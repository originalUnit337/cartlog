import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/presentation/telegram/cartridge_status_x.dart';

final class CartridgeDetailFormatter {
  const CartridgeDetailFormatter();

  String format(Cartridge cartridge) {
    return '''
Картридж ID ${cartridge.id} · #${cartridge.number}

Модель: ${cartridge.model}
Кабинет: ${cartridge.office}
Статус: ${cartridge.status.displayLabel}

Получен: ${_date(cartridge.receivedAt)}
Отправлен на заправку: ${_date(cartridge.sentToRefillAt)}
Готов: ${_date(cartridge.readyAt)}
Выдан: ${_date(cartridge.issuedAt)}
'''
        .trim();
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    final date = value.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
