import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/digits.dart';
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
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (prev, curr) =>
          curr.codeSentTo != null && prev.codeSentTo != curr.codeSentTo,
      listener: (context, state) {
        context.push(Routes.otp, extra: state.codeSentTo);
        context.read<LoginCubit>().acknowledge();
      },
      builder: (context, state) => Scaffold(
        backgroundColor: colors.tape,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSpace.gutter,
                        ),
                        child: AppMarkLockup(
                          name: l10n.appName,
                          tagline: l10n.appTagline,
                        ),
                      ),
                      const Spacer(flex: 2),
                      const SizedBox(height: DesignSpace.xxxl),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSpace.gutter,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.mobileNumber.toUpperCase(),
                              style: DesignTypography.stamp(
                                colors.inkSecondary,
                              ),
                            ),
                            const SizedBox(height: DesignSpace.sm),
                            _PhoneField(
                              controller: _phone,
                              hasError: state.failure != null,
                              onChanged: (_) =>
                                  context.read<LoginCubit>().clearError(),
                              onSubmitted: _submit,
                            ),
                            if (state.failure case final failure?) ...[
                              const SizedBox(height: DesignSpace.sm),
                              Text(
                                failure.localized(l10n),
                                style: text.bodySmall?.copyWith(
                                  color: colors.signal,
                                ),
                              ),
                            ],
                            const SizedBox(height: DesignSpace.lg),
                            Text(
                              l10n.smsHint,
                              style: text.bodySmall?.copyWith(
                                color: colors.inkSecondary,
                              ),
                            ),
                            if (AppConfig.useMockApi) ...[
                              const SizedBox(height: DesignSpace.lg),
                              NoticeBlock(
                                title: 'Demo',
                                message: l10n.mockLoginHint(
                                  MockDatabase.customerPhone.substring(4),
                                  MockDatabase.driverPhone.substring(4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(flex: 5),
                      const SizedBox(height: DesignSpace.xxxl),
                      ActionBar(
                        note: l10n.termsNotice,
                        children: [
                          ActionButton(
                            label: l10n.sendCode,
                            loading: state.submitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
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

/// A ruled field, with the dial code held in its own slot before the rule.
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
    final colors = context.colors;
    // Phone numbers always read left-to-right, even in Arabic.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: DesignSpace.md),
            child: Text(
              AppConfig.countryDialCode,
              style: DesignTypography.numeric(
                colors.inkSecondary,
                size: 20,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: DesignSpace.md),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                DigitsInputFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              style: DesignTypography.numeric(
                colors.ink,
                size: 22,
                weight: FontWeight.w600,
              ).copyWith(letterSpacing: 1.5),
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
              decoration: InputDecoration(
                hintText: '50 123 4567',
                hintStyle: DesignTypography.numeric(
                  colors.inkTertiary,
                  size: 22,
                  weight: FontWeight.w400,
                ).copyWith(letterSpacing: 1.5),
                enabledBorder: hasError
                    ? UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.signal),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
