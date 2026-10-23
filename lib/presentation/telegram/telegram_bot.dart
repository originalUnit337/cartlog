import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_list_handler.dart';
import 'package:cartlog/presentation/telegram/handlers/start_handler.dart';
import 'package:televerse/televerse.dart';

final class TelegramBot {
  TelegramBot({
    required String token,
    required CartridgeQueryService cartridgeQueryService,
  }) : _bot = Bot<Context>(token) {
    const StartHandler().register(_bot);
    CartridgeListHandler(queryService: cartridgeQueryService).register(_bot);
  }

  final Bot<Context> _bot;

  Future<void> start() => _bot.start();

  Future<void> stop() => _bot.stop();

  Future<void> close() => _bot.close();
}
