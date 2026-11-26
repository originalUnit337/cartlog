final class TelegramBotConfig {
  const TelegramBotConfig({required this.token, required this.adminIds});

  static const environmentVariableNames = [
    'TELEGRAM_BOT_TOKEN',
    'TELEGRAM_ADMIN_IDS',
  ];

  final String token;
  final Set<int> adminIds;

  factory TelegramBotConfig.fromEnvironment(Map<String, String> environment) {
    final token = environment['TELEGRAM_BOT_TOKEN']?.trim();
    if (token == null || token.isEmpty) {
      throw const FormatException(
        'Missing required environment variable: TELEGRAM_BOT_TOKEN',
      );
    }
    final adminIdsValue = environment['TELEGRAM_ADMIN_IDS']?.trim() ?? '';
    final adminIds = <int>{};
    if (adminIdsValue.isNotEmpty) {
      for (final value in adminIdsValue.split(',')) {
        final id = int.tryParse(value.trim());
        if (id == null || id <= 0) {
          throw const FormatException(
            'TELEGRAM_ADMIN_IDS must be a comma-separated list of positive Telegram IDs.',
          );
        }
        adminIds.add(id);
      }
    }

    return TelegramBotConfig(
      token: token,
      adminIds: Set.unmodifiable(adminIds),
    );
  }
}
