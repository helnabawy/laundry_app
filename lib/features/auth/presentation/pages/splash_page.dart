import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../cubit/session_cubit.dart';

/// Shown while the stored session is restored; the router moves on once
/// the [SessionCubit] settles.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.tape,
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final failure = state is SessionUnknown ? state.failure : null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DesignSpace.xxxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  AppMark(size: 96, semanticLabel: context.l10n.appName),
                  const Spacer(),
                  if (failure == null)
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.inkTertiary,
                      ),
                    )
                  else
                    ErrorView(
                      message: failure.localized(context.l10n),
                      retryLabel: context.l10n.retry,
                      onRetry: context.read<SessionCubit>().restore,
                    ),
                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
