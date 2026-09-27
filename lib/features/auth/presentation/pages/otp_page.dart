import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/mock/mock_database.dart';
import '../../domain/entities/sign_in_request.dart';
import '../cubit/otp_cubit.dart';
import '../cubit/session_cubit.dart';
import '../widgets/otp_input.dart';

/// 4-digit SMS code with a resend countdown (step 1.3).
class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.request});

  final SignInRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OtpCubit(request: request, verifyOtp: sl(), requestOtp: sl()),
      child: const _OtpView(),
    );
  }
}

class _OtpView extends StatefulWidget {
  const _OtpView();

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _countdown(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<OtpCubit>();

    return BlocConsumer<OtpCubit, OtpState>(
      listener: (context, state) {
        if (state.user case final user?) {
          context.read<SessionCubit>().signedIn(user);
        }
        if (state.resent) {
          _code.clear();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.codeResent)));
        }
      },
      builder: (context, state) => DetailPage(
        title: l10n.enterCode,
        bottomBar: ActionBar(
          children: [
            ActionButton(
              label: l10n.confirm,
              loading: state.verifying,
              onPressed: state.isComplete ? cubit.verify : null,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: DesignSpace.xxl),
                  Text(
                    l10n.codeSentTo.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: DesignTypography.stamp(colors.inkSecondary),
                  ),
                  const SizedBox(height: DesignSpace.sm),
                  Text(
                    cubit.phone.formatted,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: DesignTypography.numeric(
                      colors.ink,
                      size: 19,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DesignSpace.huge),
                  OtpInput(
                    controller: _code,
                    length: AppConfig.otpLength,
                    hasError: state.failure != null,
                    enabled: !state.verifying,
                    onChanged: cubit.codeChanged,
                  ),
                  const SizedBox(height: DesignSpace.xl),
                  if (state.failure case final failure?)
                    Text(
                      failure.localized(l10n),
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: colors.signal),
                    ),
                  const SizedBox(height: DesignSpace.sm),
                  Center(
                    child: state.canResend
                        ? TintAction(
                            label: l10n.resendCode,
                            onPressed: cubit.resend,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: DesignSpace.md,
                            ),
                            child: Text(
                              l10n.resendIn(_countdown(state.secondsLeft)),
                              style: DesignTypography.numeric(
                                colors.inkTertiary,
                                size: 15,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                  ),
                  if (AppConfig.useMockApi) ...[
                    const SizedBox(height: DesignSpace.xl),
                    NoticeBlock(
                      title: 'Demo',
                      message: l10n.mockCodeHint(MockDatabase.otpCode),
                    ),
                  ],
                  const SizedBox(height: DesignSpace.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
