import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

final class DatabaseConfig {
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.sslMode,
  });

  static const _variableNames = [
    'DATABASE_HOST',
    'DATABASE_PORT',
    'DATABASE_NAME',
    'DATABASE_USERNAME',
    'DATABASE_PASSWORD',
    'DATABASE_SSL_MODE',
  ];

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final SslMode sslMode;

  factory DatabaseConfig.load({String envFile = '.env'}) {
    final dotenv = DotEnv(quiet: true)..load([envFile]);
    final environment = <String, String>{};

    for (final name in _variableNames) {
      final value = dotenv[name];
      if (value != null) {
        environment[name] = value;
      }
    }

    environment.addAll(Platform.environment);
    return DatabaseConfig.fromEnvironment(environment);
  }

  factory DatabaseConfig.fromEnvironment(Map<String, String> environment) {
    String requiredValue(String name) {
      final value = environment[name]?.trim();
      if (value == null || value.isEmpty) {
        throw FormatException('Missing required environment variable: $name');
      }
      return value;
    }

    final portValue = environment['DATABASE_PORT']?.trim() ?? '5432';
    final port = int.tryParse(portValue);
    if (port == null || port < 1 || port > 65535) {
      throw FormatException('DATABASE_PORT must be between 1 and 65535.');
    }

    final sslModeValue =
        environment['DATABASE_SSL_MODE']?.trim().toLowerCase() ?? 'disable';
    final sslMode = switch (sslModeValue) {
      'disable' => SslMode.disable,
      'require' => SslMode.require,
      'verify-full' => SslMode.verifyFull,
      _ => throw FormatException(
        'DATABASE_SSL_MODE must be disable, require, or verify-full.',
      ),
    };

    return DatabaseConfig(
      host: requiredValue('DATABASE_HOST'),
      port: port,
      database: requiredValue('DATABASE_NAME'),
      username: requiredValue('DATABASE_USERNAME'),
      password: requiredValue('DATABASE_PASSWORD'),
      sslMode: sslMode,
    );
  }
}
