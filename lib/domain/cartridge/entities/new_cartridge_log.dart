import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

/// Log data before PostgreSQL assigns its ID and creation timestamp.
final class NewCartridgeLog {
  const NewCartridgeLog({
    required this.cartridgeId,
    required this.action,
    required this.occurredAt,
    required this.changedBy,
    this.oldStatus,
    this.newStatus,
    this.comment,
  });

  final int cartridgeId;
  final CartridgeLogAction action;
  final CartridgeStatus? oldStatus;
  final CartridgeStatus? newStatus;
  final DateTime occurredAt;
  final String changedBy;
  final String? comment;
}
