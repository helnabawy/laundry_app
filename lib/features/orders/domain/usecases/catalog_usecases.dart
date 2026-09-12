import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/service_category.dart';
import '../entities/service_tier.dart';
import '../entities/sub_service.dart';
import '../entities/time_slot.dart';
import '../repositories/catalog_repository.dart';

class GetServiceCategories
    implements UseCase<List<ServiceCategory>, NoParams> {
  const GetServiceCategories(this._repo);
  final CatalogRepository _repo;

  @override
  Future<Result<List<ServiceCategory>>> call([
    NoParams params = const NoParams(),
  ]) => _repo.getCategories();
}

class GetSubServices implements UseCase<List<SubService>, String> {
  const GetSubServices(this._repo);
  final CatalogRepository _repo;

  @override
  Future<Result<List<SubService>>> call(String categoryId) =>
      _repo.getSubServices(categoryId);
}

class GetServiceTiers implements UseCase<List<ServiceTier>, NoParams> {
  const GetServiceTiers(this._repo);
  final CatalogRepository _repo;

  @override
  Future<Result<List<ServiceTier>>> call([
    NoParams params = const NoParams(),
  ]) => _repo.getTiers();
}

class GetPickupSlots
    implements UseCase<List<TimeSlot>, ({DateTime day, String tierId})> {
  const GetPickupSlots(this._repo);
  final CatalogRepository _repo;

  @override
  Future<Result<List<TimeSlot>>> call(({DateTime day, String tierId}) params) =>
      _repo.getPickupSlots(params.day, params.tierId);
}

class GetDeliverySlots
    implements
        UseCase<
          List<TimeSlot>,
          ({DateTime day, String tierId, DateTime notBefore})
        > {
  const GetDeliverySlots(this._repo);
  final CatalogRepository _repo;

  @override
  Future<Result<List<TimeSlot>>> call(
    ({DateTime day, String tierId, DateTime notBefore}) params,
  ) => _repo.getDeliverySlots(
    params.day,
    params.tierId,
    notBefore: params.notBefore,
  );
}
