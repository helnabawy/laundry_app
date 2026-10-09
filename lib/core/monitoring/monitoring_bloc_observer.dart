import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_reporter.dart';

/// Reports errors thrown inside cubits and leaves a breadcrumb for each
/// state change — by type only: states can hold personal data and long
/// lists, which don't belong in a crash report.
class MonitoringBlocObserver extends BlocObserver {
  const MonitoringBlocObserver(this._reporter);

  final AppReporter _reporter;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _reporter.log('open ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final from = change.currentState.runtimeType;
    final to = change.nextState.runtimeType;
    // Same-type updates (a countdown tick, a field edit) are too chatty.
    if (from == to) return;
    _reporter.log('${bloc.runtimeType}: $from → $to');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _reporter.recordError(
      error,
      stackTrace,
      reason: 'in ${bloc.runtimeType}',
      extra: {
        'bloc': '${bloc.runtimeType}',
        'state': '${bloc.state.runtimeType}',
      },
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    _reporter.log('close ${bloc.runtimeType}');
    super.onClose(bloc);
  }
}
