import 'package:televerse/televerse.dart';

String telegramChangedBy(Context context) {
  final user = context.from;
  if (user == null) return 'telegram:unknown';

  final username = user.username;
  return username == null
      ? 'telegram:${user.id}'
      : 'telegram:${user.id} (@$username)';
}
