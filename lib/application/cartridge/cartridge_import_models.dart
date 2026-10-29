import 'dart:typed_data';

import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';

abstract interface class CartridgeImportParser {
  ParsedCartridgeFile parse(Uint8List bytes);
}

final class ParsedCartridgeRow {
  const ParsedCartridgeRow({
    required this.rowNumber,
    required this.cartridge,
    this.occurredAt,
    this.comment,
  });

  final int rowNumber;
  final NewCartridge cartridge;
  final DateTime? occurredAt;
  final String? comment;
}

final class CartridgeImportRowError {
  const CartridgeImportRowError({
    required this.rowNumber,
    required this.message,
  });

  final int rowNumber;
  final String message;
}

final class ParsedCartridgeFile {
  const ParsedCartridgeFile({
    required this.rowCount,
    required this.rows,
    required this.errors,
  });

  final int rowCount;
  final List<ParsedCartridgeRow> rows;
  final List<CartridgeImportRowError> errors;
}

final class CartridgeImportDuplicate {
  const CartridgeImportDuplicate({
    required this.number,
    required this.fileRowNumbers,
    required this.existingCartridges,
  });

  final String number;
  final List<int> fileRowNumbers;
  final List<Cartridge> existingCartridges;
}

final class CartridgeImportPreview {
  const CartridgeImportPreview({
    required this.rowCount,
    required this.rows,
    required this.errors,
    required this.duplicates,
  });

  final int rowCount;
  final List<ParsedCartridgeRow> rows;
  final List<CartridgeImportRowError> errors;
  final List<CartridgeImportDuplicate> duplicates;
}
