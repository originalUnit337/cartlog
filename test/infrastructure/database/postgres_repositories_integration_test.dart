import 'dart:io';

import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge_log.dart';
import 'package:cartlog/infrastructure/database/database_config.dart';
import 'package:cartlog/infrastructure/database/postgres_database.dart';
import 'package:cartlog/infrastructure/database/postgres_cartridge_unit_of_work.dart';
import 'package:cartlog/infrastructure/database/repositories/postgres_cartridge_log_repository.dart';
import 'package:cartlog/infrastructure/database/repositories/postgres_cartridge_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  if (Platform.environment['RUN_DATABASE_TESTS'] != 'true') {
    test(
      'PostgreSQL repositories (set RUN_DATABASE_TESTS=true to run)',
      () {},
      skip: 'Integration test requires a configured PostgreSQL database.',
    );
    return;
  }

  late PostgresDatabase database;
  late PostgresCartridgeRepository cartridges;
  late PostgresCartridgeLogRepository logs;
  late PostgresCartridgeUnitOfWork unitOfWork;
  late CartridgeService service;

  setUpAll(() async {
    database = await PostgresDatabase.connect(DatabaseConfig.load());
    cartridges = PostgresCartridgeRepository(session: database.session);
    logs = PostgresCartridgeLogRepository(session: database.session);
    unitOfWork = PostgresCartridgeUnitOfWork(
      sessionExecutor: database.sessionExecutor,
    );
    service = CartridgeService(unitOfWork: unitOfWork);
  });

  tearDownAll(() async {
    await database.close();
  });

  test('creates, searches, updates, and logs cartridges', () async {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final cartridgeIds = <int>[];

    try {
      final first = await cartridges.create(
        NewCartridge(
          number: 'repo-test-$suffix',
          model: 'Test model',
          office: 'T-$suffix',
        ),
      );
      cartridgeIds.add(first.id);

      final duplicateNumber = await cartridges.create(
        NewCartridge(
          number: first.number,
          model: 'Second model',
          office: 'T-$suffix',
          status: CartridgeStatus.inUse,
        ),
      );
      cartridgeIds.add(duplicateNumber.id);

      final foundById = await cartridges.findById(first.id);
      expect(foundById?.id, first.id);
      expect(foundById?.number, first.number);
      expect(
        (await cartridges.findAll()).map((cartridge) => cartridge.id),
        contains(first.id),
      );
      expect(await cartridges.findByNumber(first.number), hasLength(2));
      expect(await cartridges.findByOffice('T-$suffix'), hasLength(2));
      expect(
        (await cartridges.findByStatus(CartridgeStatus.inUse)).map((c) => c.id),
        contains(duplicateNumber.id),
      );

      final updated = await cartridges.update(
        Cartridge(
          id: first.id,
          number: first.number,
          model: first.model,
          office: first.office,
          status: CartridgeStatus.empty,
          receivedAt: first.receivedAt,
          sentToRefillAt: DateTime.now().toUtc(),
          readyAt: first.readyAt,
          issuedAt: first.issuedAt,
          createdAt: first.createdAt,
          updatedAt: first.updatedAt,
        ),
      );
      expect(updated.status, CartridgeStatus.empty);
      expect(
        updated.updatedAt.compareTo(first.updatedAt),
        greaterThanOrEqualTo(0),
      );

      final occurredAt = DateTime.utc(2026, 10, 20, 8);
      final log = await logs.create(
        NewCartridgeLog(
          cartridgeId: first.id,
          action: CartridgeLogAction.statusChanged,
          oldStatus: CartridgeStatus.ready,
          newStatus: CartridgeStatus.empty,
          occurredAt: occurredAt,
          changedBy: 'integration-test',
        ),
      );
      final history = await logs.findByCartridgeId(first.id);
      expect(history, hasLength(1));
      expect(history.single.id, log.id);
      expect(history.single.occurredAt, occurredAt);
      expect(history.single.createdAt, isNot(occurredAt));
    } finally {
      for (final id in cartridgeIds) {
        await database.session.execute(
          Sql.named('DELETE FROM cartridge_logs WHERE cartridge_id = @id'),
          parameters: {'id': id},
        );
      }
      for (final id in cartridgeIds) {
        await database.session.execute(
          Sql.named('DELETE FROM cartridges WHERE id = @id'),
          parameters: {'id': id},
        );
      }
    }
  });

  test('service changes status and records the supplied event time', () async {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final created = await cartridges.create(
      NewCartridge(
        number: 'service-test-$suffix',
        model: 'Test model',
        office: 'S-$suffix',
      ),
    );

    try {
      final occurredAt = DateTime.utc(2026, 10, 22, 8);
      final updated = await service.changeStatus(
        cartridgeId: created.id,
        status: CartridgeStatus.inUse,
        occurredAt: occurredAt,
        changedBy: 'integration-test',
      );

      expect(updated.status, CartridgeStatus.inUse);
      expect(updated.issuedAt, occurredAt);
      final history = await logs.findByCartridgeId(created.id);
      expect(history, hasLength(1));
      expect(history.single.oldStatus, CartridgeStatus.ready);
      expect(history.single.newStatus, CartridgeStatus.inUse);
      expect(history.single.occurredAt, occurredAt);
    } finally {
      await database.session.execute(
        Sql.named('DELETE FROM cartridge_logs WHERE cartridge_id = @id'),
        parameters: {'id': created.id},
      );
      await database.session.execute(
        Sql.named('DELETE FROM cartridges WHERE id = @id'),
        parameters: {'id': created.id},
      );
    }
  });

  test('unit of work rolls back repository writes after an error', () async {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final created = await cartridges.create(
      NewCartridge(
        number: 'rollback-test-$suffix',
        model: 'Test model',
        office: 'R-$suffix',
      ),
    );

    try {
      await expectLater(
        unitOfWork.run((cartridgeRepository, _) async {
          final current = await cartridgeRepository.findByIdForUpdate(
            created.id,
          );
          await cartridgeRepository.update(
            Cartridge(
              id: created.id,
              number: created.number,
              model: created.model,
              office: 'should-rollback',
              status: current!.status,
              receivedAt: current.receivedAt,
              sentToRefillAt: current.sentToRefillAt,
              readyAt: current.readyAt,
              issuedAt: current.issuedAt,
              createdAt: current.createdAt,
              updatedAt: current.updatedAt,
            ),
          );
          throw StateError('Force rollback for the integration test.');
        }),
        throwsA(isA<StateError>()),
      );

      expect((await cartridges.findById(created.id))?.office, created.office);
    } finally {
      await database.session.execute(
        Sql.named('DELETE FROM cartridge_logs WHERE cartridge_id = @id'),
        parameters: {'id': created.id},
      );
      await database.session.execute(
        Sql.named('DELETE FROM cartridges WHERE id = @id'),
        parameters: {'id': created.id},
      );
    }
  });
}
