import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

final class CartridgeNotFoundException implements Exception {
  const CartridgeNotFoundException(this.cartridgeId);

  final int cartridgeId;

  @override
  String toString() => 'Cartridge $cartridgeId was not found.';
}

final class InvalidCartridgeTransitionException implements Exception {
  const InvalidCartridgeTransitionException({
    required this.from,
    required this.to,
  });

  final CartridgeStatus from;
  final CartridgeStatus to;

  @override
  String toString() => 'Cannot change cartridge status from $from to $to.';
}
