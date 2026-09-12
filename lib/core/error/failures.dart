import 'package:equatable/equatable.dart';

/// A domain-level error. Presentation maps each type to a localized message
/// (see `FailureMessage`).
sealed class Failure extends Equatable {
  const Failure([this.message]);

  /// Optional human-readable message coming from the server.
  final String? message;

  @override
  List<Object?> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, String? message}) : super(message);

  final int? statusCode;

  @override
  List<Object?> get props => [statusCode, message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message]);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}

/// Client-side validation errors raised by use cases before hitting the API.
enum InputError { invalidPhone, invalidOtp, requiredField }

final class InputFailure extends Failure {
  const InputFailure(this.error);

  final InputError error;

  @override
  List<Object?> get props => [error];
}
