import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/infrastructure/database/mappers/postgres_row_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresRowMapper', () {
    test('maps a cartridge row including nullable lifecycle dates', () {
      final createdAt = DateTime.utc(2026, 10, 20, 9);
      final updatedAt = DateTime.utc(2026, 10, 21, 10);

      final cartridge = PostgresRowMapper.toCartridge({
        'id': 12,
        'number': '001',
        'model': 'HP 85A',
        'office': '101',
        'status': 'in_use',
        'received_at': null,
        'sent_to_refill_at': null,
        'ready_at': null,
        'issued_at': createdAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      });

      expect(cartridge.id, 12);
      expect(cartridge.number, '001');
      expect(cartridge.status, CartridgeStatus.inUse);
      expect(cartridge.receivedAt, isNull);
      expect(cartridge.issuedAt, createdAt);
      expect(cartridge.updatedAt, updatedAt);
    });

    test('maps log event time separately from database creation time', () {
      final occurredAt = DateTime.utc(2026, 10, 20, 9);
      final createdAt = DateTime.utc(2026, 10, 21, 10);

      final log = PostgresRowMapper.toCartridgeLog({
        'id': 31,
        'cartridge_id': 12,
        'action': 'statusChanged',
        'old_status': 'empty',
        'new_status': 'refilling',
        'occurred_at': occurredAt,
        'created_at': createdAt,
        'changed_by': 'telegram:123 (@operator)',
        'comment': null,
      });

      expect(log.action, CartridgeLogAction.statusChanged);
      expect(log.oldStatus, CartridgeStatus.empty);
      expect(log.newStatus, CartridgeStatus.refilling);
      expect(log.occurredAt, occurredAt);
      expect(log.createdAt, createdAt);
      expect(log.comment, isNull);
    });

    test('rejects statuses not recognized by the domain', () {
      expect(
        () => PostgresRowMapper.statusFromDatabase('refilled'),
        throwsFormatException,
      );
    });
  });
}
