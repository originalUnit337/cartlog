import 'package:cartlog/infrastructure/database/database_config.dart';
import 'package:cartlog/infrastructure/database/postgres_database.dart';

Future<void> main() async {
  final config = DatabaseConfig.load();
  final database = await PostgresDatabase.connect(config);

  try {
    await database.checkConnection();
    print('Connected to PostgreSQL.');
  } finally {
    await database.close();
  }
}
