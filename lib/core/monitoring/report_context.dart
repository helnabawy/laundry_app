import 'dart:convert';

/// Who is signed in, as attached to crash reports.
///
/// Crash reports carry the full profile so support can find the account;
/// analytics only ever gets [id] and [role] (no phone or name — Google
/// Analytics forbids personal data).
class UserContext {
  const UserContext({
    required this.id,
    required this.role,
    this.phone,
    this.name,
    this.profileCompleted,
  });

  final String id;
  final String role;
  final String? phone;
  final String? name;
  final bool? profileCompleted;

  Map<String, Object?> toKeys() => {
    'user_id': id,
    'user_role': role,
    'user_phone': phone,
    'user_name': name,
    'profile_completed': profileCompleted,
  };

  static const keys = [
    'user_id',
    'user_role',
    'user_phone',
    'user_name',
    'profile_completed',
  ];
}

/// The signed-in customer's saved addresses on crash reports: a count, then
/// one key per address holding all its fields as JSON (building, apartment,
/// alternate phone and GPS pin included, so support can reproduce
/// address-specific bugs). Capped at [max] keys; Crashlytics allows 64 in all.
abstract final class UserAddressKeys {
  static const count = 'user_address_count';
  static const max = 5;

  static String at(int index) => 'user_address_${index + 1}';

  /// Keys for [addresses] (each already a field map); unused slots cleared.
  static Map<String, Object?> of(List<Map<String, Object?>> addresses) => {
    count: addresses.length,
    for (var i = 0; i < max; i++)
      at(i): i < addresses.length ? describe(addresses[i]) : null,
  };

  /// Every address key, cleared.
  static Map<String, Object?> get cleared => {
    count: null,
    for (var i = 0; i < max; i++) at(i): null,
  };
}

/// The HTTP exchange behind an error, already redacted and truncated.
class RequestContext {
  const RequestContext({
    required this.method,
    required this.url,
    this.query,
    this.headers,
    this.body,
    this.statusCode,
    this.responseBody,
    this.durationMs,
    this.requestId,
    this.errorType,
  });

  final String method;
  final String url;
  final String? query;
  final String? headers;
  final String? body;
  final int? statusCode;
  final String? responseBody;
  final int? durationMs;
  final String? requestId;
  final String? errorType;

  /// One line for the breadcrumb trail: `GET /orders → 500 (120ms)`.
  String get summary =>
      '$method $url → ${statusCode ?? errorType ?? '?'}'
      '${durationMs == null ? '' : ' (${durationMs}ms)'}';

  Map<String, Object?> toKeys() => {
    'req_method': method,
    'req_url': url,
    'req_query': query,
    'req_headers': headers,
    'req_body': body,
    'req_duration_ms': durationMs,
    'req_id': requestId,
    'req_error_type': errorType,
    'res_status': statusCode,
    'res_body': responseBody,
  };

  static const keys = [
    'req_method',
    'req_url',
    'req_query',
    'req_headers',
    'req_body',
    'req_duration_ms',
    'req_id',
    'req_error_type',
    'res_status',
    'res_body',
  ];
}

/// Crash-report key values are capped at 1 KB.
const maxReportValueLength = 1000;

const _redacted = '<redacted>';

const _secretHeaders = {'authorization', 'cookie', 'set-cookie'};

/// Field names whose values never leave the device: one-time codes, tokens,
/// passwords, card data.
bool isSecretField(String name) {
  final key = name.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
  return const {
        'otp',
        'code',
        'pin',
        'cvv',
        'cardnumber',
        'secret',
      }.contains(key) ||
      key.contains('token') ||
      key.contains('password');
}

/// Headers with credentials masked.
Map<String, Object?> redactHeaders(Map<String, Object?> headers) => {
  for (final MapEntry(:key, :value) in headers.entries)
    key: _secretHeaders.contains(key.toLowerCase()) ? _redacted : value,
};

/// [data] (decoded JSON, a map of query params…) with secret fields masked.
Object? redact(Object? data) => switch (data) {
  final Map<Object?, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries)
      '$key': isSecretField('$key') ? _redacted : redact(value),
  },
  final List<Object?> list => [for (final item in list) redact(item)],
  _ => data,
};

/// [data] redacted and rendered as compact text, cut to fit a report value.
String? describe(Object? data, {int max = maxReportValueLength}) {
  if (data == null) return null;
  final redactedData = redact(data);
  String text;
  try {
    text = redactedData is String ? redactedData : jsonEncode(redactedData);
  } on Object {
    text = redactedData.toString();
  }
  return truncate(text, max);
}

String truncate(String text, [int max = maxReportValueLength]) =>
    text.length <= max ? text : '${text.substring(0, max - 1)}…';
