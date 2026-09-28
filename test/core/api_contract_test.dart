import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/features/addresses/data/models/address_model.dart';
import 'package:laundry_app/features/auth/data/models/app_user_model.dart';
import 'package:laundry_app/features/auth/domain/entities/app_user.dart';
import 'package:laundry_app/features/notifications/data/models/app_notification_model.dart';
import 'package:laundry_app/features/orders/data/models/driver_task_model.dart';
import 'package:laundry_app/features/orders/data/models/laundry_order_model.dart';
import 'package:laundry_app/features/orders/data/models/product_model.dart';
import 'package:laundry_app/features/orders/data/models/service_category_model.dart';
import 'package:laundry_app/features/orders/data/models/service_tier_model.dart';
import 'package:laundry_app/features/orders/data/models/sub_service_model.dart';
import 'package:laundry_app/features/orders/data/models/time_slot_model.dart';
import 'package:laundry_app/features/orders/domain/entities/order_status.dart';
import 'package:laundry_app/features/support/data/models/faq_entry_model.dart';

/// The real backend's payloads (captured from laundry_admin's REST API into
/// test/fixtures/api) must parse with the app's models. The mock data source
/// builds entities directly, so without this nothing exercises `fromJson`
/// against what the server actually sends.
///
/// Refresh the fixtures after an API change by re-capturing them from a
/// running `laundry_admin` dev server.
void main() {
  dynamic fixture(String name) =>
      jsonDecode(File('test/fixtures/api/$name.json').readAsStringSync());

  List<Map<String, dynamic>> list(String name) =>
      (fixture(name) as List<dynamic>).cast<Map<String, dynamic>>();

  group('orders', () {
    test('a shop order has no lines and parses to an empty list', () {
      final order = LaundryOrderModel.fromJson(
        fixture('shop_order') as Map<String, dynamic>,
      );
      expect(order.lines, isEmpty);
      expect(order.invoice, isNotNull);
      expect(order.invoice!.items, isNotEmpty);
      expect(order.status, OrderStatus.pending);
    });

    test('a delivered quick order carries lines, invoice and conditions', () {
      final order = LaundryOrderModel.fromJson(
        fixture('wizard_order_delivered_ar') as Map<String, dynamic>,
      );
      expect(order.lines, isNotEmpty);
      expect(order.status, OrderStatus.delivered);
      expect(order.invoice!.paid, isTrue);
      expect(order.invoice!.hasConditions, isTrue);
      expect(order.timeline.first.status, OrderStatus.pending);
    });

    test('every captured order parses, shop and quick alike', () {
      final orders = list('orders').map(LaundryOrderModel.fromJson).toList();
      expect(orders.where((o) => o.lines.isEmpty), isNotEmpty);
      expect(orders.where((o) => o.lines.isNotEmpty), isNotEmpty);
    });

    test('driver tasks parse', () {
      final tasks = [
        ...list('driver_tasks_today'),
        ...list('driver_tasks_completed'),
      ].map(DriverTaskModel.fromJson).toList();
      expect(tasks, isNotEmpty);
    });
  });

  group('catalogue', () {
    test('categories, sub-services, products, tiers and slots parse', () {
      expect(
        list('categories_ar').map(ServiceCategoryModel.fromJson),
        isNotEmpty,
      );
      expect(list('sub_services').map(SubServiceModel.fromJson), isNotEmpty);
      expect(list('products').map(ProductModel.fromJson), isNotEmpty);
      final tiers = list('tiers_ar').map(ServiceTierModel.fromJson).toList();
      expect(tiers.where((t) => t.isVip), isNotEmpty);
      expect(list('timeslots').map(TimeSlotModel.fromJson), isNotEmpty);
    });
  });

  group('account', () {
    test('verify-otp, me and addresses parse', () {
      final verify = fixture('verify_otp_customer') as Map<String, dynamic>;
      expect(verify['token'], isA<String>());
      final user = AppUserModel.fromJson(
        verify['user'] as Map<String, dynamic>,
      );
      expect(user.role, UserRole.customer);
      AppUserModel.fromJson(fixture('me') as Map<String, dynamic>);
      expect(list('addresses').map(AddressModel.fromJson), isNotEmpty);
    });

    test('notifications and support FAQs parse', () {
      list('notifications').map(AppNotificationModel.fromJson).toList();
      expect(list('faqs_ar').map(FaqEntryModel.fromJson), isNotEmpty);
    });
  });
}
