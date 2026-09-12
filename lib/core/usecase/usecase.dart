import '../result/result.dart';

/// A single application operation. Presentation depends on use cases, never on
/// repositories or data sources directly.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

final class NoParams {
  const NoParams();
}
