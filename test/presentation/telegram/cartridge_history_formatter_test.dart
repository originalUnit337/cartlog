import 'package:cartlog/domain/cartridge/entities/cartridge_log.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/presentation/telegram/cartridge_history_formatter.dart';
import 'package:test/test.dart';

void main() {
  const formatter = CartridgeHistoryFormatter();

  test('shows Telegram username but hides Telegram numeric ID', () {
    final log = _statusLog(changedBy: 'telegram:552391432 (@operator)');

    final result = formatter.format(42, [log]);

    expect(result, contains('Выполнил: @operator'));
    expect(result, isNot(contains('552391432')));
  });

  test('uses a generic Telegram label when username is unavailable', () {
    final log = _statusLog(changedBy: 'telegram:552391432');

    final result = formatter.format(42, [log]);

    expect(result, contains('Выполнил: пользователь Telegram'));
    expect(result, isNot(contains('552391432')));
  });

  test('keeps non-Telegram actor labels', () {
    final log = _statusLog(changedBy: 'import-job');

    expect(formatter.format(42, [log]), contains('Выполнил: import-job'));
  });
}

CartridgeLog _statusLog({required String changedBy}) {
  final occurredAt = DateTime.utc(2026, 10, 20);
  return CartridgeLog(
    id: 1,
    cartridgeId: 42,
    action: CartridgeLogAction.statusChanged,
    oldStatus: CartridgeStatus.ready,
    newStatus: CartridgeStatus.inUse,
    occurredAt: occurredAt,
    createdAt: occurredAt,
    changedBy: changedBy,
    comment: null,
  );
}
