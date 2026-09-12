/// REST contract with the ASP.NET Core backend.
///
/// The first group comes straight from the Phase 1 plan; the rest are the
/// proposed endpoints the app needs for Phases 2–5 and should be agreed with
/// the backend before implementation there.
abstract final class ApiEndpoints {
  // ---- Phase 1 (from the plan) -------------------------------------------
  static const requestOtp = '/api/auth/request-otp';
  static const verifyOtp = '/api/auth/verify-otp';
  static const serviceCategories = '/api/service-categories';
  static String subServices(String categoryId) =>
      '/api/service-categories/$categoryId/sub-services';
  static const serviceTiers = '/api/service-tiers';
  static const timeSlots = '/api/timeslots';
  static const orders = '/api/orders';
  static String order(String orderId) => '/api/orders/$orderId';

  // ---- Proposed ------------------------------------------------------------
  static const me = '/api/me';
  static const profile = '/api/me/profile';
  static const addresses = '/api/me/addresses';

  static String orderInvoice(String orderId) => '/api/orders/$orderId/invoice';
  static String invoicePayment(String invoiceId) =>
      '/api/invoices/$invoiceId/payment';

  static const driverMe = '/api/driver/me';
  static const driverAvailability = '/api/driver/availability';
  static const driverTasks = '/api/driver/tasks';
  static String driverTask(String orderId) => '/api/driver/tasks/$orderId';
  static String driverTaskAction(String orderId, String action) =>
      '/api/driver/tasks/$orderId/$action';
}
