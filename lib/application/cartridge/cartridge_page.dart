import 'package:cartlog/domain/cartridge/entities/cartridge.dart';

final class CartridgePage {
  const CartridgePage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasNext,
  });

  final List<Cartridge> items;
  final int page;
  final int pageSize;
  final bool hasNext;

  bool get hasPrevious => page > 0;
}
