import 'package:cartlog/application/cartridge/cartridge_exceptions.dart';
import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/presentation/telegram/cartridge_form_template.dart';
import 'package:cartlog/presentation/telegram/telegram_changed_by.dart';
import 'package:televerse/televerse.dart';

final class CartridgeEditHandler {
  const CartridgeEditHandler({
    required this.cartridgeService,
    required this.queryService,
  });

  final CartridgeService cartridgeService;
  final CartridgeQueryService queryService;

  void register(Bot<Context> bot) {
    bot.command('edit', (context) async {
      final input = context.argsString?.trim();
      if (input == null || input.isEmpty) {
        await context.reply('Использование: /edit <id>');
        return;
      }

      final lines = input.replaceAll('\r', '').split('\n');
      final cartridgeId = int.tryParse(lines.first.trim());
      if (cartridgeId == null) {
        await context.reply('Первым аргументом укажите числовой ID картриджа.');
        return;
      }

      final fields = lines.skip(1).join('\n').trim();
      if (fields.isEmpty) {
        await _sendTemplate(context, cartridgeId);
        return;
      }

      try {
        final form = CartridgeFormTemplate.parse(fields);
        final cartridge = await cartridgeService.updateDetails(
          cartridgeId: cartridgeId,
          number: form.number,
          model: form.model,
          office: form.office,
          changedBy: telegramChangedBy(context),
        );
        await context.reply(
          'Обновлён картридж #${cartridge.number} '
          '(ID ${cartridge.id}).',
        );
      } on FormatException catch (error) {
        await context.reply('${error.message}\n\n${CartridgeFormTemplate.add}');
      } on CartridgeNotFoundException {
        await context.reply('Картридж с ID $cartridgeId не найден.');
      } on CartridgeAlreadyArchivedException {
        await context.reply(
          'Этот картридж архивирован и не может быть изменён.',
        );
      }
    });
  }

  Future<void> _sendTemplate(Context context, int cartridgeId) async {
    final cartridge = await queryService.findById(cartridgeId);
    if (cartridge == null) {
      await context.reply('Картридж с ID $cartridgeId не найден.');
      return;
    }
    if (cartridge.archivedAt != null) {
      await context.reply('Этот картридж архивирован и не может быть изменён.');
      return;
    }

    await context.reply(
      'Скопируйте форму, исправьте нужные значения и отправьте:\n\n'
      '${CartridgeFormTemplate.edit(cartridge)}\n\n'
      'Статус меняется отдельно через допустимые переходы.',
    );
  }
}
