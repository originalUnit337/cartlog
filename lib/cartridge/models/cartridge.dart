import 'package:cartlog/cartridge/models/cartridge_status.dart';

class Cartridge {
  final int id;
  final String number;
  final String model;
  final String office;
  final CartridgeStatus status;

  final DateTime? receivedAt;
  final DateTime? sentToRefilAt;
  final DateTime? readyAt;
  final DateTime? issuedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  Cartridge({
    required this.id,
    required this.number,
    required this.model,
    required this.office,
    required this.status,
    this.receivedAt,
    this.sentToRefilAt,
    this.readyAt,
    this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}