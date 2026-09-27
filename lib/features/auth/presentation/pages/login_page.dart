import 'package:flutter/cupertino.dart';
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
import '../../domain/entities/saved_account.dart';
import '../cubit/login_cubit.dart';

/// Mobile number + name + "send code" — no password (steps 1.2, 1.4).
///
/// A device that has signed in before opens on that account instead: one tap
/// sends its code, and the name isn't asked again.
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
  final _name = TextEditingController();
  final _nameFocus = FocusNode();

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final cubit = context.read<LoginCubit>();
    if (cubit.state.usingSavedAccount) {
      cubit.continueWithSavedAccount();
    } else {
      cubit.submit(phone: _phone.text, fullName: _name.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      switch (state) {
                        LoginState(
                          usingSavedAccount: true,
                          savedAccount: final account?,
                        ) =>
                          _SavedAccountSection(
                            account: account,
                            state: state,
                            onContinue: _submit,
                          ),
                        _ => _NewNumberSection(
                          phone: _phone,
                          name: _name,
                          nameFocus: _nameFocus,
                          state: state,
                          onSubmit: _submit,
                        ),
                      },
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

/// "Welcome back": the saved name and number as one row. Tapping it sends the
/// code; the OTP still proves the phone is in hand.
class _SavedAccountSection extends StatelessWidget {
  const _SavedAccountSection({
    required this.account,
    required this.state,
    required this.onContinue,
  });

  final SavedAccount account;
  final LoginState state;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<LoginCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabelGroup(
          heading: l10n.welcomeBack,
          children: [
            LabelRow(
              leading: Icon(CupertinoIcons.person, size: 21, color: colors.ink),
              title: account.fullName,
              // Isolated left-to-right so the number reads correctly in Arabic.
              subtitle: '\u2066${account.phone.formatted}\u2069',
              enabled: !state.submitting,
              onTap: onContinue,
              trailing: state.submitting
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.inkSecondary,
                      ),
                    )
                  : const Icon(CupertinoIcons.chevron_forward),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSpace.gutter,
            DesignSpace.sm,
            DesignSpace.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.failure case final failure?) ...[
                _ErrorLine(failure.localized(l10n)),
                const SizedBox(height: DesignSpace.sm),
              ],
              TintAction(
                label: l10n.useAnotherNumber,
                onPressed: state.submitting ? null : cubit.useAnotherNumber,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A number this device hasn't signed in with: the number, then the name.
class _NewNumberSection extends StatelessWidget {
  const _NewNumberSection({
    required this.phone,
    required this.name,
    required this.nameFocus,
    required this.state,
    required this.onSubmit,
  });

  final TextEditingController phone;
  final TextEditingController name;
  final FocusNode nameFocus;
  final LoginState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<LoginCubit>();
    final phoneFailure = state.nameMissing ? null : state.failure;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.mobileNumber.toUpperCase(),
            style: DesignTypography.stamp(colors.inkSecondary),
          ),
          const SizedBox(height: DesignSpace.sm),
          _PhoneField(
            controller: phone,
            hasError: phoneFailure != null,
            onChanged: (_) => cubit.clearError(),
            onSubmitted: nameFocus.requestFocus,
          ),
          if (phoneFailure case final failure?) ...[
            const SizedBox(height: DesignSpace.sm),
            _ErrorLine(failure.localized(l10n)),
          ],
          const SizedBox(height: DesignSpace.xl),
          Text(
            l10n.fullName.toUpperCase(),
            style: DesignTypography.stamp(colors.inkSecondary),
          ),
          TextField(
            controller: name,
            focusNode: nameFocus,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            style: text.bodyLarge,
            onChanged: (_) => cubit.clearError(),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              isDense: true,
              errorText: state.nameMissing ? l10n.requiredField : null,
            ),
          ),
          const SizedBox(height: DesignSpace.lg),
          Text(
            l10n.smsHint,
            style: text.bodySmall?.copyWith(color: colors.inkSecondary),
          ),
          if (state.savedAccount case final saved?)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TintAction(
                label: l10n.continueAs(saved.fullName),
                onPressed: state.submitting ? null : cubit.useSavedAccount,
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
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.colors.signal),
  );
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
              textInputAction: TextInputAction.next,
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
