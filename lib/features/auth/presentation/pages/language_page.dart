import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_logo.dart';

/// First launch: pick Arabic or English (step 1.1). Labels are shown in both
/// languages on purpose — the user hasn't chosen yet.
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selected = context.read<LocaleCubit>().languageCode;

  static const _options = [('ar', 'العربية'), ('en', 'English')];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(),
              const SizedBox(height: 32),
              Text(
                'اختر اللغة',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Choose your language',
                style: text.titleMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 32),
              for (final (code, label) in _options) ...[
                SelectableCard(
                  selected: _selected == code,
                  onTap: () => setState(() => _selected = code),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SelectionIndicator(selected: _selected == code),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(flex: 2),
              PrimaryButton(
                label: _selected == 'ar' ? 'متابعة' : 'Continue',
                onPressed: () =>
                    context.read<LocaleCubit>().setLanguage(_selected),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
