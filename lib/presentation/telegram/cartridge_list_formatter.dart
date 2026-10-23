import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/presentation/telegram/cartridge_status_x.dart';

final class CartridgeListFormatter {
  const CartridgeListFormatter();

  String format(List<Cartridge> cartridges) {
    if (cartridges.isEmpty) return 'Картриджей пока нет.';

    final lines = cartridges.map(
      (cartridge) =>
          '• #${cartridge.number} — ${cartridge.model} — кабинет '
          '${cartridge.office} — ${cartridge.status.displayLabel}',
    );

    return 'Картриджи (${cartridges.length}):\n${lines.join('\n')}';
  }
}
