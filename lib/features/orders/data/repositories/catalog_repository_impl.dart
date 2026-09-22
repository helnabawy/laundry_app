import '../../../../core/error/guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;

  @override
  Future<Result<List<ServiceCategory>>> getCategories() =>
      guard(_remote.getCategories);

  @override
  Future<Result<List<SubService>>> getSubServices(String categoryId) =>
      guard(() => _remote.getSubServices(categoryId));

  @override
  Future<Result<List<ServiceTier>>> getTiers() => guard(_remote.getTiers);

  @override
  Future<Result<List<TimeSlot>>> getPickupSlots(DateTime day, String tierId) =>
      guard(() => _remote.getPickupSlots(day, tierId));

  @override
  Future<Result<List<TimeSlot>>> getDeliverySlots(
    DateTime day,
    String tierId, {
    required DateTime notBefore,
  }) => guard(() => _remote.getDeliverySlots(day, tierId, notBefore));
}
