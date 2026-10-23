import 'package:cartlog/infrastructure/config/environment_loader.dart';
import 'package:cartlog/infrastructure/config/telegram_bot_config.dart';
import 'package:cartlog/infrastructure/database/database_config.dart';

final class AppConfig {
  const AppConfig({required this.database, required this.telegramBot});

  final DatabaseConfig database;
  final TelegramBotConfig telegramBot;

  factory AppConfig.load({String envFile = '.env'}) {
    return AppConfig.fromEnvironment(
      loadEnvironment(
        variableNames: [
          ...DatabaseConfig.environmentVariableNames,
          ...TelegramBotConfig.environmentVariableNames,
        ],
        envFile: envFile,
      ),
    );
  }

  factory AppConfig.fromEnvironment(Map<String, String> environment) {
    return AppConfig(
      database: DatabaseConfig.fromEnvironment(environment),
      telegramBot: TelegramBotConfig.fromEnvironment(environment),
    );
  }
}
