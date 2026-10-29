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
        return 'Готов';
      case .inUse:
        return 'Используется';
      case .empty:
        return 'Пуст';
      case .refilling:
        return 'На заправке';
    }
  }

  String get displayLabel => '$displayEmoji $displayName';
}
