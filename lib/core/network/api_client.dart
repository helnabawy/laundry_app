import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Thin wrapper over [Dio] that returns decoded JSON and translates
/// [DioException]s into data-layer exceptions.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post<dynamic>(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _send(() => _dio.delete<dynamic>(path, data: data));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Exception _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      default:
        break;
    }
    final status = e.response?.statusCode;
    final message = _extractMessage(e.response?.data);
    if (status == 401) return UnauthorizedException(message);
    return ServerException(statusCode: status, message: message);
  }

  /// ASP.NET Core returns RFC 7807 ProblemDetails: `{title, detail, errors}`.
  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final detail = data['detail'] ?? data['message'] ?? data['title'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }
}
