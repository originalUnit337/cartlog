/// Telegram profile fields supplied with an interaction update.
final class TelegramUserProfile {
  const TelegramUserProfile({
    required this.telegramId,
    required this.firstName,
    this.lastName,
    this.username,
    this.languageCode,
    this.isPremium,
    this.addedToAttachmentMenu,
  });

  final int telegramId;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? languageCode;
  final bool? isPremium;
  final bool? addedToAttachmentMenu;
}
