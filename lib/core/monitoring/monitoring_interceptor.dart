import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_reporter.dart';

/// Leaves a breadcrumb for every API call and reports the failures worth
/// looking at, with the request and response attached (credentials, codes
/// and tokens masked).
///
/// Connectivity problems (offline, timeouts) and the 4xx answers the app
/// handles (validation, auth, conflicts) stay breadcrumbs only.
class MonitoringInterceptor extends Interceptor {
  MonitoringInterceptor(this._reporter);

  final AppReporter _reporter;

  static const _startedAt = 'monitor_started_at';

  /// Client errors the app expects and shows to the user.
  static const _handled4xx = {400, 401, 409, 422, 429};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAt] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final o = response.requestOptions;
    _reporter.log(
      'http ${o.method} ${o.path} → ${response.statusCode}'
      ' (${_elapsed(o)}ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = requestContextOf(err);
    if (shouldReport(err)) {
      _reporter.recordError(
        err,
        err.stackTrace,
        reason: 'API ${request.summary}',
        request: request,
      );
    } else {
      _reporter.log('http ${request.summary}');
    }
    handler.next(err);
  }

  @visibleForTesting
  static bool shouldReport(DioException err) => switch (err.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.cancel => false,
    DioExceptionType.badResponse => switch (err.response?.statusCode) {
      null => true,
      final status => status >= 500 || !_handled4xx.contains(status),
    },
    DioExceptionType.badCertificate || DioExceptionType.unknown => true,
  };

  @visibleForTesting
  static RequestContext requestContextOf(DioException err) {
    final o = err.requestOptions;
    final response = err.response;
    final uri = o.uri;
    return RequestContext(
      method: o.method,
      url: '${uri.origin}${uri.path}',
      query: o.queryParameters.isEmpty ? null : describe(o.queryParameters),
      headers: describe(redactHeaders(o.headers)),
      body: _describeBody(o.data),
      statusCode: response?.statusCode,
      responseBody: _describeBody(response?.data),
      durationMs: _elapsed(o),
      requestId: _requestId(response?.headers),
      errorType: err.type.name,
    );
  }

  static int? _elapsed(RequestOptions o) => switch (o.extra[_startedAt]) {
    final int start => DateTime.now().millisecondsSinceEpoch - start,
    _ => null,
  };

  static String? _describeBody(Object? data) => switch (data) {
    null => null,
    FormData(:final fields, :final files) =>
      'multipart: ${describe({for (final f in fields) f.key: f.value})}'
          ', ${files.length} file(s)',
    final String text => describe(_tryDecode(text)),
    final List<int> bytes => '<${bytes.length} bytes>',
    _ => describe(data),
  };

  static Object? _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  static String? _requestId(Headers? headers) {
    if (headers == null) return null;
    for (final name in const [
      'x-request-id',
      'x-correlation-id',
      'traceparent',
    ]) {
      if (headers.value(name) case final id?) return id;
    }
    return null;
  }
}
