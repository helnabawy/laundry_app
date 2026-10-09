import '../monitoring/app_reporter.dart';
import '../result/result.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Where [guard] reports errors it didn't expect; set by the composition
/// root (`configureDependencies`).
AppReporter guardReporter = const NoopReporter();

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
    // A bug (parsing, a null), not a failure the API or network reported.
    guardReporter.recordError(e, stack, reason: 'unexpected error in guard');
    return Err(UnexpectedFailure(e.toString()));
  }
}
