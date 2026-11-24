import 'package:cartlog/application/admin/database_backup_provider.dart';
import 'package:cartlog/infrastructure/database/database_config.dart';
import 'package:cartlog/presentation/telegram/telegram_admin_access.dart';
import 'package:cartlog/presentation/telegram/telegram_menu_labels.dart';
import 'package:televerse/televerse.dart';

final class DatabaseBackupHandler {
  DatabaseBackupHandler({
    required this.backupProvider,
    required this.adminAccess,
    required this.databaseConfig,
  });

  static const _maximumTelegramDocumentBytes = 49 * 1024 * 1024;

  final DatabaseBackupProvider backupProvider;
  final TelegramAdminAccess adminAccess;
  final DatabaseConfig databaseConfig;
  bool _backupInProgress = false;

  void register(Bot<Context> bot) {
    bot.command('backup', createBackup);
    bot.text(TelegramMenuLabels.databaseBackup, createBackup);
  }

  Future<void> createBackup(Context context) async {
    if (!adminAccess.isAdmin(context)) {
      await context.reply(
        context.isPrivateChat
            ? 'Эта функция доступна только администраторам.'
            : 'Создавать резервную копию можно только в личном чате с ботом.',
      );
      return;
    }
    if (_backupInProgress) {
      await context.reply('Резервная копия уже создаётся. Подождите немного.');
      return;
    }

    _backupInProgress = true;
    try {
      await context.reply('Создаю резервную копию базы данных…');
      final backup = await backupProvider.createBackup();
      try {
        final backupName = backup.file.uri.pathSegments.last;
        final size = await backup.file.length();
        if (size > _maximumTelegramDocumentBytes) {
          await context.reply(
            'Резервная копия создана, но файл слишком большой для отправки '
            'через Telegram (${(size / (1024 * 1024)).toStringAsFixed(1)} MB). '
            'Используйте ручную команду pg_dump на сервере.',
          );
          return;
        }

        await context.replyWithDocument(
          InputFile.fromFile(
            backup.file,
            name: backupName,
            mimeType: 'application/octet-stream',
          ),
          caption: 'Резервная копия PostgreSQL (custom format).',
        );
        await context.reply(_restoreInstructions(backupName));
      } finally {
        await backup.dispose();
      }
    } catch (error) {
      // The error message is useful in server logs; don't expose connection
      // details or credential-related output in Telegram.
      print('Database backup failed: $error');
      await context.reply(
        'Не удалось создать или отправить резервную копию. '
        'Проверьте логи бота на сервере.',
      );
    } finally {
      _backupInProgress = false;
    }
  }

  String _restoreInstructions(String temporaryPath) {
    final user = _shellQuote(databaseConfig.username);
    final database = _shellQuote(databaseConfig.database);
    final file = _shellQuote(temporaryPath.split('/').last);
    return '''
Чтобы восстановить эту копию на сервере:
1. Скопируйте скачанный файл в каталог проекта рядом с compose.yaml.
2. Сначала сделайте копию текущей базы; восстановление заменит её содержимое.
3. Остановите бота и выполните:

docker compose stop bot
docker compose exec -T db pg_restore -U $user -d $database --clean --if-exists < $file
docker compose start bot
'''
        .trim();
  }

  String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
