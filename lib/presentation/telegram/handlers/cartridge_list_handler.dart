import 'package:cartlog/presentation/telegram/telegram_menu_labels.dart';
import 'package:cartlog/presentation/telegram/cartridge_browser.dart';
import 'package:televerse/televerse.dart';

final class CartridgeListHandler {
  const CartridgeListHandler({required this.browser});

  final CartridgeBrowser browser;

  void register(Bot<Context> bot) {
    browser.register(bot);
    bot.command('list', showList);
    bot.text(TelegramMenuLabels.cartridges, showList);
  }

  Future<void> showList(Context context) =>
      browser.showActiveCartridges(context);
}
