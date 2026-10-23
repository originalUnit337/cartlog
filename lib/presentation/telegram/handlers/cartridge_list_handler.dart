import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/presentation/telegram/cartridge_list_formatter.dart';
import 'package:televerse/televerse.dart';

final class CartridgeListHandler {
  const CartridgeListHandler({
    required this.queryService,
    this.formatter = const CartridgeListFormatter(),
  });

  final CartridgeQueryService queryService;
  final CartridgeListFormatter formatter;

  void register(Bot<Context> bot) {
    bot.command('list', (context) async {
      final cartridges = await queryService.listAll();
      await context.reply(formatter.format(cartridges));
    });
  }
}
