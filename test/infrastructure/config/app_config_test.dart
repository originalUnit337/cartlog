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
      });

      expect(config.database.host, 'localhost');
      expect(config.database.port, 5434);
      expect(config.database.sslMode, SslMode.disable);
      expect(config.telegramBot.token, 'test-token');
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
