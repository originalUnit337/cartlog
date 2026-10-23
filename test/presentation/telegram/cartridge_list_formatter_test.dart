import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/presentation/telegram/cartridge_list_formatter.dart';
import 'package:test/test.dart';

void main() {
  const formatter = CartridgeListFormatter();

  test('shows an empty state when there are no cartridges', () {
    expect(formatter.format(const []), 'Картриджей пока нет.');
  });

  test('formats cartridge details with a localized status label', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final cartridge = Cartridge(
      id: 1,
      number: '001',
      model: 'HP 85A',
      office: '101',
      status: CartridgeStatus.ready,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(
      formatter.format([cartridge]),
      'Картриджи (1):\n• #001 — HP 85A — кабинет 101 — 🟢 Ready',
    );
  });
}
