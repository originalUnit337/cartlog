import 'package:cartlog/application/cartridge/cartridge_exceptions.dart';
import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/application/cartridge/cartridge_unit_of_work.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge_log.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_log_repository.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_repository.dart';
import 'package:test/test.dart';

void main() {
  late _MemoryUnitOfWork unitOfWork;
  late CartridgeService service;

  setUp(() {
    unitOfWork = _MemoryUnitOfWork();
    service = CartridgeService(unitOfWork: unitOfWork);
  });

  test('follows the lifecycle and records event times and history', () async {
    final initial = _cartridge(id: 1, status: CartridgeStatus.ready);
    unitOfWork.cartridges.records[initial.id] = initial;

    final issuedAt = DateTime.utc(2026, 10, 20, 8);
    final issued = await service.changeStatus(
      cartridgeId: initial.id,
      status: CartridgeStatus.inUse,
      occurredAt: issuedAt,
      changedBy: 'telegram:11',
    );
    expect(issued.issuedAt, issuedAt);

    final emptiedAt = DateTime.utc(2026, 10, 21, 9);
    final emptied = await service.changeStatus(
      cartridgeId: initial.id,
      status: CartridgeStatus.empty,
      occurredAt: emptiedAt,
      changedBy: 'telegram:11',
    );
    expect(emptied.status, CartridgeStatus.empty);
    expect(emptied.issuedAt, issuedAt);

    final sentAt = DateTime.utc(2026, 10, 22, 10);
    final sent = await service.changeStatus(
      cartridgeId: initial.id,
      status: CartridgeStatus.refilling,
      occurredAt: sentAt,
      changedBy: 'telegram:11',
    );
    expect(sent.sentToRefillAt, sentAt);

    final readyAt = DateTime.utc(2026, 10, 23, 11);
    final ready = await service.changeStatus(
      cartridgeId: initial.id,
      status: CartridgeStatus.ready,
      occurredAt: readyAt,
      changedBy: 'telegram:11',
    );
    expect(ready.readyAt, readyAt);

    expect(unitOfWork.logs.records, hasLength(4));
    expect(
      unitOfWork.logs.records.map((log) => (log.oldStatus, log.newStatus)),
      [
        (CartridgeStatus.ready, CartridgeStatus.inUse),
        (CartridgeStatus.inUse, CartridgeStatus.empty),
        (CartridgeStatus.empty, CartridgeStatus.refilling),
        (CartridgeStatus.refilling, CartridgeStatus.ready),
      ],
    );
    expect(unitOfWork.logs.records.map((log) => log.occurredAt), [
      issuedAt,
      emptiedAt,
      sentAt,
      readyAt,
    ]);
    expect(
      unitOfWork.logs.records.every(
        (log) => log.action == CartridgeLogAction.statusChanged,
      ),
      isTrue,
    );
  });

  test('rejects a skipped transition without updating or logging', () async {
    final initial = _cartridge(id: 2, status: CartridgeStatus.inUse);
    unitOfWork.cartridges.records[initial.id] = initial;

    await expectLater(
      service.changeStatus(
        cartridgeId: initial.id,
        status: CartridgeStatus.refilling,
        changedBy: 'telegram:12',
      ),
      throwsA(isA<InvalidCartridgeTransitionException>()),
    );

    expect(unitOfWork.cartridges.records[initial.id]?.status, initial.status);
    expect(unitOfWork.logs.records, isEmpty);
  });

  test('reports a missing cartridge', () async {
    await expectLater(
      service.changeStatus(
        cartridgeId: 99,
        status: CartridgeStatus.inUse,
        changedBy: 'telegram:12',
      ),
      throwsA(isA<CartridgeNotFoundException>()),
    );
  });

  test('creates a ready cartridge and records a created log', () async {
    final occurredAt = DateTime.utc(2026, 10, 20, 7);

    final created = await service.create(
      cartridge: const NewCartridge(
        number: ' 001 ',
        model: ' HP 85A ',
        office: ' 101 ',
      ),
      changedBy: 'telegram:16 (@operator)',
      occurredAt: occurredAt,
    );

    expect(created.number, '001');
    expect(created.model, 'HP 85A');
    expect(created.office, '101');
    expect(created.status, CartridgeStatus.ready);
    expect(unitOfWork.logs.records, hasLength(1));
    expect(unitOfWork.logs.records.single.action, CartridgeLogAction.created);
    expect(unitOfWork.logs.records.single.newStatus, CartridgeStatus.ready);
    expect(unitOfWork.logs.records.single.occurredAt, occurredAt);
  });

  test(
    'edits cartridge details without changing its status or dates',
    () async {
      final receivedAt = DateTime.utc(2026, 9, 1);
      final initial = Cartridge(
        id: 11,
        number: '001',
        model: 'Old model',
        office: '101',
        status: CartridgeStatus.inUse,
        receivedAt: receivedAt,
        createdAt: receivedAt,
        updatedAt: receivedAt,
      );
      unitOfWork.cartridges.records[initial.id] = initial;
      final occurredAt = DateTime.utc(2026, 10, 20, 7);

      final updated = await service.updateDetails(
        cartridgeId: initial.id,
        number: '002',
        model: 'New model',
        office: '202',
        changedBy: 'telegram:17',
        occurredAt: occurredAt,
      );

      expect(updated.number, '002');
      expect(updated.model, 'New model');
      expect(updated.office, '202');
      expect(updated.status, initial.status);
      expect(updated.receivedAt, receivedAt);
      expect(unitOfWork.logs.records.single.action, CartridgeLogAction.updated);
      expect(unitOfWork.logs.records.single.oldStatus, initial.status);
      expect(unitOfWork.logs.records.single.newStatus, initial.status);
    },
  );

  test(
    'archives without deleting the cartridge and records a removed log',
    () async {
      final initial = _cartridge(id: 12, status: CartridgeStatus.empty);
      unitOfWork.cartridges.records[initial.id] = initial;
      final archivedAt = DateTime.utc(2026, 10, 20, 8);

      final archived = await service.archive(
        cartridgeId: initial.id,
        changedBy: 'telegram:18',
        occurredAt: archivedAt,
      );

      expect(archived.archivedAt, archivedAt);
      expect(unitOfWork.cartridges.records.containsKey(initial.id), isTrue);
      expect(unitOfWork.logs.records.single.action, CartridgeLogAction.removed);
      expect(unitOfWork.logs.records.single.occurredAt, archivedAt);
      await expectLater(
        service.archive(cartridgeId: initial.id, changedBy: 'telegram:18'),
        throwsA(isA<CartridgeAlreadyArchivedException>()),
      );
    },
  );

  test('defaults the event time to the current UTC time', () async {
    final initial = _cartridge(id: 10, status: CartridgeStatus.ready);
    unitOfWork.cartridges.records[initial.id] = initial;
    final before = DateTime.now().toUtc();

    await service.changeStatus(
      cartridgeId: initial.id,
      status: CartridgeStatus.inUse,
      changedBy: 'telegram:12',
    );

    final occurredAt = unitOfWork.logs.records.single.occurredAt;
    final after = DateTime.now().toUtc();
    expect(occurredAt.isUtc, isTrue);
    expect(occurredAt.isBefore(before), isFalse);
    expect(occurredAt.isAfter(after), isFalse);
  });

  test('changes a batch in one unit-of-work using one occurredAt', () async {
    final first = _cartridge(id: 3, status: CartridgeStatus.empty);
    final second = _cartridge(id: 4, status: CartridgeStatus.empty);
    unitOfWork.cartridges.records.addAll({first.id: first, second.id: second});
    final occurredAt = DateTime.utc(2026, 10, 23, 12);

    final updated = await service.changeStatusForMany(
      cartridgeIds: [first.id, second.id, first.id],
      status: CartridgeStatus.refilling,
      occurredAt: occurredAt,
      changedBy: 'telegram:13',
    );

    expect(updated.map((cartridge) => cartridge.id), [first.id, second.id]);
    expect(updated.map((cartridge) => cartridge.sentToRefillAt), [
      occurredAt,
      occurredAt,
    ]);
    expect(unitOfWork.transactionCount, 1);
    expect(unitOfWork.logs.records, hasLength(2));
    expect(
      unitOfWork.logs.records.every((log) => log.occurredAt == occurredAt),
      isTrue,
    );
  });

  test('validates the full batch before applying any change', () async {
    final valid = _cartridge(id: 5, status: CartridgeStatus.inUse);
    final invalid = _cartridge(id: 6, status: CartridgeStatus.ready);
    unitOfWork.cartridges.records.addAll({
      valid.id: valid,
      invalid.id: invalid,
    });

    await expectLater(
      service.changeStatusForMany(
        cartridgeIds: [valid.id, invalid.id],
        status: CartridgeStatus.empty,
        changedBy: 'telegram:14',
      ),
      throwsA(isA<InvalidCartridgeTransitionException>()),
    );

    expect(unitOfWork.cartridges.records[valid.id]?.status, valid.status);
    expect(unitOfWork.cartridges.records[invalid.id]?.status, invalid.status);
    expect(unitOfWork.logs.records, isEmpty);
  });

  test('empty batches do not open a transaction', () async {
    final updated = await service.changeStatusForMany(
      cartridgeIds: const [],
      status: CartridgeStatus.ready,
      changedBy: 'telegram:15',
    );

    expect(updated, isEmpty);
    expect(unitOfWork.transactionCount, 0);
  });
}

Cartridge _cartridge({required int id, required CartridgeStatus status}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  return Cartridge(
    id: id,
    number: '00$id',
    model: 'Test model',
    office: '101',
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

final class _MemoryUnitOfWork implements CartridgeUnitOfWork {
  final _MemoryCartridgeRepository cartridges = _MemoryCartridgeRepository();
  final _MemoryCartridgeLogRepository logs = _MemoryCartridgeLogRepository();
  int transactionCount = 0;

  @override
  Future<T> run<T>(
    Future<T> Function(
      CartridgeRepository cartridges,
      CartridgeLogRepository logs,
    )
    operation,
  ) {
    transactionCount++;
    return operation(cartridges, logs);
  }
}

final class _MemoryCartridgeRepository implements CartridgeRepository {
  final Map<int, Cartridge> records = {};

  @override
  Future<Cartridge?> findById(int id) async => records[id];

  @override
  Future<Cartridge?> findByIdForUpdate(int id) async => records[id];

  @override
  Future<List<Cartridge>> findAll() async => records.values.toList();

  @override
  Future<List<Cartridge>> findPage({
    required int offset,
    required int limit,
  }) async {
    final active =
        records.values
            .where((cartridge) => cartridge.archivedAt == null)
            .toList()
          ..sort((left, right) => left.id.compareTo(right.id));
    return active.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Cartridge>> findByNumber(String number) async =>
      records.values.where((cartridge) => cartridge.number == number).toList();

  @override
  Future<List<Cartridge>> findByNumberPage(
    String number, {
    required int offset,
    required int limit,
  }) async => (await findByNumber(number)).skip(offset).take(limit).toList();

  @override
  Future<List<Cartridge>> findByOffice(String office) async =>
      records.values.where((cartridge) => cartridge.office == office).toList();

  @override
  Future<List<Cartridge>> findByOfficePage(
    String office, {
    required int offset,
    required int limit,
  }) async => (await findByOffice(office)).skip(offset).take(limit).toList();

  @override
  Future<List<Cartridge>> findByStatus(CartridgeStatus status) async =>
      records.values.where((cartridge) => cartridge.status == status).toList();

  @override
  Future<Cartridge> create(NewCartridge cartridge) async {
    final id = records.keys.isEmpty
        ? 1
        : records.keys.reduce((left, right) => left > right ? left : right) + 1;
    final now = DateTime.now().toUtc();
    final saved = Cartridge(
      id: id,
      number: cartridge.number,
      model: cartridge.model,
      office: cartridge.office,
      status: cartridge.status,
      receivedAt: cartridge.receivedAt,
      sentToRefillAt: cartridge.sentToRefillAt,
      readyAt: cartridge.readyAt,
      issuedAt: cartridge.issuedAt,
      createdAt: now,
      updatedAt: now,
    );
    records[id] = saved;
    return saved;
  }

  @override
  Future<Cartridge> update(Cartridge cartridge) async {
    if (!records.containsKey(cartridge.id)) {
      throw StateError('Cartridge ${cartridge.id} does not exist.');
    }
    records[cartridge.id] = cartridge;
    return cartridge;
  }
}

final class _MemoryCartridgeLogRepository implements CartridgeLogRepository {
  final List<CartridgeLog> records = [];

  @override
  Future<CartridgeLog> create(NewCartridgeLog log) async {
    final saved = CartridgeLog(
      id: records.length + 1,
      cartridgeId: log.cartridgeId,
      action: log.action,
      oldStatus: log.oldStatus,
      newStatus: log.newStatus,
      occurredAt: log.occurredAt,
      createdAt: DateTime.utc(2027),
      changedBy: log.changedBy,
      comment: log.comment,
    );
    records.add(saved);
    return saved;
  }

  @override
  Future<List<CartridgeLog>> findByCartridgeId(int cartridgeId) async =>
      records.where((log) => log.cartridgeId == cartridgeId).toList();

  @override
  Future<List<CartridgeLog>> findLatestByCartridgeId(
    int cartridgeId, {
    required int limit,
  }) async => (await findByCartridgeId(cartridgeId)).take(limit).toList();
}
