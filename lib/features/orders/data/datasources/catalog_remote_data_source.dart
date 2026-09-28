import '../../domain/entities/product.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';

abstract interface class CatalogRemoteDataSource {
  Future<List<ServiceCategory>> getCategories();
  Future<List<SubService>> getSubServices(String categoryId);
  Future<List<Product>> getProducts();
  Future<List<ServiceTier>> getTiers();
  Future<List<TimeSlot>> getPickupSlots(DateTime day, String tierId);
  Future<List<TimeSlot>> getDeliverySlots(
    DateTime day,
    String tierId,
    DateTime notBefore,
  );
}
