import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_add_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_list_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_edit_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_remove_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_search_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/start_handler.dart';
import 'package:televerse/televerse.dart';

final class TelegramBot {
  TelegramBot({
    required String token,
    required CartridgeQueryService cartridgeQueryService,
    required CartridgeService cartridgeService,
  }) : _bot = Bot<Context>(token) {
    const StartHandler().register(_bot);
    CartridgeListHandler(queryService: cartridgeQueryService).register(_bot);
    CartridgeSearchHandler(queryService: cartridgeQueryService).register(_bot);
    CartridgeAddHandler(cartridgeService: cartridgeService).register(_bot);
    CartridgeEditHandler(
      cartridgeService: cartridgeService,
      queryService: cartridgeQueryService,
    ).register(_bot);
    CartridgeRemoveHandler(cartridgeService: cartridgeService).register(_bot);
  }

  final Bot<Context> _bot;

  Future<void> start() => _bot.start();

  Future<void> stop() => _bot.stop();

  Future<void> close() => _bot.close();
}
