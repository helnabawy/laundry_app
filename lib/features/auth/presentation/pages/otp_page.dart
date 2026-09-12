import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/flow_header.dart';
import '../../domain/entities/phone_number.dart';
import '../cubit/otp_cubit.dart';
import '../cubit/session_cubit.dart';
import '../widgets/otp_input.dart';

/// 4-digit SMS code with a resend countdown (step 1.3).
class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.phone});

  final PhoneNumber phone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OtpCubit(phone: phone, verifyOtp: sl(), requestOtp: sl()),
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
    final text = Theme.of(context).textTheme;
    final cubit = context.read<OtpCubit>();

    return BlocConsumer<OtpCubit, OtpState>(
      listener: (context, state) {
        if (state.user != null) {
          context.read<SessionCubit>().signedIn(state.user!);
        }
        if (state.resent) {
          _code.clear();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.codeResent)));
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            FlowHeader(title: l10n.enterCode),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                children: [
                  const SizedBox(height: 16),
                  Text(
                    l10n.codeSentTo,
                    style: text.bodyLarge?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      cubit.phone.formatted,
                      textDirection: TextDirection.ltr,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  OtpInput(
                    controller: _code,
                    length: AppConfig.otpLength,
                    hasError: state.failure != null,
                    enabled: !state.verifying,
                    onChanged: cubit.codeChanged,
                  ),
                  const SizedBox(height: 20),
                  if (state.failure != null)
                    Text(
                      state.failure!.localized(l10n),
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: AppColors.danger),
                    ),
                  Center(
                    child: state.canResend
                        ? TextButton(
                            onPressed: cubit.resend,
                            child: Text(l10n.resendCode),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              l10n.resendIn(_countdown(state.secondsLeft)),
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: l10n.confirm,
                    loading: state.verifying,
                    onPressed: state.isComplete ? cubit.verify : null,
                  ),
                  if (AppConfig.useMockApi) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.mockCodeHint(MockDatabase.otpCode),
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: AppColors.gold),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
