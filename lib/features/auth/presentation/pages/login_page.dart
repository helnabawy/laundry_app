import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/digits.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_logo.dart';
import '../cubit/login_cubit.dart';

/// Mobile number + "send code" — no password (step 1.2).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit(_phone.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (prev, curr) =>
          curr.codeSentTo != null && prev.codeSentTo != curr.codeSentTo,
      listener: (context, state) {
        context.push(Routes.otp, extra: state.codeSentTo);
        context.read<LoginCubit>().acknowledge();
      },
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      const SizedBox(height: 32),
                      const AppLogo(),
                      const SizedBox(height: 24),
                      Text(
                        l10n.appName,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appTagline,
                        style: text.bodyLarge?.copyWith(color: AppColors.muted),
                      ),
                      const Spacer(flex: 2),
                      const SizedBox(height: 32),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.mobileNumber,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PhoneField(
                        controller: _phone,
                        hasError: state.failure != null,
                        onChanged: (_) =>
                            context.read<LoginCubit>().clearError(),
                        onSubmitted: _submit,
                      ),
                      if (state.failure != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            state.failure!.localized(l10n),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: l10n.sendCode,
                        loading: state.submitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.smsHint,
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      if (AppConfig.useMockApi) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.mockLoginHint(
                            MockDatabase.customerPhone.substring(4),
                            MockDatabase.driverPhone.substring(4),
                          ),
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                      const Spacer(flex: 5),
                      const SizedBox(height: 32),
                      Text(
                        l10n.termsNotice,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    // Phone numbers always read left-to-right, even in Arabic.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: [
          DigitsInputFormatter(),
          LengthLimitingTextInputFormatter(10),
        ],
        style: const TextStyle(fontSize: 20, letterSpacing: 1),
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(
          hintText: '50 123 4567',
          enabledBorder: hasError
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.danger),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppConfig.countryDialCode,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 32, color: AppColors.line),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
