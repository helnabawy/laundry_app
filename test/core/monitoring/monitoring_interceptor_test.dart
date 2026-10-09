import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/core/monitoring/app_reporter.dart';
import 'package:laundry_app/core/monitoring/monitoring_interceptor.dart';

DioException _error({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  Object? data,
  Object? responseData,
  Map<String, dynamic>? query,
}) {
  final options = RequestOptions(
    baseUrl: 'https://api.example.com',
    path: '/api/mobile/auth/verify',
    method: 'POST',
    data: data,
    queryParameters: query,
    headers: {'Authorization': 'Bearer secret-jwt', 'Accept-Language': 'ar'},
  );
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: responseData,
            headers: Headers.fromMap({
              'x-request-id': ['req-42'],
            }),
          ),
  );
}

void main() {
  group('shouldReport', () {
    test('server errors and unexpected client errors are reported', () {
      expect(MonitoringInterceptor.shouldReport(_error(status: 500)), isTrue);
      expect(MonitoringInterceptor.shouldReport(_error(status: 404)), isTrue);
      expect(
        MonitoringInterceptor.shouldReport(
          _error(type: DioExceptionType.unknown),
        ),
        isTrue,
      );
    });

    test('handled answers and connectivity stay breadcrumbs', () {
      for (final status in [400, 401, 409, 422, 429]) {
        expect(
          MonitoringInterceptor.shouldReport(_error(status: status)),
          isFalse,
          reason: '$status',
        );
      }
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.cancel,
      ]) {
        expect(
          MonitoringInterceptor.shouldReport(_error(type: type)),
          isFalse,
          reason: '$type',
        );
      }
    });
  });

  group('requestContextOf', () {
    test('masks the token, the code and credentials', () {
      final request = MonitoringInterceptor.requestContextOf(
        _error(
          status: 500,
          data: {'phone': '+971501234567', 'code': '9876'},
          responseData: {'token': 'jwt', 'detail': 'boom'},
        ),
      );

      expect(request.method, 'POST');
      expect(request.url, 'https://api.example.com/api/mobile/auth/verify');
      expect(request.statusCode, 500);
      expect(request.requestId, 'req-42');
      expect(request.headers, contains('<redacted>'));
      expect(request.headers, isNot(contains('secret-jwt')));
      expect(request.headers, contains('Accept-Language'));
      expect(request.body, contains('+971501234567'));
      expect(request.body, isNot(contains('9876')));
      expect(request.responseBody, contains('boom'));
      expect(request.responseBody, isNot(contains('jwt')));
    });

    test('long bodies are cut to fit a report value', () {
      final request = MonitoringInterceptor.requestContextOf(
        _error(status: 500, responseData: 'x' * 5000),
      );
      expect(request.responseBody!.length, maxReportValueLength);
    });

    test('query parameters are kept apart from the url', () {
      final request = MonitoringInterceptor.requestContextOf(
        _error(status: 500, query: {'day': '2026-01-01'}),
      );
      expect(request.url, isNot(contains('?')));
      expect(request.query, contains('2026-01-01'));
    });
  });
}
