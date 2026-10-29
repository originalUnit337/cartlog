import 'package:postgres/postgres.dart';

import 'database_config.dart';

final class PostgresDatabase {
  PostgresDatabase._(this._connection);

  final Connection _connection;

  Session get session => _connection;

  SessionExecutor get sessionExecutor => _connection;

  static Future<PostgresDatabase> connect(DatabaseConfig config) async {
    final connection = await Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      ),
      settings: ConnectionSettings(
        applicationName: 'cartlog',
        sslMode: config.sslMode,
      ),
    );

    return PostgresDatabase._(connection);
  }

  Future<void> checkConnection() async {
    await _connection.execute('SELECT 1');
  }

  Future<void> close() => _connection.close();
}
