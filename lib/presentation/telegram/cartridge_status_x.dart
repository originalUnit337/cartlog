import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

extension CartridgeStatusX on CartridgeStatus {
  String get displayName {
    switch (this) {
      case .ready:
        return 'Ready';
      case .inUse:
        return 'In use';
      case .empty:
        return 'Empty';
      case .refilling:
        return 'Refilling';
    }
  }
}
