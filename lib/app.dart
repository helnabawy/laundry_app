import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/l10n/l10n.dart';
import 'core/locale/locale_cubit.dart';
import 'core/design/design.dart';
import 'core/theme/theme_cubit.dart';
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
            builder: (context, child) => _SessionExpiryListener(child: child!),
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
