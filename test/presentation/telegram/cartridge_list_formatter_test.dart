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
      'Картриджи (1):\n• ID 1 · #001 — HP 85A — кабинет 101 — 🟢 Ready',
    );
  });

  test('formats all search matches and the search query', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final cartridges = [
      Cartridge(
        id: 1,
        number: '001',
        model: 'HP 85A',
        office: '101',
        status: CartridgeStatus.ready,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      Cartridge(
        id: 2,
        number: '001',
        model: 'HP 85A',
        office: '102',
        status: CartridgeStatus.empty,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    ];

    final result = formatter.formatSearchResults(
      cartridges: cartridges,
      query: 'номер 001',
    );

    expect(result, contains('найдено: 2'));
    expect(result, contains('ID 1 · #001'));
    expect(result, contains('ID 2 · #001'));
    expect(result, contains('#001 — HP 85A — кабинет 101'));
    expect(result, contains('#001 — HP 85A — кабинет 102'));
  });

  test('formats searches with no matches', () {
    expect(
      formatter.formatSearchResults(cartridges: const [], query: 'кабинет 999'),
      'По запросу «кабинет 999» ничего не найдено.',
    );
  });
}
