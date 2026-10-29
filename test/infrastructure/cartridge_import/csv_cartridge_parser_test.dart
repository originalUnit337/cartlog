import 'dart:typed_data';

import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/infrastructure/cartridge_import/csv_cartridge_parser.dart';
import 'package:enough_convert/enough_convert.dart';
import 'package:test/test.dart';

void main() {
  const parser = CsvCartridgeParser();
  const windows1251 = Windows1251Codec(allowInvalid: false);

  test('parses the Russian semicolon export and preserves leading zeroes', () {
    final bytes = Uint8List.fromList(
      windows1251.encode(
        '№;Дата;Модель;Кабинет;Статус;Дата приема;Дата на заправку;'
        'Дата готовности;Дата выдачи;Столбец1\r\n'
        '001;30.07.2026;PC-211;515-1;выдан;30.07.2026;;30.07.2026;'
        '04.08.2026;\r\n'
        '002;20.08.2026;C-725;приёмная-1;принят;23.10.2026;;;;'
        '"ждем чип; потом проверить"',
      ),
    );

    final parsed = parser.parse(bytes);

    expect(parsed.rowCount, 2);
    expect(parsed.errors, isEmpty);
    expect(parsed.rows, hasLength(2));
    expect(parsed.rows.first.cartridge.number, '001');
    expect(parsed.rows.first.cartridge.status, CartridgeStatus.inUse);
    expect(parsed.rows.first.cartridge.receivedAt, DateTime.utc(2026, 7, 30));
    expect(parsed.rows.first.occurredAt, DateTime.utc(2026, 7, 30));
    expect(parsed.rows[1].cartridge.status, CartridgeStatus.ready);
    expect(parsed.rows[1].cartridge.office, 'приёмная-1');
    expect(parsed.rows[1].comment, 'ждем чип; потом проверить');
  });

  test('defaults blank statuses and offices to the approved values', () {
    final bytes = Uint8List.fromList(
      windows1251.encode('№;Модель;Кабинет;Статус\n003;PC-211;;'),
    );

    final parsed = parser.parse(bytes);

    expect(parsed.errors, isEmpty);
    expect(parsed.rows.single.cartridge.status, CartridgeStatus.ready);
    expect(parsed.rows.single.cartridge.office, '-');
  });

  test('reports row errors for unrecognized statuses and malformed dates', () {
    final bytes = Uint8List.fromList(
      windows1251.encode(
        '№;Модель;Кабинет;Статус;Дата выдачи\n'
        '004;PC-211;101;неизвестно;01.09.2026\n'
        '005;PC-211;102;готов;31.02.2026',
      ),
    );

    final parsed = parser.parse(bytes);

    expect(parsed.rowCount, 2);
    expect(parsed.rows, isEmpty);
    expect(parsed.errors, hasLength(2));
    expect(parsed.errors.map((error) => error.rowNumber), [2, 3]);
  });

  test(
    'rejects unsupported headers rather than silently discarding columns',
    () {
      final bytes = Uint8List.fromList(
        windows1251.encode(
          '№;Модель;Кабинет;Неизвестная колонка\n001;PC-211;101;x',
        ),
      );

      expect(() => parser.parse(bytes), throwsFormatException);
    },
  );
}
