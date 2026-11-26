import 'package:cartlog/application/telegram/telegram_user_service.dart';
import 'package:cartlog/domain/telegram/entities/telegram_user_profile.dart';
import 'package:televerse/televerse.dart';

final class TelegramUserTrackingMiddleware {
  const TelegramUserTrackingMiddleware({required this.userService});

  final TelegramUserService userService;

  Future<void> call(Context context, NextFunction next) async {
    final user = context.from;
    if (user != null && !user.isBot) {
      try {
        await userService.recordInteraction(
          TelegramUserProfile(
            telegramId: user.id,
            firstName: user.firstName,
            lastName: user.lastName,
            username: user.username,
            languageCode: user.languageCode,
            isPremium: user.isPremium,
            addedToAttachmentMenu: user.addedToAttachmentMenu,
          ),
        );
      } catch (error) {
        // User tracking must not interrupt regular bot commands. Keep the
        // failure visible in the server logs without printing profile data.
        print('Telegram user profile upsert failed: $error');
      }
    }

    await next();
  }
}
