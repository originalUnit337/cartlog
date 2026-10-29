import 'package:cartlog/application/cartridge/cartridge_unit_of_work.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_log_repository.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_repository.dart';
import 'package:cartlog/infrastructure/database/repositories/postgres_cartridge_log_repository.dart';
import 'package:cartlog/infrastructure/database/repositories/postgres_cartridge_repository.dart';
import 'package:postgres/postgres.dart';

final class PostgresCartridgeUnitOfWork implements CartridgeUnitOfWork {
  const PostgresCartridgeUnitOfWork({required this.sessionExecutor});

  final SessionExecutor sessionExecutor;

  @override
  Future<T> run<T>(
    Future<T> Function(
      CartridgeRepository cartridges,
      CartridgeLogRepository logs,
    )
    operation,
  ) {
    return sessionExecutor.runTx((session) {
      return operation(
        PostgresCartridgeRepository(session: session),
        PostgresCartridgeLogRepository(session: session),
      );
    });
  }
}
