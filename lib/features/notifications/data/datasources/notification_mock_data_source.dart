import '../../../../core/mock/mock_database.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../../orders/domain/entities/order_timeline_event.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_remote_data_source.dart';

/// Derives the inbox from the shared `orders` table: every status change the
/// backend would push a notification for becomes one entry. Read state is
/// kept per user, the way the API keeps it.
class NotificationMockDataSource implements NotificationRemoteDataSource {
  NotificationMockDataSource(this._db);

  static const _ordersTable = 'orders';
  static const _readsTable = 'notification_reads';

  final MockDatabase _db;

  @override
  Future<List<AppNotification>> getNotifications() async {
    await _db.delay();
    final userId = _db.requireUserId();
    final read = _readIds(userId);
    final notifications = <AppNotification>[];

    for (final row in _db.table(_ordersTable)) {
      final isCustomer = row['userId'] == userId;
      final isDriver = row['driverId'] == userId;
      if (!isCustomer && !isDriver) continue;

      final timeline = row['timeline'] as List<OrderTimelineEvent>;
      final pickupFailed = timeline.any(
        (e) => e.status == OrderStatus.pickupFailed,
      );
      for (final event in timeline) {
        final kind = isCustomer
            ? _customerKind(event.status, pickupFailed: pickupFailed)
            : _driverKind(event.status);
        if (kind == null) continue;
        final id =
            '${row['id']}:${event.status.name}:'
            '${event.at.millisecondsSinceEpoch}';
        notifications.add(
          AppNotification(
            id: id,
            kind: kind,
            orderId: row['id'] as String,
            orderNumber: row['number'] as int,
            sentAt: event.at,
            read: read.contains(id),
          ),
        );
      }
    }
    return notifications..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  @override
  Future<void> markAllRead() async {
    final userId = _db.requireUserId();
    final ids = (await getNotifications()).map((n) => n.id);
    _readIds(userId).addAll(ids);
  }

  Set<String> _readIds(String userId) {
    final rows = _db.table(_readsTable);
    final row = rows.firstWhere(
      (r) => r['userId'] == userId,
      orElse: () {
        final created = {'userId': userId, 'ids': <String>{}};
        rows.add(created);
        return created;
      },
    );
    return row['ids'] as Set<String>;
  }

  /// `pending` and `atFacility` are too quick or too internal to notify; a
  /// cancellation that follows a failed pickup was already announced by it.
  NotificationKind? _customerKind(
    OrderStatus status, {
    required bool pickupFailed,
  }) => switch (status) {
    OrderStatus.driverAssigned => NotificationKind.driverAssigned,
    OrderStatus.pickedUp => NotificationKind.pickedUp,
    OrderStatus.awaitingPayment => NotificationKind.invoiceReady,
    OrderStatus.processing => NotificationKind.processing,
    OrderStatus.outForDelivery => NotificationKind.outForDelivery,
    OrderStatus.delivered => NotificationKind.delivered,
    OrderStatus.pickupFailed => NotificationKind.pickupFailed,
    OrderStatus.deliveryFailed => NotificationKind.deliveryFailed,
    OrderStatus.cancelled when !pickupFailed => NotificationKind.cancelled,
    _ => null,
  };

  /// The driver hears about new work; what they did themselves isn't news.
  NotificationKind? _driverKind(OrderStatus status) => switch (status) {
    OrderStatus.driverAssigned => NotificationKind.newPickup,
    OrderStatus.outForDelivery => NotificationKind.newDelivery,
    _ => null,
  };
}
