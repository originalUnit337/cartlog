import 'package:televerse/televerse.dart';

final class StartHandler {
  const StartHandler();

  static const welcomeMessage = '''
Привет! Я помогу вести учёт картриджей.

Выберите действие кнопками меню ниже:
• «Картриджи» — открыть список и карточки
• «Поиск» — найти по номеру или кабинету
• «Добавить» — создать картридж
• «Импорт CSV» — проверить и импортировать файл

В карточке доступны изменение данных, статуса, история и архивирование.
Команды /list, /number, /office, /add, /edit, /remove и /import также доступны.
''';

  void register(Bot<Context> bot, {required KeyboardMenu<Context> menu}) {
    bot.command('start', (context) async {
      await context.reply(welcomeMessage.trim(), replyMarkup: menu);
    });
  }
}
