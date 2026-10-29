import 'package:cartlog/application/cartridge/cartridge_page.dart';
import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';

final class CartridgeBrowser {
  CartridgeBrowser({required this.queryService});

  static const pageSize = 10;
  static const _routeLifetime = Duration(minutes: 30);
  static const _maximumRoutes = 100;

  final CartridgeQueryService queryService;
  final Map<String, _BrowseRoute> _routes = {};
  int _routeCounter = 0;

  void register(Bot<Context> bot) {
    bot.callbackQuery(RegExp(r'^browse:'), _handlePageCallback);
  }

  Future<void> showActiveCartridges(Context context, {int page = 0}) {
    return _showPage(
      context,
      title: 'Активные картриджи',
      page: page,
      loadPage: (page) => queryService.listPage(page: page, pageSize: pageSize),
    );
  }

  Future<void> showSearchResults(
    Context context, {
    required String query,
    required String title,
    required Future<CartridgePage> Function(int page) loadPage,
  }) {
    return _showPage(
      context,
      title: '$title «$query»',
      page: 0,
      loadPage: loadPage,
    );
  }

  Future<void> showPageInCurrentMessage(
    Context context, {
    required String routeId,
    required int page,
  }) async {
    final route = _routes[routeId];
    if (route == null || _isExpired(route)) {
      _routes.remove(routeId);
      await context.editMessageText(
        'Этот список устарел. Откройте его заново из меню.',
      );
      return;
    }
    await _render(context, routeId, route, page, editCurrentMessage: true);
  }

  Future<void> showRouteInCurrentMessage(
    Context context, {
    required String routeId,
    required int page,
  }) {
    return showPageInCurrentMessage(context, routeId: routeId, page: page);
  }

  Future<void> _showPage(
    Context context, {
    required String title,
    required int page,
    required Future<CartridgePage> Function(int page) loadPage,
  }) async {
    _pruneRoutes();
    final routeId = _newRouteId();
    final route = _BrowseRoute(title: title, loadPage: loadPage);
    _routes[routeId] = route;
    await _render(context, routeId, route, page);
  }

  Future<void> _render(
    Context context,
    String routeId,
    _BrowseRoute route,
    int pageNumber, {
    bool editCurrentMessage = false,
  }) async {
    final page = await route.loadPage(pageNumber);
    final rows = <List<InlineKeyboardButton>>[
      for (final cartridge in page.items)
        [
          InlineKeyboardButton(
            text: _buttonLabel(cartridge),
            callbackData: 'cartridge:${cartridge.id}:$routeId:${page.page}',
          ),
        ],
      if (page.hasPrevious || page.hasNext)
        [
          if (page.hasPrevious)
            InlineKeyboardButton(
              text: '⬅️ Назад',
              callbackData: 'browse:$routeId:${page.page - 1}',
            ),
          if (page.hasNext)
            InlineKeyboardButton(
              text: 'Далее ➡️',
              callbackData: 'browse:$routeId:${page.page + 1}',
            ),
        ],
    ];

    final text = page.items.isEmpty
        ? '${route.title}\nКартриджи не найдены.'
        : '${route.title} · страница ${page.page + 1}\n'
              'Нажмите на картридж, чтобы открыть карточку.';
    final markup = rows.isEmpty ? null : InlineKeyboard(inlineKeyboard: rows);

    if (editCurrentMessage) {
      await context.editMessageText(text, replyMarkup: markup);
    } else {
      await context.reply(text, replyMarkup: markup);
    }
  }

  Future<void> _handlePageCallback(Context context) async {
    await context.answerCallbackQuery();
    final parts = context.callbackQuery?.data?.split(':');
    if (parts == null || parts.length != 3) return;

    final page = int.tryParse(parts[2]);
    if (page == null || page < 0) return;
    await showPageInCurrentMessage(context, routeId: parts[1], page: page);
  }

  String _newRouteId() {
    _routeCounter++;
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${_routeCounter.toRadixString(36)}';
  }

  void _pruneRoutes() {
    _routes.removeWhere((_, route) => _isExpired(route));
    while (_routes.length >= _maximumRoutes) {
      _routes.remove(_routes.keys.first);
    }
  }

  bool _isExpired(_BrowseRoute route) =>
      DateTime.now().difference(route.createdAt) > _routeLifetime;

  String _buttonLabel(Cartridge cartridge) {
    final label =
        'ID ${cartridge.id} · #${cartridge.number} · ${cartridge.office}';
    return label.length <= 52 ? label : '${label.substring(0, 49)}…';
  }
}

final class _BrowseRoute {
  _BrowseRoute({required this.title, required this.loadPage});

  final String title;
  final Future<CartridgePage> Function(int page) loadPage;
  final DateTime createdAt = DateTime.now();
}
