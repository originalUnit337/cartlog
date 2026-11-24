import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/application/cartridge/cartridge_import_service.dart';
import 'package:cartlog/application/cartridge/cartridge_history_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/application/admin/database_backup_provider.dart';
import 'package:cartlog/application/telegram/telegram_user_service.dart';
import 'package:cartlog/infrastructure/config/telegram_bot_config.dart';
import 'package:cartlog/infrastructure/database/database_config.dart';
import 'package:cartlog/presentation/telegram/handlers/database_backup_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_add_handler.dart';
import 'package:cartlog/presentation/telegram/cartridge_browser.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_detail_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_list_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_edit_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_import_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_remove_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_search_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/start_handler.dart';
import 'package:cartlog/presentation/telegram/telegram_admin_access.dart';
import 'package:cartlog/presentation/telegram/telegram_user_tracking_middleware.dart';
import 'package:televerse/plugins.dart';
import 'package:televerse/televerse.dart';

final class TelegramBot {
  TelegramBot({
    required String token,
    required CartridgeQueryService cartridgeQueryService,
    required CartridgeHistoryQueryService cartridgeHistoryQueryService,
    required CartridgeService cartridgeService,
    required CartridgeImportService cartridgeImportService,
    required TelegramBotConfig telegramBotConfig,
    required DatabaseConfig databaseConfig,
    required DatabaseBackupProvider databaseBackupProvider,
    required TelegramUserService telegramUserService,
  }) : _bot = Bot<Context>(token),
       _adminAccess = TelegramAdminAccess(
         adminIds: telegramBotConfig.adminIds,
       ) {
    final browser = CartridgeBrowser(queryService: cartridgeQueryService);
    final listHandler = CartridgeListHandler(browser: browser);
    final addHandler = CartridgeAddHandler(cartridgeService: cartridgeService);
    final importHandler = CartridgeImportHandler(
      importService: cartridgeImportService,
    );
    final backupHandler = DatabaseBackupHandler(
      backupProvider: databaseBackupProvider,
      adminAccess: _adminAccess,
      databaseConfig: databaseConfig,
    );
    final searchHandler = CartridgeSearchHandler(
      queryService: cartridgeQueryService,
      browser: browser,
      onAddPressed: addHandler.showTemplate,
      onImportPressed: importHandler.prompt,
      onBackupPressed: backupHandler.createBackup,
    );
    final editHandler = CartridgeEditHandler(
      cartridgeService: cartridgeService,
      queryService: cartridgeQueryService,
    );

    _bot.use(
      TelegramUserTrackingMiddleware(userService: telegramUserService).call,
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
    backupHandler.register(_bot);
    CartridgeDetailHandler(
      queryService: cartridgeQueryService,
      historyQueryService: cartridgeHistoryQueryService,
      cartridgeService: cartridgeService,
      browser: browser,
      editHandler: editHandler,
    ).register(_bot);

    const StartHandler().register(_bot, adminAccess: _adminAccess);
  }

  final Bot<Context> _bot;
  final TelegramAdminAccess _adminAccess;

  Future<void> start() => _bot.start();

  Future<void> stop() => _bot.stop();

  Future<void> close() => _bot.close();
}
