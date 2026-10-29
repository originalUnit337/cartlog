import 'dart:async';
import 'dart:io';

import 'package:cartlog/application/cartridge/cartridge_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_history_query_service.dart';
import 'package:cartlog/application/cartridge/cartridge_import_service.dart';
import 'package:cartlog/application/cartridge/cartridge_service.dart';
import 'package:cartlog/infrastructure/config/app_config.dart';
import 'package:cartlog/infrastructure/database/postgres_database.dart';
import 'package:cartlog/infrastructure/database/postgres_cartridge_unit_of_work.dart';
import 'package:cartlog/infrastructure/cartridge_import/csv_cartridge_parser.dart';
import 'package:cartlog/infrastructure/database/repositories/postgres_cartridge_log_repository.dart';
import 'package:cartlog/infrastructure/database/repositories/postgres_cartridge_repository.dart';
import 'package:cartlog/presentation/telegram/telegram_bot.dart';

/// Configures dependencies and starts the Telegram bot.
Future<void> main() async {
  final config = AppConfig.load();
  final database = await PostgresDatabase.connect(config.database);
  final cartridgeRepository = PostgresCartridgeRepository(
    session: database.session,
  );
  final cartridgeLogRepository = PostgresCartridgeLogRepository(
    session: database.session,
  );
  final unitOfWork = PostgresCartridgeUnitOfWork(
    sessionExecutor: database.sessionExecutor,
  );
  final bot = TelegramBot(
    token: config.telegramBot.token,
    cartridgeQueryService: CartridgeQueryService(
      repository: cartridgeRepository,
    ),
    cartridgeHistoryQueryService: CartridgeHistoryQueryService(
      repository: cartridgeLogRepository,
    ),
    cartridgeService: CartridgeService(unitOfWork: unitOfWork),
    cartridgeImportService: CartridgeImportService(
      parser: const CsvCartridgeParser(),
      repository: cartridgeRepository,
      unitOfWork: unitOfWork,
    ),
  );
  final signalSubscriptions = [
    ProcessSignal.sigint.watch().listen((_) => unawaited(bot.stop())),
    ProcessSignal.sigterm.watch().listen((_) => unawaited(bot.stop())),
  ];

  try {
    await database.checkConnection();
    await bot.start();
  } finally {
    for (final subscription in signalSubscriptions) {
      await subscription.cancel();
    }
    await bot.close();
    await database.close();
  }
}
