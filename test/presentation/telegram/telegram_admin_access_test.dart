import 'package:cartlog/presentation/telegram/telegram_admin_access.dart';
import 'package:test/test.dart';

void main() {
  const access = TelegramAdminAccess(adminIds: {123, 456});

  test('allows configured IDs only in private chats', () {
    expect(access.canAccess(userId: 123, isPrivateChat: true), isTrue);
    expect(access.canAccess(userId: 123, isPrivateChat: false), isFalse);
    expect(access.canAccess(userId: 789, isPrivateChat: true), isFalse);
    expect(access.canAccess(userId: null, isPrivateChat: true), isFalse);
  });

  test('empty allowlist grants no admin access', () {
    const noAdmins = TelegramAdminAccess(adminIds: {});

    expect(noAdmins.canAccess(userId: 123, isPrivateChat: true), isFalse);
  });
}
