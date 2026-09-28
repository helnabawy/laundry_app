import '../../../../core/result/result.dart';
import '../entities/product.dart';
import '../entities/service_category.dart';
import '../entities/service_tier.dart';
import '../entities/sub_service.dart';
import '../entities/time_slot.dart';

/// Reference/scheduling data (plan §5 `GET /api/service-categories`,
/// `/api/service-tiers`, `/api/timeslots`).
abstract interface class CatalogRepository {
  Future<Result<List<ServiceCategory>>> getCategories();
  Future<Result<List<SubService>>> getSubServices(String categoryId);

  /// The shop flow's flat, unfiltered product catalog.
  Future<Result<List<Product>>> getProducts();
  Future<Result<List<ServiceTier>>> getTiers();

  Future<Result<List<TimeSlot>>> getPickupSlots(DateTime day, String tierId);

  /// [notBefore] narrows delivery slots to the tier's turnaround (plan step
  /// 2.5: "فترات التسليم المتاحة فقط بناءً على مستوى الخدمة المختار").
  Future<Result<List<TimeSlot>>> getDeliverySlots(
    DateTime day,
    String tierId, {
    required DateTime notBefore,
  });
}
