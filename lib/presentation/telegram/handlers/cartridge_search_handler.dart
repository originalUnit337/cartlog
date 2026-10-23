import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/presentation/telegram/cartridge_list_formatter.dart';
import 'package:televerse/televerse.dart';

final class CartridgeSearchHandler {
  const CartridgeSearchHandler({
    required this.queryService,
    this.formatter = const CartridgeListFormatter(),
  });

  final CartridgeQueryService queryService;
  final CartridgeListFormatter formatter;

  void register(Bot<Context> bot) {
    bot.command('number', (context) {
      return _search(
        context,
        fieldName: 'номер',
        usage: '/number <номер>',
        search: queryService.findByNumber,
      );
    });
    bot.command('office', (context) {
      return _search(
        context,
        fieldName: 'кабинет',
        usage: '/office <кабинет>',
        search: queryService.findByOffice,
      );
    });
  }

  Future<void> _search(
    Context context, {
    required String fieldName,
    required String usage,
    required Future<List<Cartridge>> Function(String value) search,
  }) async {
    final value = context.argsString?.trim();
    if (value == null || value.isEmpty) {
      await context.reply('Использование: $usage');
      return;
    }

    final cartridges = await search(value);
    await context.reply(
      formatter.formatSearchResults(
        cartridges: cartridges,
        query: '$fieldName $value',
      ),
    );
  }
}
