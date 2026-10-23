import 'package:cartlog/domain/cartridge/repositories/cartridge_log_repository.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_repository.dart';

abstract interface class CartridgeUnitOfWork {
  Future<T> run<T>(
    Future<T> Function(
      CartridgeRepository cartridges,
      CartridgeLogRepository logs,
    )
    operation,
  );
}
