import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/presentation/telegram/cartridge_detail_formatter.dart';
import 'package:test/test.dart';

void main() {
  test('formats a cartridge card with its ID, status, and lifecycle dates', () {
    final cartridge = Cartridge(
      id: 42,
      number: '001',
      model: 'HP 85A',
      office: '101',
      status: CartridgeStatus.inUse,
      receivedAt: DateTime.utc(2026, 1, 2),
      sentToRefillAt: DateTime.utc(2026, 2, 3),
      readyAt: DateTime.utc(2026, 2, 4),
      issuedAt: DateTime.utc(2026, 2, 5),
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 2, 5),
    );

    final details = const CartridgeDetailFormatter().format(cartridge);

    expect(details, contains('ID 42 · #001'));
    expect(details, contains('Модель: HP 85A'));
    expect(details, contains('Статус: 🔵 Используется'));
    expect(details, contains('Отправлен на заправку:'));
    expect(details, contains('Выдан:'));
  });
}
