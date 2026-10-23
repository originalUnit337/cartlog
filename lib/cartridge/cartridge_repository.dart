import 'package:cartlog/cartridge/models/cartridge.dart';
import 'package:cartlog/cartridge/models/cartridge_status.dart';

abstract interface class CartridgeRepository {
  Future<Cartridge?> findById(int id);

  Future<List<Cartridge>> findAll();

  Future<List<Cartridge>> findByNumber(String number);

  Future<List<Cartridge>> findByOffice(String office);

  Future<List<Cartridge>> findByStatus(CartridgeStatus status);

  Future<Cartridge> create(Cartridge cartridge);

  Future<Cartridge> update(Cartridge cartridge);
}