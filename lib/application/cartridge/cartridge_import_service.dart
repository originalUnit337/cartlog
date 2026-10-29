import 'dart:typed_data';

import 'package:cartlog/application/cartridge/cartridge_import_models.dart';
import 'package:cartlog/application/cartridge/cartridge_unit_of_work.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge_log.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_repository.dart';

final class CartridgeImportService {
  const CartridgeImportService({
    required this.parser,
    required this.repository,
    required this.unitOfWork,
  });

  final CartridgeImportParser parser;
  final CartridgeRepository repository;
  final CartridgeUnitOfWork unitOfWork;

  static const maximumRowCount = 5000;

  Future<CartridgeImportPreview> preview(Uint8List bytes) async {
    final parsedFile = parser.parse(bytes);
    if (parsedFile.rowCount > maximumRowCount) {
      throw FormatException(
        'CSV has ${parsedFile.rowCount} rows; the limit is $maximumRowCount.',
      );
    }
    final rowsByNumber = <String, List<int>>{};
    for (final row in parsedFile.rows) {
      rowsByNumber
          .putIfAbsent(row.cartridge.number, () => [])
          .add(row.rowNumber);
    }

    final existingCartridges = await repository.findByNumbers(
      rowsByNumber.keys.toList(),
    );
    final existingByNumber = <String, List<Cartridge>>{};
    for (final cartridge in existingCartridges) {
      existingByNumber.putIfAbsent(cartridge.number, () => []).add(cartridge);
    }

    final duplicateNumbers = <String>{
      ...rowsByNumber.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) => entry.key),
      ...existingByNumber.keys,
    };
    final duplicates = duplicateNumbers.map((number) {
      return CartridgeImportDuplicate(
        number: number,
        fileRowNumbers: rowsByNumber[number] ?? const [],
        existingCartridges: existingByNumber[number] ?? const [],
      );
    }).toList()..sort((left, right) => left.number.compareTo(right.number));

    return CartridgeImportPreview(
      rowCount: parsedFile.rowCount,
      rows: parsedFile.rows,
      errors: parsedFile.errors,
      duplicates: duplicates,
    );
  }

  Future<List<Cartridge>> importValidRows({
    required CartridgeImportPreview preview,
    required String changedBy,
  }) async {
    if (preview.rows.isEmpty) return const [];
    final importedAt = DateTime.now().toUtc();

    return unitOfWork.run((cartridges, logs) async {
      final imported = <Cartridge>[];
      for (final row in preview.rows) {
        final cartridge = await cartridges.create(row.cartridge);
        await logs.create(
          NewCartridgeLog(
            cartridgeId: cartridge.id,
            action: CartridgeLogAction.created,
            newStatus: cartridge.status,
            occurredAt: row.occurredAt ?? importedAt,
            changedBy: changedBy,
            comment: row.comment,
          ),
        );
        imported.add(cartridge);
      }
      return imported;
    });
  }
}
