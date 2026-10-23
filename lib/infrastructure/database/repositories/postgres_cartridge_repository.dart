import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_repository.dart';
import 'package:cartlog/infrastructure/database/mappers/postgres_row_mapper.dart';
import 'package:postgres/postgres.dart';

final class PostgresCartridgeRepository implements CartridgeRepository {
  const PostgresCartridgeRepository({required this.session});

  final Session session;

  @override
  Future<Cartridge?> findById(int id) async {
    final result = await session.execute(
      Sql.named('SELECT * FROM cartridges WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return PostgresRowMapper.toCartridge(result.first.toColumnMap());
  }

  @override
  Future<Cartridge?> findByIdForUpdate(int id) async {
    final result = await session.execute(
      Sql.named('SELECT * FROM cartridges WHERE id = @id FOR UPDATE'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return PostgresRowMapper.toCartridge(result.first.toColumnMap());
  }

  @override
  Future<List<Cartridge>> findAll() async {
    final result = await session.execute(
      'SELECT * FROM cartridges ORDER BY id',
    );
    return result
        .map((row) => PostgresRowMapper.toCartridge(row.toColumnMap()))
        .toList();
  }

  @override
  Future<List<Cartridge>> findByNumber(String number) async {
    final result = await session.execute(
      Sql.named('SELECT * FROM cartridges WHERE number = @number ORDER BY id'),
      parameters: {'number': number},
    );
    return result
        .map((row) => PostgresRowMapper.toCartridge(row.toColumnMap()))
        .toList();
  }

  @override
  Future<List<Cartridge>> findByOffice(String office) async {
    final result = await session.execute(
      Sql.named('SELECT * FROM cartridges WHERE office = @office ORDER BY id'),
      parameters: {'office': office},
    );
    return result
        .map((row) => PostgresRowMapper.toCartridge(row.toColumnMap()))
        .toList();
  }

  @override
  Future<List<Cartridge>> findByStatus(CartridgeStatus status) async {
    final result = await session.execute(
      Sql.named('SELECT * FROM cartridges WHERE status = @status ORDER BY id'),
      parameters: {'status': PostgresRowMapper.statusToDatabase(status)},
    );
    return result
        .map((row) => PostgresRowMapper.toCartridge(row.toColumnMap()))
        .toList();
  }

  @override
  Future<Cartridge> create(NewCartridge cartridge) async {
    final result = await session.execute(
      Sql.named('''
        INSERT INTO cartridges (
          number,
          model,
          office,
          status,
          received_at,
          sent_to_refill_at,
          ready_at,
          issued_at
        ) VALUES (
          @number,
          @model,
          @office,
          @status,
          @receivedAt,
          @sentToRefillAt,
          @readyAt,
          @issuedAt
        )
        RETURNING *
      '''),
      parameters: {
        'number': cartridge.number,
        'model': cartridge.model,
        'office': cartridge.office,
        'status': PostgresRowMapper.statusToDatabase(cartridge.status),
        'receivedAt': cartridge.receivedAt,
        'sentToRefillAt': cartridge.sentToRefillAt,
        'readyAt': cartridge.readyAt,
        'issuedAt': cartridge.issuedAt,
      },
    );
    return PostgresRowMapper.toCartridge(result.first.toColumnMap());
  }

  @override
  Future<Cartridge> update(Cartridge cartridge) async {
    final result = await session.execute(
      Sql.named('''
        UPDATE cartridges
        SET number = @number,
            model = @model,
            office = @office,
            status = @status,
            received_at = @receivedAt,
            sent_to_refill_at = @sentToRefillAt,
            ready_at = @readyAt,
            issued_at = @issuedAt
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': cartridge.id,
        'number': cartridge.number,
        'model': cartridge.model,
        'office': cartridge.office,
        'status': PostgresRowMapper.statusToDatabase(cartridge.status),
        'receivedAt': cartridge.receivedAt,
        'sentToRefillAt': cartridge.sentToRefillAt,
        'readyAt': cartridge.readyAt,
        'issuedAt': cartridge.issuedAt,
      },
    );
    if (result.isEmpty) {
      throw StateError('Cartridge ${cartridge.id} does not exist.');
    }
    return PostgresRowMapper.toCartridge(result.first.toColumnMap());
  }
}
