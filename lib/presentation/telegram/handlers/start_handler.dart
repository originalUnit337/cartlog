import 'package:televerse/televerse.dart';

final class StartHandler {
  const StartHandler();

  static const welcomeMessage = '''
Привет! Я помогу вести учёт картриджей.

Доступные команды:
/list — показать список картриджей
/number <номер> — найти картридж по номеру
/office <кабинет> — найти картриджи по кабинету
/add — добавить картридж
/edit <id> — изменить номер, модель или кабинет
/remove <id> — убрать картридж из активного списка
''';

  void register(Bot<Context> bot) {
    bot.command('start', (context) async {
      await context.reply(welcomeMessage.trim());
    });
  }
}
