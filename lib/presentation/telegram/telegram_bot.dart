import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/application/cartridge/cartridge_import_service.dart';
import 'package:cartlog/application/cartridge/cartridge_history_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_add_handler.dart';
import 'package:cartlog/presentation/telegram/cartridge_browser.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_detail_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_list_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_edit_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_import_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_remove_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_search_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/start_handler.dart';
import 'package:cartlog/presentation/telegram/telegram_menu_labels.dart';
import 'package:televerse/plugins.dart';
import 'package:televerse/televerse.dart';

final class TelegramBot {
  TelegramBot({
    required String token,
    required CartridgeQueryService cartridgeQueryService,
    required CartridgeHistoryQueryService cartridgeHistoryQueryService,
    required CartridgeService cartridgeService,
    required CartridgeImportService cartridgeImportService,
  }) : _bot = Bot<Context>(token) {
    final browser = CartridgeBrowser(queryService: cartridgeQueryService);
    final listHandler = CartridgeListHandler(browser: browser);
    final addHandler = CartridgeAddHandler(cartridgeService: cartridgeService);
    final importHandler = CartridgeImportHandler(
      importService: cartridgeImportService,
    );
    final searchHandler = CartridgeSearchHandler(
      queryService: cartridgeQueryService,
      browser: browser,
      onAddPressed: addHandler.showTemplate,
      onImportPressed: importHandler.prompt,
    );
    final editHandler = CartridgeEditHandler(
      cartridgeService: cartridgeService,
      queryService: cartridgeQueryService,
    );

    _bot.plugin(
      ConversationPlugin<Context>(
        defaultTimeout: const Duration(minutes: 2),
        getStorageKey: (context) =>
            'chat:${context.chat?.id ?? 'unknown'}:'
            'user:${context.from?.id ?? 'unknown'}',
      ),
    );
    searchHandler.registerConversations(_bot);

    listHandler.register(_bot);
    searchHandler.register(_bot);
    addHandler.register(_bot);
    editHandler.register(_bot);
    CartridgeRemoveHandler(cartridgeService: cartridgeService).register(_bot);
    importHandler.register(_bot);
    CartridgeDetailHandler(
      queryService: cartridgeQueryService,
      historyQueryService: cartridgeHistoryQueryService,
      cartridgeService: cartridgeService,
      browser: browser,
      editHandler: editHandler,
    ).register(_bot);

    final menu = KeyboardMenu<Context>()
        .text(TelegramMenuLabels.cartridges, listHandler.showList)
        .text(TelegramMenuLabels.search, searchHandler.showSearchOptions)
        .row()
        .text(TelegramMenuLabels.add, addHandler.showTemplate)
        .text(TelegramMenuLabels.importCsv, importHandler.prompt)
        .resized()
        .persistent();
    _bot.attachMenu(menu);
    const StartHandler().register(_bot, menu: menu);
  }

  final Bot<Context> _bot;

  Future<void> start() => _bot.start();

  Future<void> stop() => _bot.stop();

  Future<void> close() => _bot.close();
}
