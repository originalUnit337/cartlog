import 'package:televerse/televerse.dart';

final class TelegramAdminAccess {
  const TelegramAdminAccess({required this.adminIds});

  final Set<int> adminIds;

  bool isAdmin(Context context) {
    return canAccess(
      userId: context.from?.id,
      isPrivateChat: context.isPrivateChat,
    );
  }

  bool canAccess({required int? userId, required bool isPrivateChat}) =>
      isPrivateChat && userId != null && adminIds.contains(userId);
}
