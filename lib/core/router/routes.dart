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
  static const driverHome = '/driver';
}
