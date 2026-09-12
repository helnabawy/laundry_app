import '../../../../core/mock/mock_database.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';
import 'catalog_remote_data_source.dart';

/// Reference data for the order wizard (plan §1: 4 categories, 2 tiers) plus
/// deterministic slot generation.
///
/// Also exposes plain lookups (not part of [CatalogRemoteDataSource]) that
/// [OrderMockDataSource] uses to resolve ids chosen during order creation.
class CatalogMockDataSource implements CatalogRemoteDataSource {
  CatalogMockDataSource(this._db);

  final MockDatabase _db;

  static const _windows = [(9, 11), (11, 13), (16, 18), (18, 20)];

  static final _categoriesRaw = [
    (
      id: 'cat-clothes',
      name: {'ar': 'ملابس', 'en': 'Clothes'},
      description: {'ar': 'غسيل، كي، خدمة كاملة', 'en': 'Wash, iron, full service'},
    ),
    (
      id: 'cat-textiles',
      name: {'ar': 'مفروشات', 'en': 'Home Textiles'},
      description: {'ar': 'مفارش، أغطية، وسائد', 'en': 'Sheets, covers, pillows'},
    ),
    (
      id: 'cat-carpets',
      name: {'ar': 'سجاد', 'en': 'Carpets'},
      description: {'ar': 'تنظيف عميق وغسيل', 'en': 'Deep cleaning & wash'},
    ),
    (
      id: 'cat-curtains',
      name: {'ar': 'ستائر', 'en': 'Curtains'},
      description: {'ar': 'فك، غسيل، وكي', 'en': 'Take-down, wash & iron'},
    ),
  ];

  static final _subServicesRaw = [
    (
      id: 'sub-wash-only',
      categoryId: 'cat-clothes',
      name: {'ar': 'غسيل فقط', 'en': 'Wash only'},
      description: {'ar': 'غسيل وتجفيف بدون كي', 'en': 'Wash & dry, no iron'},
    ),
    (
      id: 'sub-wash-iron',
      categoryId: 'cat-clothes',
      name: {'ar': 'غسيل وكي', 'en': 'Wash & Iron'},
      description: {'ar': 'غسيل وتجفيف وكي كامل', 'en': 'Wash, dry & full iron'},
    ),
    (
      id: 'sub-iron-only',
      categoryId: 'cat-clothes',
      name: {'ar': 'كي فقط', 'en': 'Iron only'},
      description: {'ar': 'كي القطع النظيفة', 'en': 'Iron clean items'},
    ),
    (
      id: 'sub-full-service',
      categoryId: 'cat-clothes',
      name: {'ar': 'خدمة كاملة', 'en': 'Full Service'},
      description: {
        'ar': 'غسيل وكي وتعليق وتغليف',
        'en': 'Wash, iron, hang & wrap',
      },
    ),
    (
      id: 'sub-textiles-wash',
      categoryId: 'cat-textiles',
      name: {'ar': 'غسيل وكي', 'en': 'Wash & Iron'},
      description: {'ar': 'مفارش وأغطية ووسائد', 'en': 'Sheets, covers & pillows'},
    ),
    (
      id: 'sub-carpet-deep',
      categoryId: 'cat-carpets',
      name: {'ar': 'تنظيف عميق وغسيل', 'en': 'Deep cleaning & wash'},
      description: {'ar': 'إزالة الأتربة والبقع', 'en': 'Dust & stain removal'},
    ),
    (
      id: 'sub-curtain-full',
      categoryId: 'cat-curtains',
      name: {'ar': 'فك، غسيل، وكي', 'en': 'Take-down, wash & iron'},
      description: {
        'ar': 'فك من المنزل وإعادة تركيب',
        'en': 'Removed & re-hung at home',
      },
    ),
  ];

  static final _tiersRaw = [
    (
      id: 'tier-standard',
      name: {'ar': 'عادي', 'en': 'Standard'},
      deliveryHours: 48,
      isVip: false,
      perks: [
        {'ar': 'استلام وتسليم مجاني', 'en': 'Free pickup & delivery'},
        {'ar': 'مواعيد يومية متاحة', 'en': 'Daily slots available'},
      ],
    ),
    (
      id: 'tier-vip',
      name: {'ar': 'VIP', 'en': 'VIP'},
      deliveryHours: 24,
      isVip: true,
      perks: [
        {'ar': 'أولوية في المعالجة', 'en': 'Priority processing'},
        {'ar': 'مواعيد تسليم موسعة', 'en': 'Extended delivery slots'},
      ],
    ),
  ];

  @override
  Future<List<ServiceCategory>> getCategories() async {
    await _db.delay();
    return _categoriesRaw.map(_category).toList();
  }

  @override
  Future<List<SubService>> getSubServices(String categoryId) async {
    await _db.delay();
    return _subServicesRaw
        .where((s) => s.categoryId == categoryId)
        .map(_subService)
        .toList();
  }

  @override
  Future<List<ServiceTier>> getTiers() async {
    await _db.delay();
    return _tiersRaw.map(_tier).toList();
  }

  @override
  Future<List<TimeSlot>> getPickupSlots(DateTime day, String tierId) async {
    await _db.delay();
    return _generateSlots(day);
  }

  @override
  Future<List<TimeSlot>> getDeliverySlots(
    DateTime day,
    String tierId,
    DateTime notBefore,
  ) async {
    await _db.delay();
    return _generateSlots(day, notBefore: notBefore);
  }

  // ---- Lookups used by OrderMockDataSource (outside the API contract) -----

  ServiceCategory categoryById(String id) =>
      _category(_categoriesRaw.firstWhere((c) => c.id == id));

  SubService subServiceById(String id) =>
      _subService(_subServicesRaw.firstWhere((s) => s.id == id));

  ServiceTier tierById(String id) => _tier(_tiersRaw.firstWhere((t) => t.id == id));

  /// Slot ids encode their day + window index, so a booked slot can be
  /// resolved again without a slots table.
  TimeSlot slotById(String id) {
    final parts = id.split('-');
    final index = int.parse(parts.removeLast());
    final day = DateTime.parse(parts.join('-'));
    final (startHour, endHour) = _windows[index];
    return TimeSlot(
      id: id,
      start: DateTime(day.year, day.month, day.day, startHour),
      end: DateTime(day.year, day.month, day.day, endHour),
      isFull: _isFull(day, index),
    );
  }

  List<TimeSlot> _generateSlots(DateTime day, {DateTime? notBefore}) {
    final now = DateTime.now();
    final slots = <TimeSlot>[];
    for (var i = 0; i < _windows.length; i++) {
      final (startHour, endHour) = _windows[i];
      final start = DateTime(day.year, day.month, day.day, startHour);
      final end = DateTime(day.year, day.month, day.day, endHour);
      if (start.isBefore(now)) continue;
      if (notBefore != null && start.isBefore(notBefore)) continue;
      slots.add(TimeSlot(id: _slotId(day, i), start: start, end: end, isFull: _isFull(day, i)));
    }
    return slots;
  }

  String _slotId(DateTime day, int index) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}-$index';

  /// Deterministic "full" slot so the picker UI can be exercised without
  /// real capacity data.
  bool _isFull(DateTime day, int index) => index == 2 && day.day.isEven;

  ServiceCategory _category(
    ({String id, Map<String, String> name, Map<String, String> description}) c,
  ) => ServiceCategory(
    id: c.id,
    name: _db.tr(c.name),
    description: _db.tr(c.description),
  );

  SubService _subService(
    ({
      String id,
      String categoryId,
      Map<String, String> name,
      Map<String, String> description,
    })
    s,
  ) => SubService(
    id: s.id,
    categoryId: s.categoryId,
    name: _db.tr(s.name),
    description: _db.tr(s.description),
  );

  ServiceTier _tier(
    ({
      String id,
      Map<String, String> name,
      int deliveryHours,
      bool isVip,
      List<Map<String, String>> perks,
    })
    t,
  ) => ServiceTier(
    id: t.id,
    name: _db.tr(t.name),
    deliveryHours: t.deliveryHours,
    isVip: t.isVip,
    perks: t.perks.map(_db.tr).toList(),
  );
}
