import 'dart:typed_data';

import 'package:cartlog/application/cartridge/cartridge_import_models.dart';
import 'package:cartlog/application/cartridge/cartridge_import_service.dart';
import 'package:cartlog/presentation/telegram/telegram_changed_by.dart';
import 'package:televerse/televerse.dart';
import 'package:televerse/telegram.dart';

final class CartridgeImportHandler {
  CartridgeImportHandler({required this.importService});

  static const _maximumFileBytes = 10 * 1024 * 1024;
  static const _previewLifetime = Duration(minutes: 10);
  static const _maximumPendingPreviews = 10;

  final CartridgeImportService importService;
  final Map<String, _PendingImport> _pendingImports = {};
  int _tokenCounter = 0;

  void register(Bot<Context> bot) {
    bot.command('import', prompt);
    bot.onDocument(_receiveCsv);
    bot.callbackQuery(
      RegExp(r'^import:(confirm|cancel):'),
      _handleConfirmation,
    );
  }

  Future<void> prompt(Context context) async {
    await context.reply(
      'Отправьте CSV-файл с разделителем «;».\n'
      'Ожидаются столбцы №, Модель и Кабинет. Статус необязателен.',
    );
  }

  Future<void> _receiveCsv(Context context) async {
    final document = context.message?.document;
    if (document == null) return;

    final fileName = document.fileName?.toLowerCase();
    if (fileName == null || !fileName.endsWith('.csv')) {
      await context.reply('Пожалуйста, отправьте файл с расширением .csv.');
      return;
    }
    if (document.fileSize != null && document.fileSize! > _maximumFileBytes) {
      await context.reply('Размер CSV-файла должен быть не больше 10 MB.');
      return;
    }

    try {
      final file = await context.api.getFile(document.fileId);
      final bytes = await file.getBytes(context.api.token);
      if (bytes == null) {
        await context.reply(
          'Не удалось скачать файл. Попробуйте отправить его ещё раз.',
        );
        return;
      }
      if (bytes.length > _maximumFileBytes) {
        await context.reply('Размер CSV-файла должен быть не больше 10 MB.');
        return;
      }

      final preview = await importService.preview(Uint8List.fromList(bytes));
      _pruneExpiredPreviews();
      if (preview.rows.isEmpty) {
        await context.reply(_formatPreview(preview));
        return;
      }

      final chatId = context.chat?.id;
      if (chatId == null) {
        await context.reply(
          'Не удалось определить чат для подтверждения импорта.',
        );
        return;
      }

      final token = _newToken();
      _pendingImports[token] = _PendingImport(
        preview: preview,
        chatId: chatId,
        expiresAt: DateTime.now().add(_previewLifetime),
      );
      while (_pendingImports.length > _maximumPendingPreviews) {
        _pendingImports.remove(_pendingImports.keys.first);
      }

      await context.reply(
        _formatPreview(preview),
        replyMarkup: InlineKeyboard(
          inlineKeyboard: [
            [
              InlineKeyboardButton(
                text: 'Импортировать ${preview.rows.length} строк',
                callbackData: 'import:confirm:$token',
              ),
              InlineKeyboardButton(
                text: 'Отмена',
                callbackData: 'import:cancel:$token',
              ),
            ],
          ],
        ),
      );
    } on FormatException catch (error) {
      await context.reply('Не удалось разобрать CSV: ${error.message}');
    }
  }

  Future<void> _handleConfirmation(Context context) async {
    await context.answerCallbackQuery();
    final parts = context.callbackQuery?.data?.split(':');
    if (parts == null || parts.length != 3) return;

    final token = parts[2];
    final pending = _pendingImports[token];
    if (pending == null || DateTime.now().isAfter(pending.expiresAt)) {
      _pendingImports.remove(token);
      await context.editMessageText(
        'Предпросмотр импорта устарел. Отправьте CSV ещё раз.',
      );
      return;
    }
    if (context.chat?.id != pending.chatId) {
      await context.editMessageText(
        'Этот предпросмотр импорта относится к другому чату.',
      );
      return;
    }

    if (parts[1] == 'cancel') {
      _pendingImports.remove(token);
      await context.editMessageText('Импорт отменён. Данные не изменены.');
      return;
    }
    if (parts[1] != 'confirm') return;

    // Remove before awaiting so a rapid double-click cannot import twice.
    _pendingImports.remove(token);
    try {
      final imported = await importService.importValidRows(
        preview: pending.preview,
        changedBy: telegramChangedBy(context),
      );
      await context.editMessageText(
        'Импорт завершён: добавлено ${imported.length} картриджей.\n'
        'Существующие записи не изменялись.',
      );
    } catch (_) {
      _pendingImports[token] = pending;
      await context.editMessageText(
        'Импорт не выполнен. Транзакция отменена; существующие данные не изменены.',
        replyMarkup: InlineKeyboard(
          inlineKeyboard: [
            [
              InlineKeyboardButton(
                text: 'Повторить импорт',
                callbackData: 'import:confirm:$token',
              ),
              InlineKeyboardButton(
                text: 'Отмена',
                callbackData: 'import:cancel:$token',
              ),
            ],
          ],
        ),
      );
    }
  }

  String _formatPreview(CartridgeImportPreview preview) {
    final buffer = StringBuffer()
      ..writeln('Предпросмотр CSV-импорта')
      ..writeln('Строк данных: ${preview.rowCount}')
      ..writeln('Готово к добавлению: ${preview.rows.length}')
      ..writeln('Ошибки строк: ${preview.errors.length}')
      ..writeln('Группы возможных дубликатов: ${preview.duplicates.length}')
      ..writeln()
      ..writeln(
        'Повторяющиеся номера не объединяются: подтверждённые строки '
        'будут добавлены как отдельные картриджи.',
      );

    for (final duplicate in preview.duplicates.take(5)) {
      final details = <String>[];
      if (duplicate.fileRowNumbers.length > 1) {
        final sampleRows = duplicate.fileRowNumbers.take(8).join(', ');
        final remainingRows = duplicate.fileRowNumbers.length - 8;
        details.add('строки $sampleRows${remainingRows > 0 ? ', …' : ''}');
      }
      if (duplicate.existingCartridges.isNotEmpty) {
        final existingIds = duplicate.existingCartridges
            .take(5)
            .map((cartridge) => cartridge.id)
            .join(', ');
        final remainingIds = duplicate.existingCartridges.length - 5;
        details.add('уже есть ID $existingIds${remainingIds > 0 ? ', …' : ''}');
      }
      buffer.writeln('• № ${duplicate.number}: ${details.join('; ')}');
    }
    if (preview.duplicates.length > 5) {
      buffer.writeln(
        '…и ещё ${preview.duplicates.length - 5} групп дубликатов.',
      );
    }

    for (final error in preview.errors.take(5)) {
      buffer.writeln('Строка ${error.rowNumber}: ${error.message}');
    }
    if (preview.errors.length > 5) {
      buffer.writeln('…и ещё ${preview.errors.length - 5} ошибок строк.');
    }
    return buffer.toString().trim();
  }

  void _pruneExpiredPreviews() {
    final now = DateTime.now();
    _pendingImports.removeWhere((_, value) => now.isAfter(value.expiresAt));
  }

  String _newToken() {
    _tokenCounter++;
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${_tokenCounter.toRadixString(36)}';
  }
}

final class _PendingImport {
  const _PendingImport({
    required this.preview,
    required this.chatId,
    required this.expiresAt,
  });

  final CartridgeImportPreview preview;
  final int chatId;
  final DateTime expiresAt;
}
