import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/presentation/telegram/cartridge_status_x.dart';

final class CartridgeListFormatter {
  const CartridgeListFormatter();

  String format(List<Cartridge> cartridges) {
    if (cartridges.isEmpty) return 'Картриджей пока нет.';

    return 'Картриджи (${cartridges.length}):\n${_formatCartridges(cartridges)}';
  }

  String formatSearchResults({
    required List<Cartridge> cartridges,
    required String query,
  }) {
    if (cartridges.isEmpty) return 'По запросу «$query» ничего не найдено.';

    return 'По запросу «$query» найдено: ${cartridges.length}\n'
        '${_formatCartridges(cartridges)}';
  }

  String _formatCartridges(List<Cartridge> cartridges) {
    return cartridges
        .map(
          (cartridge) =>
              '• #${cartridge.number} — ${cartridge.model} — кабинет '
              '${cartridge.office} — ${cartridge.status.displayLabel}',
        )
        .join('\n');
  }
}
