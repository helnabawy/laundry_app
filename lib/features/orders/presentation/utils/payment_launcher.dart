import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/datasources/order_mock_data_source.dart';
import '../../domain/entities/payment_info.dart';
import '../widgets/mock_gateway_sheet.dart';

/// Sends the customer to a payment's checkout. The server, not the app,
/// learns the outcome — callers poll the payment afterwards.
abstract interface class PaymentLauncher {
  /// Whether the customer pays outside the app (and so must come back).
  bool get leavesApp;

  /// Opens [payment]'s checkout. Resolves false when it couldn't be opened.
  Future<bool> open(BuildContext context, PaymentInfo payment);
}

/// The provider's hosted page, in an in-app browser tab
/// (SFSafariViewController / Custom Tabs) so the app stays one swipe away.
class BrowserPaymentLauncher implements PaymentLauncher {
  const BrowserPaymentLauncher();

  @override
  bool get leavesApp => true;

  @override
  Future<bool> open(BuildContext context, PaymentInfo payment) async {
    final url = payment.checkoutUrl;
    if (url == null) return false;
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } on Object {
      return false;
    }
  }
}

/// With the mock backend there is no hosted page: an in-app sheet plays the
/// provider and reports the verdict straight to the mock data source.
class MockPaymentLauncher implements PaymentLauncher {
  const MockPaymentLauncher(this._gateway);

  final OrderMockDataSource _gateway;

  @override
  bool get leavesApp => false;

  @override
  Future<bool> open(BuildContext context, PaymentInfo payment) async {
    final succeeded = await showMockGatewaySheet(context, payment);
    if (succeeded == null) return true;
    await _gateway.completeCheckout(payment.id, succeeded: succeeded);
    return true;
  }
}
