import 'package:cartlog/infrastructure/database/database_config.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('DatabaseConfig.fromEnvironment', () {
    test('reads required values and defaults the port and SSL mode', () {
      final config = DatabaseConfig.fromEnvironment({
        'DATABASE_HOST': 'localhost',
        'DATABASE_NAME': 'cartlog',
        'DATABASE_USERNAME': 'cartlog',
        'DATABASE_PASSWORD': 'secret',
      });

      expect(config.host, 'localhost');
      expect(config.port, 5432);
      expect(config.database, 'cartlog');
      expect(config.username, 'cartlog');
      expect(config.password, 'secret');
      expect(config.sslMode, SslMode.disable);
    });

    test('parses port and SSL mode', () {
      final config = DatabaseConfig.fromEnvironment({
        'DATABASE_HOST': 'db.example.com',
        'DATABASE_PORT': '6432',
        'DATABASE_NAME': 'cartlog',
        'DATABASE_USERNAME': 'cartlog',
        'DATABASE_PASSWORD': 'secret',
        'DATABASE_SSL_MODE': 'verify-full',
      });

      expect(config.port, 6432);
      expect(config.sslMode, SslMode.verifyFull);
    });

    test('rejects missing required values', () {
      expect(() => DatabaseConfig.fromEnvironment({}), throwsFormatException);
    });

    test('rejects an invalid port', () {
      expect(
        () => DatabaseConfig.fromEnvironment({
          'DATABASE_HOST': 'localhost',
          'DATABASE_PORT': '70000',
          'DATABASE_NAME': 'cartlog',
          'DATABASE_USERNAME': 'cartlog',
          'DATABASE_PASSWORD': 'secret',
        }),
        throwsFormatException,
      );
    });
  });
}
