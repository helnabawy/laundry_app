/// A product analytics event. Names and parameters are defined here, in one
/// place, so dashboards don't drift from the code.
///
/// Names: snake_case, ≤ 40 chars. Parameter values: strings or numbers, and
/// never personal data (phone, name, address).
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.params = const {}]);

  final String name;
  final Map<String, Object> params;

  // Auth

  factory AnalyticsEvent.otpSent({required bool newAccount}) =>
      AnalyticsEvent('otp_requested', {'new_account': '$newAccount'});

  factory AnalyticsEvent.otpResent() => const AnalyticsEvent('otp_resent');

  /// `sign_up` for a new account, `login` otherwise (Firebase's recommended
  /// events).
  factory AnalyticsEvent.signedIn({required bool newAccount, String? role}) =>
      AnalyticsEvent(newAccount ? 'sign_up' : 'login', {
        'method': 'phone_otp',
        'role': ?role,
      });

  factory AnalyticsEvent.profileCompleted() =>
      const AnalyticsEvent('profile_completed');

  factory AnalyticsEvent.logout() => const AnalyticsEvent('logout');

  // Laundries

  factory AnalyticsEvent.laundrySelected(String laundryId) =>
      AnalyticsEvent('laundry_selected', {'laundry_id': laundryId});

  // Orders

  factory AnalyticsEvent.beginCheckout({
    required String flow,
    double? value,
    int? itemCount,
    bool reorder = false,
  }) => AnalyticsEvent('begin_checkout', {
    'flow': flow,
    'currency': 'AED',
    'value': ?value,
    'item_count': ?itemCount,
    'reorder': '$reorder',
  });

  /// An order was placed — Firebase's `purchase`, so revenue reports work.
  factory AnalyticsEvent.orderPlaced({
    required String orderId,
    required String flow,
    double? value,
    int? itemCount,
    String? paymentMethod,
    String? tier,
    bool reorder = false,
  }) => AnalyticsEvent('purchase', {
    'transaction_id': orderId,
    'flow': flow,
    'currency': 'AED',
    'value': ?value,
    'item_count': ?itemCount,
    'payment_type': ?paymentMethod,
    'tier': ?tier,
    'reorder': '$reorder',
  });

  factory AnalyticsEvent.orderFailed({
    required String flow,
    required String failure,
  }) => AnalyticsEvent('order_failed', {'flow': flow, 'failure': failure});

  factory AnalyticsEvent.reorderUndone({required String flow}) =>
      AnalyticsEvent('reorder_undone', {'flow': flow});

  factory AnalyticsEvent.paymentStatus({
    required String status,
    String? provider,
  }) => AnalyticsEvent('payment_status', {
    'status': status,
    'provider': ?provider,
  });

  factory AnalyticsEvent.paymentRetried() =>
      const AnalyticsEvent('payment_retried');

  // Driver

  factory AnalyticsEvent.driverTask({
    required String action,
    required bool success,
    String? reason,
  }) => AnalyticsEvent('driver_task', {
    'action': action,
    'success': '$success',
    'reason': ?reason,
  });

  @override
  String toString() => params.isEmpty ? name : '$name $params';
}
