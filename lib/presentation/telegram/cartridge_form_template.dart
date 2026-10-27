import 'package:cartlog/domain/cartridge/entities/cartridge.dart';

final class CartridgeForm {
  const CartridgeForm({
    required this.number,
    required this.model,
    required this.office,
  });

  final String number;
  final String model;
  final String office;
}

final class CartridgeFormTemplate {
  const CartridgeFormTemplate._();

  static const add = '/add\nnumber=\nmodel=\noffice=';

  static String edit(Cartridge cartridge) {
    return '/edit ${cartridge.id}\n'
        'number=${cartridge.number}\n'
        'model=${cartridge.model}\n'
        'office=${cartridge.office}';
  }

  static CartridgeForm parse(String text) {
    final fields = <String, String>{};

    for (final originalLine in text.split(RegExp(r'\r?\n'))) {
      final line = originalLine.trim();
      if (line.isEmpty) continue;

      final separator = line.indexOf('=');
      if (separator < 0) {
        throw const FormatException('Use one field=value pair per line.');
      }

      final field = line.substring(0, separator).trim().toLowerCase();
      if (!const {'number', 'model', 'office'}.contains(field)) {
        throw FormatException('Unknown field "$field".');
      }
      if (fields.containsKey(field)) {
        throw FormatException('Field "$field" was provided more than once.');
      }

      fields[field] = line.substring(separator + 1).trim();
    }

    String requiredField(String name) {
      final value = fields[name];
      if (value == null || value.isEmpty) {
        throw FormatException('Field "$name" is required.');
      }
      return value;
    }

    return CartridgeForm(
      number: requiredField('number'),
      model: requiredField('model'),
      office: requiredField('office'),
    );
  }
}
