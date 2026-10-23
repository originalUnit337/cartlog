import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

extension CartridgeStatusX on CartridgeStatus {
  String get displayEmoji => switch (this) {
    .ready => '🟢',
    .inUse => '🔵',
    .empty => '🔴',
    .refilling => '🟡',
  };

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

  String get displayLabel => '$displayEmoji $displayName';
}
