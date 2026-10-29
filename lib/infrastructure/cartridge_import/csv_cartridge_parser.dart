import 'dart:convert';
import 'dart:typed_data';

import 'package:cartlog/application/cartridge/cartridge_import_models.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';
import 'package:csv/csv.dart';
import 'package:enough_convert/enough_convert.dart';

final class CsvCartridgeParser implements CartridgeImportParser {
  const CsvCartridgeParser();

  @override
  ParsedCartridgeFile parse(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('The CSV file is empty.');
    }

    final contents = _decode(bytes);
    final rows = Csv(
      fieldDelimiter: ';',
      autoDetect: false,
      skipEmptyLines: false,
    ).decode(contents);
    if (rows.isEmpty) throw const FormatException('The CSV file has no rows.');

    final columns = _readColumns(rows.first);
    _validateHeaders(columns);

    final parsedRows = <ParsedCartridgeRow>[];
    final errors = <CartridgeImportRowError>[];
    var rowCount = 0;

    for (final (index, values) in rows.skip(1).indexed) {
      if (values.every((value) => _cellText(value).trim().isEmpty)) continue;
      rowCount++;
      final csvRowNumber = index + 2;

      try {
        final paddedValues = [...values];
        if (paddedValues.length > columns.length) {
          throw const FormatException('Row has more fields than the header.');
        }
        while (paddedValues.length < columns.length) {
          paddedValues.add('');
        }

        final cells = <String, String>{};
        for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
          final name = columns[columnIndex];
          cells[name] = _cellText(paddedValues[columnIndex]).trim();
        }

        final number = _required(cells, 'number');
        final model = _required(cells, 'model');
        final office = cells['office']?.isEmpty ?? true
            ? '-'
            : cells['office']!;

        final status = _status(cells['status'] ?? '');
        final sourceDate = _optionalDate(cells['source_date'], 'Дата');
        final receivedAt = _optionalDate(cells['received_at'], 'Дата приема');
        final sentToRefillAt = _optionalDate(
          cells['sent_to_refill_at'],
          'Дата на заправку',
        );
        final readyAt = _optionalDate(cells['ready_at'], 'Дата готовности');
        final issuedAt = _optionalDate(cells['issued_at'], 'Дата выдачи');
        final comment = cells['comment']?.trim();

        parsedRows.add(
          ParsedCartridgeRow(
            rowNumber: csvRowNumber,
            cartridge: NewCartridge(
              number: number,
              model: model,
              office: office,
              status: status,
              receivedAt: receivedAt,
              sentToRefillAt: sentToRefillAt,
              readyAt: readyAt,
              issuedAt: issuedAt,
            ),
            occurredAt: sourceDate,
            comment: comment == null || comment.isEmpty ? null : comment,
          ),
        );
      } on FormatException catch (error) {
        errors.add(
          CartridgeImportRowError(
            rowNumber: csvRowNumber,
            message: error.message.toString(),
          ),
        );
      }
    }

    return ParsedCartridgeFile(
      rowCount: rowCount,
      rows: parsedRows,
      errors: errors,
    );
  }

  String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      // This export is Windows-1251, a common encoding for Russian Excel CSVs.
      return const Windows1251Codec(allowInvalid: false).decode(bytes);
    }
  }

  List<String> _readColumns(List<dynamic> headerRow) {
    return headerRow.map((cell) {
      final header = _cellText(cell).replaceFirst('\uFEFF', '').trim();
      final key = header.toLowerCase().replaceAll('ё', 'е');
      if (key.isEmpty) {
        throw const FormatException('CSV contains a blank column header.');
      }
      return switch (key) {
        '№' || 'number' => 'number',
        'дата' || 'source_date' || 'occurred_at' => 'source_date',
        'модель' || 'model' => 'model',
        'кабинет' || 'office' => 'office',
        'статус' || 'status' => 'status',
        'дата приема' || 'received_at' => 'received_at',
        'дата на заправку' || 'sent_to_refill_at' => 'sent_to_refill_at',
        'дата готовности' || 'ready_at' => 'ready_at',
        'дата выдачи' || 'issued_at' => 'issued_at',
        'столбец1' || 'comment' || 'note' => 'comment',
        _ => throw FormatException('Unsupported CSV column "$header".'),
      };
    }).toList();
  }

  void _validateHeaders(List<String> headers) {
    for (final required in const ['number', 'model', 'office']) {
      if (!headers.contains(required)) {
        throw FormatException(
          'CSV is missing the required "$required" column.',
        );
      }
    }
    if (headers.toSet().length != headers.length) {
      throw const FormatException('CSV contains duplicate recognized headers.');
    }
  }

  String _required(Map<String, String> cells, String field) {
    final value = cells[field]?.trim();
    if (value == null || value.isEmpty) {
      throw FormatException('Required field "$field" is blank.');
    }
    return value;
  }

  CartridgeStatus _status(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('ё', 'е');
    return switch (normalized) {
      '' || 'готов' || 'ready' => CartridgeStatus.ready,
      'принят' => CartridgeStatus.ready,
      'выдан' || 'используется' || 'in_use' => CartridgeStatus.inUse,
      'пуст' || 'empty' => CartridgeStatus.empty,
      'на заправке' || 'refilling' => CartridgeStatus.refilling,
      _ => throw FormatException('Unknown status "$value".'),
    };
  }

  DateTime? _optionalDate(String? value, String column) {
    if (value == null || value.isEmpty) return null;

    final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(value);
    if (match == null) {
      throw FormatException(
        'Invalid date "$value" in column "$column"; expected DD.MM.YYYY.',
      );
    }

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('Invalid calendar date "$value" in "$column".');
    }
    return date;
  }

  String _cellText(Object? value) => value?.toString() ?? '';
}
