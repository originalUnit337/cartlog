import 'package:cartlog/application/cartridge/cartridge_exceptions.dart';
import 'package:cartlog/application/cartridge/cartridge_history_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/presentation/telegram/cartridge_browser.dart';
import 'package:cartlog/presentation/telegram/cartridge_detail_formatter.dart';
import 'package:cartlog/presentation/telegram/cartridge_history_formatter.dart';
import 'package:cartlog/presentation/telegram/handlers/cartridge_edit_handler.dart';
import 'package:cartlog/presentation/telegram/telegram_changed_by.dart';
import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';

final class CartridgeDetailHandler {
  const CartridgeDetailHandler({
    required this.queryService,
    required this.historyQueryService,
    required this.cartridgeService,
    required this.browser,
    required this.editHandler,
    this.detailFormatter = const CartridgeDetailFormatter(),
    this.historyFormatter = const CartridgeHistoryFormatter(),
  });

  final CartridgeQueryService queryService;
  final CartridgeHistoryQueryService historyQueryService;
  final CartridgeService cartridgeService;
  final CartridgeBrowser browser;
  final CartridgeEditHandler editHandler;
  final CartridgeDetailFormatter detailFormatter;
  final CartridgeHistoryFormatter historyFormatter;

  void register(Bot<Context> bot) {
    bot.callbackQuery(RegExp(r'^cartridge:\d+:'), _openCartridge);
    bot.callbackQuery(RegExp(r'^status:\d+:'), _changeStatus);
    bot.callbackQuery(RegExp(r'^edit:\d+$'), _editCartridge);
    bot.callbackQuery(RegExp(r'^history:\d+:'), _showHistory);
    bot.callbackQuery(RegExp(r'^archive:\d+:'), _confirmArchive);
    bot.callbackQuery(RegExp(r'^archive-confirm:\d+:'), _archiveCartridge);
    bot.callbackQuery(RegExp(r'^archive-cancel:\d+:'), _cancelArchive);
    bot.callbackQuery(RegExp(r'^detail-back:\d+:'), _returnToDetails);
  }

  Future<void> _openCartridge(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'cartridge', 4);
    if (values == null) return;
    await _showDetails(
      context,
      int.parse(values[1]),
      routeId: values[2],
      page: int.parse(values[3]),
    );
  }

  Future<void> _changeStatus(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'status', 4);
    if (values == null) return;
    final id = int.parse(values[1]);

    try {
      final current = await queryService.findById(id);
      if (current == null) {
        await context.editMessageText('Картридж с ID $id не найден.');
        return;
      }
      if (current.archivedAt != null) {
        await context.editMessageText('Этот картридж архивирован.');
        return;
      }

      final nextStatus = cartridgeService.nextStatusFor(current.status);
      if (nextStatus == null) {
        await context.editMessageText(
          'Для этого статуса нет следующего действия.',
        );
        return;
      }

      await cartridgeService.changeStatus(
        cartridgeId: id,
        status: nextStatus,
        changedBy: telegramChangedBy(context),
      );
      await _showDetails(
        context,
        id,
        routeId: values[2],
        page: int.parse(values[3]),
      );
    } on CartridgeNotFoundException {
      await context.editMessageText('Картридж с ID $id не найден.');
    } on CartridgeAlreadyArchivedException {
      await context.editMessageText('Этот картридж архивирован.');
    } on InvalidCartridgeTransitionException {
      await context.editMessageText(
        'Статус успел измениться. Откройте карточку снова.',
      );
    }
  }

  Future<void> _editCartridge(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'edit', 2);
    if (values == null) return;
    await editHandler.showTemplate(context, int.parse(values[1]));
  }

  Future<void> _showHistory(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'history', 4);
    if (values == null) return;
    final id = int.parse(values[1]);
    final logs = await historyQueryService.latestForCartridge(id);
    final keyboard = InlineKeyboard(
      inlineKeyboard: [
        [
          InlineKeyboardButton(
            text: '⬅️ К карточке',
            callbackData: 'detail-back:$id:${values[2]}:${values[3]}',
          ),
        ],
      ],
    );
    await context.editMessageText(
      historyFormatter.format(id, logs),
      replyMarkup: keyboard,
    );
  }

  Future<void> _confirmArchive(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'archive', 4);
    if (values == null) return;
    final id = int.parse(values[1]);
    final cartridge = await queryService.findById(id);
    if (cartridge == null) {
      await context.editMessageText('Картридж с ID $id не найден.');
      return;
    }
    if (cartridge.archivedAt != null) {
      await context.editMessageText('Этот картридж уже архивирован.');
      return;
    }

    await context.editMessageText(
      'Убрать картридж #${cartridge.number} из активного списка?\n'
      'Запись и история сохранятся.',
      replyMarkup: InlineKeyboard(
        inlineKeyboard: [
          [
            InlineKeyboardButton(
              text: 'Да, убрать',
              callbackData: 'archive-confirm:$id:${values[2]}:${values[3]}',
            ),
            InlineKeyboardButton(
              text: 'Отмена',
              callbackData: 'archive-cancel:$id:${values[2]}:${values[3]}',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _archiveCartridge(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'archive-confirm', 4);
    if (values == null) return;
    final id = int.parse(values[1]);

    try {
      final archived = await cartridgeService.archive(
        cartridgeId: id,
        changedBy: telegramChangedBy(context),
      );
      await context.editMessageText(
        'Картридж #${archived.number} убран из активного списка. '
        'История сохранена.',
        replyMarkup: InlineKeyboard(
          inlineKeyboard: [
            [
              InlineKeyboardButton(
                text: '⬅️ К списку',
                callbackData: 'browse:${values[2]}:${values[3]}',
              ),
            ],
          ],
        ),
      );
    } on CartridgeNotFoundException {
      await context.editMessageText('Картридж с ID $id не найден.');
    } on CartridgeAlreadyArchivedException {
      await context.editMessageText('Картридж с ID $id уже архивирован.');
    }
  }

  Future<void> _cancelArchive(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'archive-cancel', 4);
    if (values == null) return;
    await _showDetails(
      context,
      int.parse(values[1]),
      routeId: values[2],
      page: int.parse(values[3]),
    );
  }

  Future<void> _returnToDetails(Context context) async {
    await context.answerCallbackQuery();
    final values = _callbackParts(context, 'detail-back', 4);
    if (values == null) return;
    await _showDetails(
      context,
      int.parse(values[1]),
      routeId: values[2],
      page: int.parse(values[3]),
    );
  }

  Future<void> _showDetails(
    Context context,
    int id, {
    required String routeId,
    required int page,
  }) async {
    final cartridge = await queryService.findById(id);
    if (cartridge == null) {
      await context.editMessageText('Картридж с ID $id не найден.');
      return;
    }

    final rows = <List<InlineKeyboardButton>>[];
    if (cartridge.archivedAt == null) {
      final nextStatus = cartridgeService.nextStatusFor(cartridge.status);
      if (nextStatus != null) {
        rows.add([
          InlineKeyboardButton(
            text: _statusActionLabel(nextStatus),
            callbackData: 'status:$id:$routeId:$page',
          ),
        ]);
      }
      rows.add([
        InlineKeyboardButton(text: '✏️ Изменить', callbackData: 'edit:$id'),
        InlineKeyboardButton(
          text: '📜 История',
          callbackData: 'history:$id:$routeId:$page',
        ),
      ]);
      rows.add([
        InlineKeyboardButton(
          text: '🗃 Убрать из списка',
          callbackData: 'archive:$id:$routeId:$page',
        ),
      ]);
    } else {
      rows.add([
        InlineKeyboardButton(
          text: '📜 История',
          callbackData: 'history:$id:$routeId:$page',
        ),
      ]);
    }
    rows.add([
      InlineKeyboardButton(
        text: '⬅️ Назад к результатам',
        callbackData: 'browse:$routeId:$page',
      ),
    ]);

    await context.editMessageText(
      detailFormatter.format(cartridge),
      replyMarkup: InlineKeyboard(inlineKeyboard: rows),
    );
  }

  List<String>? _callbackParts(
    Context context,
    String action,
    int expectedLength,
  ) {
    final data = context.callbackQuery?.data;
    if (data == null) return null;
    final parts = data.split(':');
    if (parts.length != expectedLength || parts.first != action) return null;
    return parts;
  }

  String _statusActionLabel(CartridgeStatus nextStatus) => switch (nextStatus) {
    CartridgeStatus.inUse => '📤 Выдать картридж',
    CartridgeStatus.empty => '🔴 Отметить пустым',
    CartridgeStatus.refilling => '🟡 Отправить на заправку',
    CartridgeStatus.ready => '🟢 Отметить готовым',
  };
}
