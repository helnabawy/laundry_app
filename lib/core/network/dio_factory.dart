import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

/// Builds the [Dio] instance used by [ApiClient]:
/// - attaches the JWT, the UI language and the chosen laundry
///   (`X-Vendor-Id`) to every request;
/// - reports 401s so the app can end the session.
Dio createDio({
  required String baseUrl,
  required TokenStorage tokenStorage,
  required String Function() languageCode,
  required void Function() onUnauthorized,
  String? Function()? laundryId,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept-Language'] = languageCode();
        if (laundryId?.call() case final id?) {
          options.headers['X-Vendor-Id'] = id;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) onUnauthorized();
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (line) => debugPrint('$line'),
      ),
    );
  }
  return dio;
}
