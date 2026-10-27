import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/repositories/cartridge_repository.dart';

final class CartridgeQueryService {
  const CartridgeQueryService({required this.repository});

  final CartridgeRepository repository;

  Future<List<Cartridge>> listAll() => repository.findAll();

  Future<Cartridge?> findById(int id) => repository.findById(id);

  Future<List<Cartridge>> findByNumber(String number) =>
      repository.findByNumber(number.trim());

  Future<List<Cartridge>> findByOffice(String office) =>
      repository.findByOffice(office.trim());
}
