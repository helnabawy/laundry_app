import 'package:flutter/foundation.dart';

import '../result/result.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Runs a data-layer call and converts thrown exceptions into [Failure]s.
/// Every repository method goes through this, so the domain only ever sees
/// [Result]s.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on UnauthorizedException catch (e) {
    return Err(UnauthorizedFailure(e.message));
  } on ServerException catch (e) {
    return Err(ServerFailure(statusCode: e.statusCode, message: e.message));
  } on NetworkException {
    return const Err(NetworkFailure());
  } on CacheException catch (e) {
    return Err(CacheFailure(e.message));
  } catch (e, stack) {
    debugPrint('Unexpected error: $e\n$stack');
    return Err(UnexpectedFailure(e.toString()));
  }
}
