import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/presentation/telegram/cartridge_form_template.dart';
import 'package:test/test.dart';

void main() {
  test('parses field=value lines and keeps spaces inside values', () {
    final form = CartridgeFormTemplate.parse(
      'number=001\r\nmodel=HP LaserJet 85A\r\noffice=Room 101',
    );

    expect(form.number, '001');
    expect(form.model, 'HP LaserJet 85A');
    expect(form.office, 'Room 101');
  });

  test('rejects missing values and unknown fields', () {
    expect(
      () => CartridgeFormTemplate.parse('number=001\nmodel=HP 85A\noffice='),
      throwsFormatException,
    );
    expect(
      () => CartridgeFormTemplate.parse(
        'number=001\nmodel=HP 85A\noffice=101\nstatus=empty',
      ),
      throwsFormatException,
    );
  });

  test('creates an edit form with the cartridge ID and existing values', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final cartridge = Cartridge(
      id: 7,
      number: '001',
      model: 'HP 85A',
      office: '101',
      status: CartridgeStatus.ready,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(
      CartridgeFormTemplate.edit(cartridge),
      '/edit 7\nnumber=001\nmodel=HP 85A\noffice=101',
    );
  });
}
