import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

/// Cartridge data before PostgreSQL assigns its ID and timestamps.
final class NewCartridge {
  const NewCartridge({
    required this.number,
    required this.model,
    required this.office,
    this.status = CartridgeStatus.ready,
    this.receivedAt,
    this.sentToRefillAt,
    this.readyAt,
    this.issuedAt,
  });

  final String number;
  final String model;
  final String office;
  final CartridgeStatus status;
  final DateTime? receivedAt;
  final DateTime? sentToRefillAt;
  final DateTime? readyAt;
  final DateTime? issuedAt;
}
