import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_repository.dart';

import 'cartridge_page.dart';

final class CartridgeQueryService {
  const CartridgeQueryService({required this.repository});

  final CartridgeRepository repository;

  Future<List<Cartridge>> listAll() => repository.findAll();

  Future<Cartridge?> findById(int id) => repository.findById(id);

  Future<List<Cartridge>> findByNumber(String number) =>
      repository.findByNumber(number.trim());

  Future<List<Cartridge>> findByOffice(String office) =>
      repository.findByOffice(office.trim());

  Future<CartridgePage> listPage({int page = 0, int pageSize = 10}) {
    return _loadPage(
      page: page,
      pageSize: pageSize,
      fetch: (offset, limit) =>
          repository.findPage(offset: offset, limit: limit),
    );
  }

  Future<CartridgePage> findByNumberPage(
    String number, {
    int page = 0,
    int pageSize = 10,
  }) {
    return _loadPage(
      page: page,
      pageSize: pageSize,
      fetch: (offset, limit) => repository.findByNumberPage(
        number.trim(),
        offset: offset,
        limit: limit,
      ),
    );
  }

  Future<CartridgePage> findByOfficePage(
    String office, {
    int page = 0,
    int pageSize = 10,
  }) {
    return _loadPage(
      page: page,
      pageSize: pageSize,
      fetch: (offset, limit) => repository.findByOfficePage(
        office.trim(),
        offset: offset,
        limit: limit,
      ),
    );
  }

  Future<CartridgePage> _loadPage({
    required int page,
    required int pageSize,
    required Future<List<Cartridge>> Function(int offset, int limit) fetch,
  }) async {
    if (page < 0) {
      throw ArgumentError.value(page, 'page', 'Must not be negative.');
    }
    if (pageSize < 1 || pageSize > 20) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'Must be between 1 and 20.',
      );
    }

    final rows = await fetch(page * pageSize, pageSize + 1);
    final hasNext = rows.length > pageSize;

    return CartridgePage(
      items: rows.take(pageSize).toList(),
      page: page,
      pageSize: pageSize,
      hasNext: hasNext,
    );
  }
}
