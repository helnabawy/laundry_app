import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/session_cubit.dart';

/// Shown while the stored session is restored; the router moves on once
/// the [SessionCubit] settles.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final failure = state is SessionUnknown ? state.failure : null;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(),
                const SizedBox(height: 32),
                if (failure == null)
                  const CircularProgressIndicator()
                else
                  ErrorView(
                    message: failure.localized(context.l10n),
                    onRetry: context.read<SessionCubit>().restore,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
