import 'package:cartlog/domain/cartridge/entities/cartridge_log.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_log_repository.dart';

final class CartridgeHistoryQueryService {
  const CartridgeHistoryQueryService({required this.repository});

  final CartridgeLogRepository repository;

  Future<List<CartridgeLog>> latestForCartridge(
    int cartridgeId, {
    int limit = 10,
  }) {
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 50.');
    }
    return repository.findLatestByCartridgeId(cartridgeId, limit: limit);
  }
}
