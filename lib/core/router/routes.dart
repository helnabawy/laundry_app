/// Route paths shared across features.
abstract final class Routes {
  static const splash = '/splash';
  static const language = '/language';

  static const login = '/login';
  static const otpSegment = 'otp';
  static const otp = '$login/$otpSegment';

  static const completeProfile = '/complete-profile';
  static const addAddress = '/addresses/new';

  static const customerHome = '/customer';
  static const orderNew = '/orders/new';
  static String orderDetail(String id) => '/orders/$id';
  static String orderInvoice(String id) => '/orders/$id/invoice';

  static const driverHome = '/driver';
  static String driverPickup(String orderId) => '/driver/pickup/$orderId';
  static String driverDelivery(String orderId) => '/driver/delivery/$orderId';
}
