import 'package:cartlog/infrastructure/config/app_config.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig.fromEnvironment', () {
    test('loads database and Telegram configuration', () {
      final config = AppConfig.fromEnvironment({
        'DATABASE_HOST': 'localhost',
        'DATABASE_PORT': '5434',
        'DATABASE_NAME': 'cartlog',
        'DATABASE_USERNAME': 'cartlog',
        'DATABASE_PASSWORD': 'secret',
        'DATABASE_SSL_MODE': 'disable',
        'TELEGRAM_BOT_TOKEN': '  test-token  ',
        'TELEGRAM_ADMIN_IDS': '12345, 67890,12345',
      });

      expect(config.database.host, 'localhost');
      expect(config.database.port, 5434);
      expect(config.database.sslMode, SslMode.disable);
      expect(config.telegramBot.token, 'test-token');
      expect(config.telegramBot.adminIds, {12345, 67890});
    });

    test('defaults to no admins when the admin allowlist is empty', () {
      final config = AppConfig.fromEnvironment({
        'DATABASE_HOST': 'localhost',
        'DATABASE_NAME': 'cartlog',
        'DATABASE_USERNAME': 'cartlog',
        'DATABASE_PASSWORD': 'secret',
        'TELEGRAM_BOT_TOKEN': 'test-token',
      });

      expect(config.telegramBot.adminIds, isEmpty);
    });

    test('rejects invalid admin IDs', () {
      expect(
        () => AppConfig.fromEnvironment({
          'DATABASE_HOST': 'localhost',
          'DATABASE_NAME': 'cartlog',
          'DATABASE_USERNAME': 'cartlog',
          'DATABASE_PASSWORD': 'secret',
          'TELEGRAM_BOT_TOKEN': 'test-token',
          'TELEGRAM_ADMIN_IDS': '123,not-an-id',
        }),
        throwsFormatException,
      );
    });

    test('requires a Telegram bot token', () {
      expect(
        () => AppConfig.fromEnvironment({
          'DATABASE_HOST': 'localhost',
          'DATABASE_NAME': 'cartlog',
          'DATABASE_USERNAME': 'cartlog',
          'DATABASE_PASSWORD': 'secret',
        }),
        throwsFormatException,
      );
    });
  });
}
