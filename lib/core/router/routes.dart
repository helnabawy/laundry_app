/// Route paths shared across features.
abstract final class Routes {
  static const splash = '/splash';
  static const language = '/language';

  static const login = '/login';
  static const otpSegment = 'otp';
  static const otp = '$login/$otpSegment';

  static const completeProfile = '/complete-profile';
  static const addresses = '/addresses';
  static const addAddress = '$addresses/new';
  static String editAddress(String id) => '$addresses/$id/edit';

  static const customerHome = '/customer';

  /// Which laundry to order from — required before the customer's Home.
  static const chooseLaundry = '/laundry';
  static const orderNew = '/orders/new';

  /// The shop flow: flat product grid + cart, additive alongside the order
  /// wizard reachable via [orderNew].
  static const shop = '/shop';
  static const checkout = '/checkout';
  static String orderDetail(String id) => '/orders/$id';
  static String orderInvoice(String id) => '/orders/$id/invoice';
  static String orderInvoiceHelp(String id) => '/orders/$id/invoice/help';
  static String orderAssistant(String id) =>
      '/orders/$id/invoice/help/assistant';

  /// Shared by both roles, so it sits outside either role's area.
  static const notifications = '/notifications';

  static const driverHome = '/driver';
  static String driverPickup(String orderId) => '/driver/pickup/$orderId';
  static String driverDelivery(String orderId) => '/driver/delivery/$orderId';
}
