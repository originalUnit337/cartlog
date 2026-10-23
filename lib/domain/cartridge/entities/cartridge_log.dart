import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

final class CartridgeLog {
  const CartridgeLog({
    required this.id,
    required this.cartridgeId,
    required this.action,
    required this.oldStatus,
    required this.newStatus,
    required this.occurredAt,
    required this.createdAt,
    required this.changedBy,
    required this.comment,
  });

  final int id;
  final int cartridgeId;
  final CartridgeLogAction action;
  final CartridgeStatus? oldStatus;
  final CartridgeStatus? newStatus;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String changedBy;
  final String? comment;
}
