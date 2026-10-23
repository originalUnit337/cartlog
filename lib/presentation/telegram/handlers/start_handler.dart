import 'package:televerse/televerse.dart';

final class StartHandler {
  const StartHandler();

  static const welcomeMessage = '''
Привет! Я помогу вести учёт картриджей.

Доступные команды:
/list — показать список картриджей
''';

  void register(Bot<Context> bot) {
    bot.command('start', (context) async {
      await context.reply(welcomeMessage.trim());
    });
  }
}
