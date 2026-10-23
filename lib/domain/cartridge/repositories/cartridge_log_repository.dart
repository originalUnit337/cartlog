import 'package:cartlog/domain/cartridge/entities/cartridge_log.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge_log.dart';

abstract interface class CartridgeLogRepository {
  Future<CartridgeLog> create(NewCartridgeLog log);

  Future<List<CartridgeLog>> findByCartridgeId(int cartridgeId);
}
