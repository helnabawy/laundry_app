import 'package:url_launcher/url_launcher.dart';

import '../../../addresses/domain/entities/address.dart';

Future<void> launchTel(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

Future<void> launchSms(String phone) => launchUrl(Uri(scheme: 'sms', path: phone));

Future<bool> launchWhatsApp(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return launchUrl(Uri.https('wa.me', '/$digits'), mode: LaunchMode.externalApplication);
}

Future<void> launchMaps(Address address) {
  final query = address.hasCoordinates
      ? '${address.latitude},${address.longitude}'
      : '${address.area}, ${address.city}';
  return launchUrl(Uri.https('maps.google.com', '/', {'q': query}), mode: LaunchMode.externalApplication);
}
