import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_page.dart';
import 'package:cartlog/presentation/telegram/cartridge_browser.dart';
import 'package:cartlog/presentation/telegram/telegram_menu_labels.dart';
import 'package:televerse/plugins.dart';
import 'package:televerse/televerse.dart';

final class CartridgeSearchHandler {
  const CartridgeSearchHandler({
    required this.queryService,
    required this.browser,
    required this.onAddPressed,
    required this.onImportPressed,
  });

  static const _searchTimeout = Duration(minutes: 2);

  final CartridgeQueryService queryService;
  final CartridgeBrowser browser;
  final Future<void> Function(Context context) onAddPressed;
  final Future<void> Function(Context context) onImportPressed;

  void registerConversations(Bot<Context> bot) {
    bot
      ..use(
        createConversation<Context>(
          'search-number',
          (conversation, context) => _searchConversation(
            conversation,
            context,
            fieldName: 'номер картриджа',
            title: 'По номеру',
            search: queryService.findByNumberPage,
          ),
        ),
      )
      ..use(
        createConversation<Context>(
          'search-office',
          (conversation, context) => _searchConversation(
            conversation,
            context,
            fieldName: 'кабинет',
            title: 'По кабинету',
            search: queryService.findByOfficePage,
          ),
        ),
      );
  }

  void register(Bot<Context> bot) {
    bot.command('number', (context) async {
      await _searchFromCommand(
        context,
        title: 'По номеру',
        conversationName: 'search-number',
        search: queryService.findByNumberPage,
      );
    });

    bot.command('office', (context) async {
      await _searchFromCommand(
        context,
        title: 'По кабинету',
        conversationName: 'search-office',
        search: queryService.findByOfficePage,
      );
    });

    bot.callbackQuery('search:number', (context) async {
      await context.answerCallbackQuery();
      await context.conversation.enter('search-number');
    });

    bot.callbackQuery('search:office', (context) async {
      await context.answerCallbackQuery();
      await context.conversation.enter('search-office');
    });
  }

  Future<void> showSearchOptions(Context context) async {
    await context.reply(
      'По какому полю искать?',
      replyMarkup: InlineKeyboard.from([
        [
          ('🔢 По номеру', 'search:number'),
          ('🏢 По кабинету', 'search:office'),
        ],
      ]),
    );
  }

  Future<void> _searchFromCommand(
    Context context, {
    required String title,
    required String conversationName,
    required Future<CartridgePage> Function(
      String value, {
      int page,
      int pageSize,
    })
    search,
  }) async {
    final value = context.argsString?.trim();
    if (value == null || value.isEmpty) {
      await context.conversation.enter(conversationName);
      return;
    }
    await _showResults(context, value, title, search);
  }

  Future<void> _searchConversation(
    Conversation<Context> conversation,
    Context context, {
    required String fieldName,
    required String title,
    required Future<CartridgePage> Function(
      String value, {
      int page,
      int pageSize,
    })
    search,
  }) async {
    try {
      await context.reply(
        'Введите $fieldName. Для отмены отправьте /cancel.',
        replyMarkup: const Keyboard(forceReply: true),
      );

      while (true) {
        final response = await conversation.waitFor(
          (ctx) =>
              ctx.text?.trim().isNotEmpty == true && ctx.callbackQuery == null,
          timeout: _searchTimeout,
        );
        final value = response.text!.trim();
        if (value == '/cancel') {
          await response.reply('Поиск отменён.');
          return;
        }
        if (value == TelegramMenuLabels.cartridges) {
          await conversation.halt();
          await browser.showActiveCartridges(response);
          return;
        }
        if (value == TelegramMenuLabels.search) {
          await conversation.halt();
          await showSearchOptions(response);
          return;
        }
        if (value == TelegramMenuLabels.add) {
          await conversation.halt();
          await onAddPressed(response);
          return;
        }
        if (value == TelegramMenuLabels.importCsv) {
          await conversation.halt();
          await onImportPressed(response);
          return;
        }
        if (value.startsWith('/')) {
          await response.reply(
            'Введите значение поиска или отправьте /cancel.',
          );
          continue;
        }
        await _showResults(response, value, title, search);
        return;
      }
    } on ConversationTimeoutException {
      await context.reply(
        'Время ожидания истекло. Начните поиск снова из меню.',
      );
    }
  }

  Future<void> _showResults(
    Context context,
    String value,
    String title,
    Future<CartridgePage> Function(String value, {int page, int pageSize})
    search,
  ) {
    return browser.showSearchResults(
      context,
      query: value,
      title: title,
      loadPage: (page) => search(value, page: page),
    );
  }
}
