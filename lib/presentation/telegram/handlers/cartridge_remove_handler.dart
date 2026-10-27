import 'package:cartlog/application/cartridge/cartridge_exceptions.dart';
import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/presentation/telegram/telegram_changed_by.dart';
import 'package:televerse/televerse.dart';

final class CartridgeRemoveHandler {
  const CartridgeRemoveHandler({required this.cartridgeService});

  final CartridgeService cartridgeService;

  void register(Bot<Context> bot) {
    bot.command('remove', (context) async {
      final input = context.argsString?.trim();
      final cartridgeId = input == null ? null : int.tryParse(input);
      if (cartridgeId == null) {
        await context.reply('Использование: /remove <id>');
        return;
      }

      try {
        final cartridge = await cartridgeService.archive(
          cartridgeId: cartridgeId,
          changedBy: telegramChangedBy(context),
        );
        await context.reply(
          'Картридж #${cartridge.number} убран из активного списка. '
          'История сохранена.',
        );
      } on CartridgeNotFoundException {
        await context.reply('Картридж с ID $cartridgeId не найден.');
      } on CartridgeAlreadyArchivedException {
        await context.reply('Картридж с ID $cartridgeId уже архивирован.');
      }
    });
  }
}
