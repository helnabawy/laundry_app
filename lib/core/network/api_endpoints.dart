/// REST contract with the ASP.NET Core backend.
///
/// The first group comes straight from the Phase 1 plan; the rest are the
/// proposed endpoints the app needs for Phases 2–5 and should be agreed with
/// the backend before implementation there.
abstract final class ApiEndpoints {
  // ---- Phase 1 (from the plan) -------------------------------------------
  static const requestOtp = '/api/auth/request-otp';
  static const verifyOtp = '/api/auth/verify-otp';
  static const lookupPhone = '/api/auth/lookup';
  static const serviceCategories = '/api/service-categories';
  static String subServices(String categoryId) =>
      '/api/service-categories/$categoryId/sub-services';
  static const products = '/api/products';
  static const serviceTiers = '/api/service-tiers';
  static const timeSlots = '/api/timeslots';
  static const orders = '/api/orders';
  static String order(String orderId) => '/api/orders/$orderId';

  // ---- Multi-laundry & push ---------------------------------------------------
  /// Active laundries the customer can order from (public).
  static const laundries = '/api/vendors';

  /// Registers / removes this install's push token (POST / DELETE).
  static const devices = '/api/me/devices';

  // ---- Proposed ------------------------------------------------------------
  static const me = '/api/me';
  static const profile = '/api/me/profile';
  static const addresses = '/api/me/addresses';
  static String address(String addressId) => '/api/me/addresses/$addressId';

  static String orderInvoice(String orderId) => '/api/orders/$orderId/invoice';
  static String invoicePayment(String invoiceId) =>
      '/api/invoices/$invoiceId/payment';
  static String orderPaymentMethod(String orderId) =>
      '/api/orders/$orderId/payment-method';
  static String orderRating(String orderId) => '/api/orders/$orderId/rating';

  static const supportInvoiceFaqs = '/api/support/faqs/invoice';
  static const supportAssistant = '/api/support/assistant';
  static const supportRequests = '/api/support/requests';

  static const notifications = '/api/me/notifications';
  static const notificationsReadAll = '/api/me/notifications/read-all';

  static const driverMe = '/api/driver/me';
  static const driverAvailability = '/api/driver/availability';
  static const driverTasks = '/api/driver/tasks';
  static String driverTask(String orderId) => '/api/driver/tasks/$orderId';
  static String driverTaskAction(String orderId, String action) =>
      '/api/driver/tasks/$orderId/$action';
}
