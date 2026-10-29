import 'package:cartlog/domain/cartridge/entities/cartridge_log.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/presentation/telegram/cartridge_status_x.dart';

final class CartridgeHistoryFormatter {
  const CartridgeHistoryFormatter();

  String format(int cartridgeId, List<CartridgeLog> logs) {
    if (logs.isEmpty) return 'История картриджа ID $cartridgeId пуста.';

    final entries = logs.map((log) {
      final action = switch (log.action) {
        CartridgeLogAction.created => 'Создан',
        CartridgeLogAction.updated => 'Изменены данные',
        CartridgeLogAction.statusChanged =>
          '${log.oldStatus!.displayName} → ${log.newStatus!.displayName}',
        CartridgeLogAction.removed => 'Убран из активного списка',
      };
      final eventDate = _date(log.occurredAt);
      return '• $eventDate — $action\n  Выполнил: ${log.changedBy}';
    });

    return 'История картриджа ID $cartridgeId:\n${entries.join('\n')}';
  }

  String _date(DateTime value) {
    final date = value.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
