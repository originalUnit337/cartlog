final class TelegramBotConfig {
  const TelegramBotConfig({required this.token});

  static const environmentVariableNames = ['TELEGRAM_BOT_TOKEN'];

  final String token;

  factory TelegramBotConfig.fromEnvironment(Map<String, String> environment) {
    final token = environment['TELEGRAM_BOT_TOKEN']?.trim();
    if (token == null || token.isEmpty) {
      throw const FormatException(
        'Missing required environment variable: TELEGRAM_BOT_TOKEN',
      );
    }
    return TelegramBotConfig(token: token);
  }
}
