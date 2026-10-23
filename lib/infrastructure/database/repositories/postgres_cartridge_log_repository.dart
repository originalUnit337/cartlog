import 'package:cartlog/domain/cartridge/entities/cartridge_log.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge_log.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_log_repository.dart';
import 'package:cartlog/infrastructure/database/mappers/postgres_row_mapper.dart';
import 'package:postgres/postgres.dart';

final class PostgresCartridgeLogRepository implements CartridgeLogRepository {
  const PostgresCartridgeLogRepository({required this.session});

  final Session session;

  @override
  Future<CartridgeLog> create(NewCartridgeLog log) async {
    final result = await session.execute(
      Sql.named('''
        INSERT INTO cartridge_logs (
          cartridge_id,
          action,
          old_status,
          new_status,
          occurred_at,
          changed_by,
          comment
        ) VALUES (
          @cartridgeId,
          @action,
          @oldStatus,
          @newStatus,
          @occurredAt,
          @changedBy,
          @comment
        )
        RETURNING *
      '''),
      parameters: {
        'cartridgeId': log.cartridgeId,
        'action': PostgresRowMapper.actionToDatabase(log.action),
        'oldStatus': _nullableStatusToDatabase(log.oldStatus),
        'newStatus': _nullableStatusToDatabase(log.newStatus),
        'occurredAt': log.occurredAt,
        'changedBy': log.changedBy,
        'comment': log.comment,
      },
    );
    return PostgresRowMapper.toCartridgeLog(result.first.toColumnMap());
  }

  @override
  Future<List<CartridgeLog>> findByCartridgeId(int cartridgeId) async {
    final result = await session.execute(
      Sql.named('''
        SELECT *
        FROM cartridge_logs
        WHERE cartridge_id = @cartridgeId
        ORDER BY occurred_at DESC, id DESC
      '''),
      parameters: {'cartridgeId': cartridgeId},
    );
    return result
        .map((row) => PostgresRowMapper.toCartridgeLog(row.toColumnMap()))
        .toList();
  }

  String? _nullableStatusToDatabase(CartridgeStatus? status) {
    return status == null ? null : PostgresRowMapper.statusToDatabase(status);
  }
}
