import 'package:cartlog/domain/telegram/entities/telegram_user_profile.dart';

abstract interface class TelegramUserRepository {
  /// Inserts a Telegram user or refreshes their profile and last-seen time.
  Future<void> upsertInteraction(TelegramUserProfile profile);
}
