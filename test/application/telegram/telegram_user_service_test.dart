import 'package:cartlog/application/telegram/telegram_user_service.dart';
import 'package:cartlog/domain/telegram/entities/telegram_user_profile.dart';
import 'package:cartlog/domain/telegram/repositories/telegram_user_repository.dart';
import 'package:test/test.dart';

void main() {
  late _MemoryTelegramUserRepository repository;
  late TelegramUserService service;

  setUp(() {
    repository = _MemoryTelegramUserRepository();
    service = TelegramUserService(repository: repository);
  });

  test('trims Telegram profile fields before upserting', () async {
    await service.recordInteraction(
      const TelegramUserProfile(
        telegramId: 123,
        firstName: ' Alice ',
        lastName: ' Example ',
        username: ' alice ',
        languageCode: ' en ',
        isPremium: true,
        addedToAttachmentMenu: false,
      ),
    );

    expect(repository.profile?.telegramId, 123);
    expect(repository.profile?.firstName, 'Alice');
    expect(repository.profile?.lastName, 'Example');
    expect(repository.profile?.username, 'alice');
    expect(repository.profile?.languageCode, 'en');
    expect(repository.profile?.isPremium, isTrue);
  });

  test('rejects a profile with an invalid Telegram ID', () {
    expect(
      () => service.recordInteraction(
        const TelegramUserProfile(telegramId: 0, firstName: 'Alice'),
      ),
      throwsArgumentError,
    );
  });

  test('rejects an empty first name', () {
    expect(
      () => service.recordInteraction(
        const TelegramUserProfile(telegramId: 123, firstName: '  '),
      ),
      throwsArgumentError,
    );
  });
}

final class _MemoryTelegramUserRepository implements TelegramUserRepository {
  TelegramUserProfile? profile;

  @override
  Future<void> upsertInteraction(TelegramUserProfile profile) async {
    this.profile = profile;
  }
}
