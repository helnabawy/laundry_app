import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';
import '../models/service_category_model.dart';
import '../models/service_tier_model.dart';
import '../models/sub_service_model.dart';
import '../models/time_slot_model.dart';
import 'catalog_remote_data_source.dart';

class CatalogApiDataSource implements CatalogRemoteDataSource {
  const CatalogApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<ServiceCategory>> getCategories() async {
    final json =
        await _api.get(ApiEndpoints.serviceCategories) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(ServiceCategoryModel.fromJson)
        .toList();
  }

  @override
  Future<List<SubService>> getSubServices(String categoryId) async {
    final json =
        await _api.get(ApiEndpoints.subServices(categoryId)) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(SubServiceModel.fromJson)
        .toList();
  }

  @override
  Future<List<ServiceTier>> getTiers() async {
    final json = await _api.get(ApiEndpoints.serviceTiers) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(ServiceTierModel.fromJson)
        .toList();
  }

  @override
  Future<List<TimeSlot>> getPickupSlots(DateTime day, String tierId) =>
      _getSlots(day, tierId, type: 'pickup');

  @override
  Future<List<TimeSlot>> getDeliverySlots(
    DateTime day,
    String tierId,
    DateTime notBefore,
  ) => _getSlots(day, tierId, type: 'delivery', notBefore: notBefore);

  Future<List<TimeSlot>> _getSlots(
    DateTime day,
    String tierId, {
    required String type,
    DateTime? notBefore,
  }) async {
    final json = await _api.get(
      ApiEndpoints.timeSlots,
      query: {
        'date': _dateOnly(day),
        'tier': tierId,
        'type': type,
        if (notBefore != null) 'notBefore': notBefore.toIso8601String(),
      },
    ) as List<dynamic>;
    return json
        .cast<Map<String, dynamic>>()
        .map(TimeSlotModel.fromJson)
        .toList();
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
