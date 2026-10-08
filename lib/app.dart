import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/l10n/l10n.dart';
import 'core/locale/locale_cubit.dart';
import 'core/design/design.dart';
import 'core/theme/theme_cubit.dart';
import 'core/push/push_service.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<LocaleCubit>()),
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<SessionCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          // Arabic gets its own tracking and optical size; set before the
          // first frame of a locale is laid out.
          DesignTypography.script =
              (locale ?? const Locale(LocaleCubit.fallbackLanguageCode))
                  .languageCode;
          return MaterialApp.router(
            onGenerateTitle: (context) => context.l10n.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: context.watch<ThemeCubit>().state,
            locale: locale ?? const Locale(LocaleCubit.fallbackLanguageCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: sl<GoRouter>(),
            builder: (context, child) =>
                _SessionExpiryListener(child: _PushListener(child: child!)),
          );
        },
      ),
    );
  }
}

/// Tells the user why they were sent back to login after a 401.
class _SessionExpiryListener extends StatelessWidget {
  const _SessionExpiryListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (_, curr) => curr is SessionUnauthenticated && curr.expired,
      listener: (context, _) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(context.l10n.sessionExpired)));
      },
      child: child,
    );
  }
}

/// Opens the order a tapped push is about, and — on Android, where the
/// system shows nothing while the app is open — shows a push that arrives
/// in the foreground as a banner with a "View" action.
class _PushListener extends StatefulWidget {
  const _PushListener({required this.child});

  final Widget child;

  @override
  State<_PushListener> createState() => _PushListenerState();
}

class _PushListenerState extends State<_PushListener> {
  final _subscriptions = <StreamSubscription<Object?>>[];

  PushService get _push => sl<PushService>();

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_push.openedRoutes.listen(_open))
      ..add(_push.foregroundPushes.listen(_banner));
    // The session is usually restored before the first frame.
    if (sl<SessionCubit>().state is SessionAuthenticated) _openLaunchRoute();
  }

  void _openLaunchRoute() {
    if (_push.takeLaunchRoute() case final route?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(route));
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _open(String route) => sl<GoRouter>().push(route);

  void _banner(ForegroundPush push) {
    // iOS already showed the system banner.
    if (Theme.of(context).platform == TargetPlatform.iOS) return;
    final l10n = context.l10n;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10n.pushNewUpdate(push.title, push.body)),
        action: push.route == null
            ? null
            : SnackBarAction(
                label: l10n.pushView,
                onPressed: () => _open(push.route!),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A push that launched the app opens once the user is signed in.
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (_, curr) => curr is SessionAuthenticated,
      listener: (_, _) => _openLaunchRoute(),
      child: widget.child,
    );
  }
}
