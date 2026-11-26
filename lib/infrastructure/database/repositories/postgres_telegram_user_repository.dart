import 'package:cartlog/domain/telegram/entities/telegram_user_profile.dart';
import 'package:cartlog/domain/telegram/repositories/telegram_user_repository.dart';
import 'package:postgres/postgres.dart';

final class PostgresTelegramUserRepository implements TelegramUserRepository {
  const PostgresTelegramUserRepository({required this.session});

  final Session session;

  @override
  Future<void> upsertInteraction(TelegramUserProfile profile) async {
    await session.execute(
      Sql.named('''
        INSERT INTO telegram_users (
          telegram_id,
          first_name,
          last_name,
          username,
          language_code,
          is_premium,
          added_to_attachment_menu
        ) VALUES (
          @telegramId,
          @firstName,
          @lastName,
          @username,
          @languageCode,
          @isPremium,
          @addedToAttachmentMenu
        )
        ON CONFLICT (telegram_id) DO UPDATE SET
          first_name = EXCLUDED.first_name,
          last_name = EXCLUDED.last_name,
          username = EXCLUDED.username,
          language_code = EXCLUDED.language_code,
          is_premium = EXCLUDED.is_premium,
          added_to_attachment_menu = EXCLUDED.added_to_attachment_menu,
          last_seen_at = CURRENT_TIMESTAMP
      '''),
      parameters: {
        'telegramId': profile.telegramId,
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'username': profile.username,
        'languageCode': profile.languageCode,
        'isPremium': profile.isPremium,
        'addedToAttachmentMenu': profile.addedToAttachmentMenu,
      },
      ignoreRows: true,
    );
  }
}
