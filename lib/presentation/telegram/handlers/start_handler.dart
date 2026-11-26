import 'package:cartlog/presentation/telegram/telegram_admin_access.dart';
import 'package:cartlog/presentation/telegram/telegram_menu_labels.dart';
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
• Администраторам в личном чате доступна резервная копия базы

В карточке доступны изменение данных, статуса, история и архивирование.
Команды /list, /number, /office, /add, /edit, /remove и /import также доступны.
''';

  void register(Bot<Context> bot, {required TelegramAdminAccess adminAccess}) {
    bot.command('myid', (context) async {
      final userId = context.from?.id;
      if (userId == null) {
        await context.reply('Не удалось определить Telegram ID.');
        return;
      }
      await context.reply('Ваш Telegram ID: $userId');
    });

    bot.command('start', (context) async {
      final rows = <List<String>>[
        [TelegramMenuLabels.cartridges, TelegramMenuLabels.search],
        [TelegramMenuLabels.add, TelegramMenuLabels.importCsv],
      ];
      if (adminAccess.isAdmin(context)) {
        rows.add([TelegramMenuLabels.databaseBackup]);
      }

      final menu = Keyboard.from(rows).resized().persistent();
      await context.reply(welcomeMessage.trim(), replyMarkup: menu);
    });
  }
}
