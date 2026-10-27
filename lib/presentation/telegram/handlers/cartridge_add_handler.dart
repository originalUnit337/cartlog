import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';
import 'package:cartlog/presentation/telegram/cartridge_form_template.dart';
import 'package:cartlog/presentation/telegram/telegram_changed_by.dart';
import 'package:cartlog/presentation/telegram/cartridge_status_x.dart';
import 'package:televerse/televerse.dart';

final class CartridgeAddHandler {
  const CartridgeAddHandler({required this.cartridgeService});

  final CartridgeService cartridgeService;

  void register(Bot<Context> bot) {
    bot.command('add', (context) async {
      final input = context.argsString?.trim();
      if (input == null || input.isEmpty) {
        await context.reply(
          'Скопируйте форму, заполните её и отправьте:\n\n'
          '${CartridgeFormTemplate.add}\n\n'
          'Новый картридж получит статус «Готов».',
        );
        return;
      }

      try {
        final form = CartridgeFormTemplate.parse(input);
        final cartridge = await cartridgeService.create(
          cartridge: NewCartridge(
            number: form.number,
            model: form.model,
            office: form.office,
          ),
          changedBy: telegramChangedBy(context),
        );
        await context.reply(
          'Добавлен картридж #${cartridge.number}.\n'
          'Модель: ${cartridge.model}\n'
          'Кабинет: ${cartridge.office}\n'
          'Статус: ${cartridge.status.displayLabel}',
        );
      } on FormatException catch (error) {
        await context.reply(
          '${error.message}\n\nЗаполните форму и отправьте её:\n'
          '${CartridgeFormTemplate.add}',
        );
      }
    });
  }
}
