import '../../../../core/mock/mock_database.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/sub_service.dart';
import '../../domain/entities/time_slot.dart';
import 'catalog_remote_data_source.dart';

/// Reference data for the order wizard (plan §1: 4 categories, 2 tiers) and
/// the shop flow's flat product catalog, plus deterministic slot generation.
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
      description: {
        'ar': 'غسيل، كي، خدمة كاملة',
        'en': 'Wash, iron, full service',
      },
    ),
    (
      id: 'cat-textiles',
      name: {'ar': 'مفروشات', 'en': 'Home Textiles'},
      description: {
        'ar': 'مفارش، أغطية، وسائد',
        'en': 'Sheets, covers, pillows',
      },
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
      description: {
        'ar': 'غسيل وتجفيف وكي كامل',
        'en': 'Wash, dry & full iron',
      },
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
      description: {
        'ar': 'مفارش وأغطية ووسائد',
        'en': 'Sheets, covers & pillows',
      },
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
      surchargeType: TierSurchargeType.none,
      surchargeValue: 0.0,
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
      // Shop flow's cart-level VIP surcharge (plan §1 "دعم VIP surcharge").
      surchargeType: TierSurchargeType.percentage,
      surchargeValue: 15.0,
    ),
  ];

  /// The shop flow's flat, bilingual product catalog — a product row IS the
  /// purchasable unit there (no sub-service step), priced in EGP.
  static final _productsRaw = [
    // ---- Clothes ------------------------------------------------------
    (
      id: 'prod-tshirt',
      categoryId: 'cat-clothes',
      name: {'ar': 'تي شيرت', 'en': 'T-shirt'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 2.0,
    ),
    (
      id: 'prod-shirt',
      categoryId: 'cat-clothes',
      name: {'ar': 'قميص', 'en': 'Shirt'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 10.0,
    ),
    (
      id: 'prod-trouser',
      categoryId: 'cat-clothes',
      name: {'ar': 'بنطلون', 'en': 'Trouser'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 15.0,
    ),
    (
      id: 'prod-jacket',
      categoryId: 'cat-clothes',
      name: {'ar': 'جاكيت', 'en': 'Jacket'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 25.0,
    ),
    (
      id: 'prod-dress',
      categoryId: 'cat-clothes',
      name: {'ar': 'فستان', 'en': 'Dress'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 30.0,
    ),
    (
      id: 'prod-suit',
      categoryId: 'cat-clothes',
      name: {'ar': 'بدلة', 'en': 'Suit'},
      description: {
        'ar': 'غسيل وكي، جاكيت وبنطلون',
        'en': 'Wash & iron, jacket & trouser',
      },
      unitPrice: 45.0,
    ),
    // ---- Home Textiles --------------------------------------------------
    (
      id: 'prod-bedsheet',
      categoryId: 'cat-textiles',
      name: {'ar': 'ملاءة سرير', 'en': 'Bedsheet'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 20.0,
    ),
    (
      id: 'prod-pillowcase',
      categoryId: 'cat-textiles',
      name: {'ar': 'كيس وسادة', 'en': 'Pillowcase'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 6.0,
    ),
    (
      id: 'prod-duvet-cover',
      categoryId: 'cat-textiles',
      name: {'ar': 'غطاء لحاف', 'en': 'Duvet cover'},
      description: {'ar': 'غسيل وكي', 'en': 'Wash & iron'},
      unitPrice: 35.0,
    ),
    (
      id: 'prod-towel',
      categoryId: 'cat-textiles',
      name: {'ar': 'منشفة', 'en': 'Towel'},
      description: {'ar': 'غسيل', 'en': 'Wash'},
      unitPrice: 8.0,
    ),
    // ---- Carpets ----------------------------------------------------------
    (
      id: 'prod-carpet-small',
      categoryId: 'cat-carpets',
      name: {'ar': 'سجادة صغيرة', 'en': 'Small carpet'},
      description: {'ar': 'تنظيف عميق وغسيل', 'en': 'Deep cleaning & wash'},
      unitPrice: 60.0,
    ),
    (
      id: 'prod-carpet-large',
      categoryId: 'cat-carpets',
      name: {'ar': 'سجادة كبيرة', 'en': 'Large carpet'},
      description: {'ar': 'تنظيف عميق وغسيل', 'en': 'Deep cleaning & wash'},
      unitPrice: 120.0,
    ),
    (
      id: 'prod-rug',
      categoryId: 'cat-carpets',
      name: {'ar': 'كليم', 'en': 'Rug'},
      description: {'ar': 'تنظيف عميق وغسيل', 'en': 'Deep cleaning & wash'},
      unitPrice: 40.0,
    ),
    // ---- Curtains -----------------------------------------------------
    (
      id: 'prod-curtain-panel',
      categoryId: 'cat-curtains',
      name: {'ar': 'ستارة (قطعة)', 'en': 'Curtain panel'},
      description: {'ar': 'فك، غسيل، وكي', 'en': 'Take-down, wash & iron'},
      unitPrice: 30.0,
    ),
    (
      id: 'prod-curtain-set',
      categoryId: 'cat-curtains',
      name: {'ar': 'طقم ستائر', 'en': 'Curtain set'},
      description: {'ar': 'فك، غسيل، وكي', 'en': 'Take-down, wash & iron'},
      unitPrice: 55.0,
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
  Future<List<Product>> getProducts() async {
    await _db.delay();
    return _productsRaw.map(_product).toList();
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

  Product productById(String id) => _product(
    _productsRaw.firstWhere(
      (p) => p.id == id,
      orElse: () => _db.notFound('Product not found'),
    ),
  );

  ServiceTier tierById(String id) =>
      _tier(_tiersRaw.firstWhere((t) => t.id == id));

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
      slots.add(
        TimeSlot(
          id: _slotId(day, i),
          start: start,
          end: end,
          isFull: _isFull(day, i),
        ),
      );
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

  Product _product(
    ({
      String id,
      String categoryId,
      Map<String, String> name,
      Map<String, String> description,
      double unitPrice,
    })
    p,
  ) => Product(
    id: p.id,
    categoryId: p.categoryId,
    name: _db.tr(p.name),
    description: _db.tr(p.description),
    unitPrice: p.unitPrice,
  );

  ServiceTier _tier(
    ({
      String id,
      Map<String, String> name,
      int deliveryHours,
      bool isVip,
      List<Map<String, String>> perks,
      TierSurchargeType surchargeType,
      double surchargeValue,
    })
    t,
  ) => ServiceTier(
    id: t.id,
    name: _db.tr(t.name),
    deliveryHours: t.deliveryHours,
    isVip: t.isVip,
    perks: t.perks.map(_db.tr).toList(),
    surchargeType: t.surchargeType,
    surchargeValue: t.surchargeValue,
  );
}
