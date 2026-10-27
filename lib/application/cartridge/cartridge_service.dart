import 'package:cartlog/application/cartridge/cartridge_exceptions.dart';
import 'package:cartlog/application/cartridge/cartridge_unit_of_work.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_log_action.dart';
import 'package:cartlog/domain/cartridge/entities/cartridge_status.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge.dart';
import 'package:cartlog/domain/cartridge/entities/new_cartridge_log.dart';

final class CartridgeService {
  const CartridgeService({required this.unitOfWork});

  final CartridgeUnitOfWork unitOfWork;

  Future<Cartridge> create({
    required NewCartridge cartridge,
    required String changedBy,
    DateTime? occurredAt,
    String? comment,
  }) async {
    _validateDetails(cartridge.number, cartridge.model, cartridge.office);
    final eventTime = (occurredAt ?? DateTime.now()).toUtc();
    final cleanCartridge = NewCartridge(
      number: cartridge.number.trim(),
      model: cartridge.model.trim(),
      office: cartridge.office.trim(),
      status: cartridge.status,
      receivedAt: cartridge.receivedAt,
      sentToRefillAt: cartridge.sentToRefillAt,
      readyAt: cartridge.readyAt,
      issuedAt: cartridge.issuedAt,
    );

    return unitOfWork.run((cartridges, logs) async {
      final created = await cartridges.create(cleanCartridge);
      await logs.create(
        NewCartridgeLog(
          cartridgeId: created.id,
          action: CartridgeLogAction.created,
          newStatus: created.status,
          occurredAt: eventTime,
          changedBy: changedBy,
          comment: comment,
        ),
      );
      return created;
    });
  }

  Future<Cartridge> updateDetails({
    required int cartridgeId,
    required String number,
    required String model,
    required String office,
    required String changedBy,
    DateTime? occurredAt,
    String? comment,
  }) async {
    _validateDetails(number, model, office);
    final eventTime = (occurredAt ?? DateTime.now()).toUtc();

    return unitOfWork.run((cartridges, logs) async {
      final current = await cartridges.findByIdForUpdate(cartridgeId);
      if (current == null) throw CartridgeNotFoundException(cartridgeId);
      if (current.archivedAt != null) {
        throw CartridgeAlreadyArchivedException(cartridgeId);
      }

      final updated = await cartridges.update(
        _withDetails(
          current,
          number: number.trim(),
          model: model.trim(),
          office: office.trim(),
        ),
      );
      await logs.create(
        NewCartridgeLog(
          cartridgeId: cartridgeId,
          action: CartridgeLogAction.updated,
          oldStatus: current.status,
          newStatus: current.status,
          occurredAt: eventTime,
          changedBy: changedBy,
          comment: comment,
        ),
      );
      return updated;
    });
  }

  Future<Cartridge> archive({
    required int cartridgeId,
    required String changedBy,
    DateTime? occurredAt,
    String? comment,
  }) async {
    final eventTime = (occurredAt ?? DateTime.now()).toUtc();

    return unitOfWork.run((cartridges, logs) async {
      final current = await cartridges.findByIdForUpdate(cartridgeId);
      if (current == null) throw CartridgeNotFoundException(cartridgeId);
      if (current.archivedAt != null) {
        throw CartridgeAlreadyArchivedException(cartridgeId);
      }

      final archived = await cartridges.update(
        _withArchivedAt(current, eventTime),
      );
      await logs.create(
        NewCartridgeLog(
          cartridgeId: cartridgeId,
          action: CartridgeLogAction.removed,
          oldStatus: current.status,
          newStatus: current.status,
          occurredAt: eventTime,
          changedBy: changedBy,
          comment: comment,
        ),
      );
      return archived;
    });
  }

  Future<Cartridge> changeStatus({
    required int cartridgeId,
    required CartridgeStatus status,
    required String changedBy,
    DateTime? occurredAt,
    String? comment,
  }) async {
    final changed = await changeStatusForMany(
      cartridgeIds: [cartridgeId],
      status: status,
      changedBy: changedBy,
      occurredAt: occurredAt,
      comment: comment,
    );
    return changed.single;
  }

  Future<List<Cartridge>> changeStatusForMany({
    required List<int> cartridgeIds,
    required CartridgeStatus status,
    required String changedBy,
    DateTime? occurredAt,
    String? comment,
  }) async {
    final ids = cartridgeIds.toSet().toList();
    if (ids.isEmpty) return const [];

    final eventTime = (occurredAt ?? DateTime.now()).toUtc();

    return unitOfWork.run((cartridges, logs) async {
      final currentById = <int, Cartridge>{};
      final lockOrder = [...ids]..sort();

      // Lock in a stable order so overlapping batches are less likely to deadlock.
      for (final id in lockOrder) {
        final current = await cartridges.findByIdForUpdate(id);
        if (current == null) throw CartridgeNotFoundException(id);
        if (current.archivedAt != null) {
          throw CartridgeAlreadyArchivedException(id);
        }
        currentById[id] = current;
      }

      // Validate the entire batch before changing any cartridge.
      final updatesById = <int, Cartridge>{};
      for (final id in ids) {
        final current = currentById[id]!;
        if (!_isAllowedTransition(current.status, status)) {
          throw InvalidCartridgeTransitionException(
            from: current.status,
            to: status,
          );
        }
        updatesById[id] = _withStatus(current, status, eventTime);
      }

      final updatedCartridges = <Cartridge>[];
      for (final id in ids) {
        final current = currentById[id]!;
        final updated = await cartridges.update(updatesById[id]!);
        await logs.create(
          NewCartridgeLog(
            cartridgeId: id,
            action: CartridgeLogAction.statusChanged,
            oldStatus: current.status,
            newStatus: status,
            occurredAt: eventTime,
            changedBy: changedBy,
            comment: comment,
          ),
        );
        updatedCartridges.add(updated);
      }

      return updatedCartridges;
    });
  }

  bool _isAllowedTransition(CartridgeStatus from, CartridgeStatus to) {
    return switch ((from, to)) {
      (CartridgeStatus.ready, CartridgeStatus.inUse) ||
      (CartridgeStatus.inUse, CartridgeStatus.empty) ||
      (CartridgeStatus.empty, CartridgeStatus.refilling) ||
      (CartridgeStatus.refilling, CartridgeStatus.ready) => true,
      _ => false,
    };
  }

  Cartridge _withStatus(
    Cartridge current,
    CartridgeStatus status,
    DateTime occurredAt,
  ) {
    return Cartridge(
      id: current.id,
      number: current.number,
      model: current.model,
      office: current.office,
      status: status,
      receivedAt: current.receivedAt,
      sentToRefillAt: status == CartridgeStatus.refilling
          ? occurredAt
          : current.sentToRefillAt,
      readyAt: status == CartridgeStatus.ready ? occurredAt : current.readyAt,
      issuedAt: status == CartridgeStatus.inUse ? occurredAt : current.issuedAt,
      archivedAt: current.archivedAt,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
  }

  Cartridge _withDetails(
    Cartridge current, {
    required String number,
    required String model,
    required String office,
  }) {
    return Cartridge(
      id: current.id,
      number: number,
      model: model,
      office: office,
      status: current.status,
      receivedAt: current.receivedAt,
      sentToRefillAt: current.sentToRefillAt,
      readyAt: current.readyAt,
      issuedAt: current.issuedAt,
      archivedAt: current.archivedAt,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
  }

  Cartridge _withArchivedAt(Cartridge current, DateTime archivedAt) {
    return Cartridge(
      id: current.id,
      number: current.number,
      model: current.model,
      office: current.office,
      status: current.status,
      receivedAt: current.receivedAt,
      sentToRefillAt: current.sentToRefillAt,
      readyAt: current.readyAt,
      issuedAt: current.issuedAt,
      archivedAt: archivedAt,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
  }

  void _validateDetails(String number, String model, String office) {
    if (number.trim().isEmpty ||
        model.trim().isEmpty ||
        office.trim().isEmpty) {
      throw const FormatException('Number, model, and office are required.');
    }
  }
}
