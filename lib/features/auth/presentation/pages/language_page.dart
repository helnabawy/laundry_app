import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/locale/locale_cubit.dart';

/// First launch: pick Arabic or English (step 1.1). Labels are shown in both
/// languages on purpose — the user hasn't chosen yet, so neither script may
/// be treated as the default.
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selected = context.read<LocaleCubit>().languageCode;

  static const _options = [
    ('ar', 'العربية', 'Arabic'),
    ('en', 'English', 'الإنجليزية'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.tape,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
              child: AppMark(size: 72),
            ),
            const SizedBox(height: DesignSpace.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSpace.gutter,
              ),
              child: Column(
                children: [
                  Text(
                    'اختر اللغة',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: DesignSpace.xxs),
                  Text(
                    'CHOOSE YOUR LANGUAGE',
                    textAlign: TextAlign.center,
                    style: DesignTypography.fibreLine(colors.inkTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignSpace.xxxl),
            LabelGroup(
              children: [
                for (final (code, native, translated) in _options)
                  LabelRow(
                    title: native,
                    subtitle: translated,
                    selected: _selected == code,
                    onTap: () => setState(() => _selected = code),
                    trailing: _selected == code
                        ? const Icon(CupertinoIcons.checkmark_alt)
                        : null,
                  ),
              ],
            ),
            const Spacer(flex: 2),
            ActionBar(
              children: [
                ActionButton(
                  label: _selected == 'ar' ? 'متابعة' : 'Continue',
                  onPressed: () =>
                      context.read<LocaleCubit>().setLanguage(_selected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
