import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/session_usecases.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

/// Restoring the session on launch; [failure] is set if that failed
/// (e.g. offline) so the splash can offer a retry.
final class SessionUnknown extends SessionState {
  const SessionUnknown({this.failure});

  final Failure? failure;

  @override
  List<Object?> get props => [failure];
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated({this.expired = false});

  final bool expired;

  @override
  List<Object?> get props => [expired];
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// App-wide auth state; drives the router's role-based redirects.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required RestoreSession restoreSession, required Logout logout})
    : _restoreSession = restoreSession,
      _logout = logout,
      super(const SessionUnknown());

  final RestoreSession _restoreSession;
  final Logout _logout;

  Future<void> restore() async {
    emit(const SessionUnknown());
    final result = await _restoreSession();
    emit(
      result.fold(
        onErr: (failure) => SessionUnknown(failure: failure),
        onOk: (user) => user == null
            ? const SessionUnauthenticated()
            : SessionAuthenticated(user),
      ),
    );
  }

  void signedIn(AppUser user) => emit(SessionAuthenticated(user));

  void userUpdated(AppUser user) => emit(SessionAuthenticated(user));

  Future<void> logout() async {
    await _logout();
    emit(const SessionUnauthenticated());
  }

  /// Called when the API rejects the JWT (401).
  Future<void> expire() async {
    if (state is! SessionAuthenticated) return;
    await _logout();
    emit(const SessionUnauthenticated(expired: true));
  }
}
