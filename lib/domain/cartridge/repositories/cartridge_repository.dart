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

  Future<List<Cartridge>> findByNumberPage(
    String number, {
    required int offset,
    required int limit,
  });

  Future<List<Cartridge>> findByOffice(String office);

  Future<List<Cartridge>> findByOfficePage(
    String office, {
    required int offset,
    required int limit,
  });

  Future<List<Cartridge>> findByStatus(CartridgeStatus status);

  Future<Cartridge> create(NewCartridge cartridge);

  Future<Cartridge> update(Cartridge cartridge);
}
