import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

final class PostgresRowMapper {
  const PostgresRowMapper._();

  static Cartridge toCartridge(Map<String, Object?> row) {
    return Cartridge(
      id: _integer(row, 'id'),
      number: _string(row, 'number'),
      model: _string(row, 'model'),
      office: _string(row, 'office'),
      status: statusFromDatabase(row['status']),
      receivedAt: _nullableDateTime(row, 'received_at'),
      sentToRefillAt: _nullableDateTime(row, 'sent_to_refill_at'),
      readyAt: _nullableDateTime(row, 'ready_at'),
      issuedAt: _nullableDateTime(row, 'issued_at'),
      archivedAt: _nullableDateTime(row, 'archived_at'),
      createdAt: _dateTime(row, 'created_at'),
      updatedAt: _dateTime(row, 'updated_at'),
    );
  }

  static CartridgeLog toCartridgeLog(Map<String, Object?> row) {
    return CartridgeLog(
      id: _integer(row, 'id'),
      cartridgeId: _integer(row, 'cartridge_id'),
      action: actionFromDatabase(row['action']),
      oldStatus: nullableStatusFromDatabase(row['old_status']),
      newStatus: nullableStatusFromDatabase(row['new_status']),
      occurredAt: _dateTime(row, 'occurred_at'),
      createdAt: _dateTime(row, 'created_at'),
      changedBy: _string(row, 'changed_by'),
      comment: _nullableString(row, 'comment'),
    );
  }

  static String statusToDatabase(CartridgeStatus status) => switch (status) {
    CartridgeStatus.ready => 'ready',
    CartridgeStatus.inUse => 'in_use',
    CartridgeStatus.empty => 'empty',
    CartridgeStatus.refilling => 'refilling',
  };

  static CartridgeStatus statusFromDatabase(Object? value) => switch (value) {
    'ready' => CartridgeStatus.ready,
    'in_use' => CartridgeStatus.inUse,
    'empty' => CartridgeStatus.empty,
    'refilling' => CartridgeStatus.refilling,
    _ => throw FormatException('Unknown cartridge status in database: $value'),
  };

  static CartridgeStatus? nullableStatusFromDatabase(Object? value) =>
      value == null ? null : statusFromDatabase(value);

  static String actionToDatabase(CartridgeLogAction action) => switch (action) {
    CartridgeLogAction.created => 'created',
    CartridgeLogAction.updated => 'updated',
    CartridgeLogAction.statusChanged => 'statusChanged',
    CartridgeLogAction.removed => 'removed',
  };

  static CartridgeLogAction actionFromDatabase(Object? value) =>
      switch (value) {
        'created' => CartridgeLogAction.created,
        'updated' => CartridgeLogAction.updated,
        'statusChanged' => CartridgeLogAction.statusChanged,
        'removed' => CartridgeLogAction.removed,
        _ => throw FormatException(
          'Unknown cartridge log action in database: $value',
        ),
      };

  static int _integer(Map<String, Object?> row, String column) {
    final value = row[column];
    return switch (value) {
      int() => value,
      BigInt() => value.toInt(),
      _ => throw FormatException('Expected integer column "$column".'),
    };
  }

  static String _string(Map<String, Object?> row, String column) {
    final value = row[column];
    if (value is String) return value;
    throw FormatException('Expected text column "$column".');
  }

  static String? _nullableString(Map<String, Object?> row, String column) {
    final value = row[column];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Expected nullable text column "$column".');
  }

  static DateTime _dateTime(Map<String, Object?> row, String column) {
    final value = row[column];
    return switch (value) {
      DateTime() => value,
      String() => DateTime.parse(value),
      _ => throw FormatException('Expected timestamp column "$column".'),
    };
  }

  static DateTime? _nullableDateTime(Map<String, Object?> row, String column) {
    final value = row[column];
    if (value == null) return null;
    return switch (value) {
      DateTime() => value,
      String() => DateTime.parse(value),
      _ => throw FormatException(
        'Expected nullable timestamp column "$column".',
      ),
    };
  }
}
