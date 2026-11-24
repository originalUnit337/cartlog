import 'package:cartlog/domain/telegram/entities/telegram_user_profile.dart';
import 'package:cartlog/domain/telegram/repositories/telegram_user_repository.dart';

final class TelegramUserService {
  const TelegramUserService({required this.repository});

  final TelegramUserRepository repository;

  Future<void> recordInteraction(TelegramUserProfile profile) {
    if (profile.telegramId <= 0) {
      throw ArgumentError.value(
        profile.telegramId,
        'telegramId',
        'Telegram ID must be positive.',
      );
    }
    if (profile.firstName.trim().isEmpty) {
      throw ArgumentError.value(
        profile.firstName,
        'firstName',
        'Telegram first name cannot be empty.',
      );
    }
    return repository.upsertInteraction(
      TelegramUserProfile(
        telegramId: profile.telegramId,
        firstName: profile.firstName.trim(),
        lastName: _trimOrNull(profile.lastName),
        username: _trimOrNull(profile.username),
        languageCode: _trimOrNull(profile.languageCode),
        isPremium: profile.isPremium,
        addedToAttachmentMenu: profile.addedToAttachmentMenu,
      ),
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
