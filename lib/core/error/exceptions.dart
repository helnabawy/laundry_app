/// Exceptions thrown by the data layer. Repositories convert them into
/// [Failure]s (see `guard`) so they never reach the presentation layer.
library;

class ServerException implements Exception {
  const ServerException({this.statusCode, this.message});

  final int? statusCode;
  final String? message;

  @override
  String toString() => 'ServerException($statusCode, $message)';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message]);

  final String? message;
}

class NetworkException implements Exception {
  const NetworkException();
}

class CacheException implements Exception {
  const CacheException([this.message]);

  final String? message;
}
