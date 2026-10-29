import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';

abstract interface class CartridgeRepository {
  Future<Cartridge?> findById(int id);

  /// Finds a cartridge and locks its row until the current transaction ends.
  Future<Cartridge?> findByIdForUpdate(int id);

  Future<List<Cartridge>> findAll();

  Future<List<Cartridge>> findPage({required int offset, required int limit});

  Future<List<Cartridge>> findByNumber(String number);

  /// Finds all records for the supplied numbers, including archived records.
  Future<List<Cartridge>> findByNumbers(List<String> numbers);

  Future<List<Cartridge>> findByNumberPage(
    String number, {
    required int offset,
    required int limit,
  });

  /// Finds active cartridges whose office starts with [officePrefix].
  Future<List<Cartridge>> findByOffice(String officePrefix);

  /// Finds a page of active cartridges whose office starts with [officePrefix].
  Future<List<Cartridge>> findByOfficePage(
    String officePrefix, {
    required int offset,
    required int limit,
  });

  Future<List<Cartridge>> findByStatus(CartridgeStatus status);

  Future<Cartridge> create(NewCartridge cartridge);

  Future<Cartridge> update(Cartridge cartridge);
}
