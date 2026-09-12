/// `+971501234567` → `+971 50 123 4567`. Falls back to the raw input for
/// anything else (the MVP is UAE-only).
String formatUaePhone(String e164) {
  if (!e164.startsWith('+971')) return e164;
  final rest = e164.substring(4);
  if (rest.length != 9) return e164;
  return '+971 ${rest.substring(0, 2)} ${rest.substring(2, 5)} ${rest.substring(5, 9)}';
}
