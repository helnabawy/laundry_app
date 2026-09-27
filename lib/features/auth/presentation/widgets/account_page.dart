import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/locale/locale_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/phone_format.dart';
import '../../domain/entities/app_user.dart';
import '../cubit/session_cubit.dart';

/// The account tab, shared by the customer and driver shells.
///
/// The user's own label: the initial stamped into a tape square, the fields
/// beneath it as ruled rows.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final state = context.watch<SessionCubit>().state;
    final user = state is SessionAuthenticated ? state.user : null;
    final name = user?.fullName?.trim();
    final languageCode = context.watch<LocaleCubit>().languageCode;

    return LargeTitlePage(
      title: l10n.account,
      trailing: _LogoutAction(phone: user?.phone),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpace.gutter,
              vertical: DesignSpace.lg,
            ),
            child: Row(
              children: [
                _Initial(letter: name?.isNotEmpty ?? false ? name![0] : null),
                const SizedBox(width: DesignSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name?.isNotEmpty ?? false ? name! : l10n.account,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: DesignSpace.xs),
                      Text(
                        formatUaePhone(user?.phone ?? ''),
                        textDirection: TextDirection.ltr,
                        style: DesignTypography.numeric(
                          colors.inkSecondary,
                          size: 15,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (user?.role == UserRole.customer)
          SliverToBoxAdapter(
            child: LabelGroup(
              heading: l10n.addressesHeading,
              children: [
                LabelRow(
                  leading: Icon(CupertinoIcons.placemark, color: colors.ink),
                  title: l10n.savedAddresses,
                  trailing: const Icon(CupertinoIcons.chevron_forward),
                  onTap: () => context.push(Routes.addresses),
                ),
              ],
            ),
          ),
        SliverToBoxAdapter(
          child: LabelGroup(
            heading: l10n.language,
            children: [
              LabelRow(
                title: languageCode == 'ar' ? 'العربية' : 'English',
                subtitle: languageCode == 'ar' ? 'Arabic' : 'الإنجليزية',
                trailing: const Icon(CupertinoIcons.chevron_forward),
                onTap: () => _pickLanguage(context, languageCode),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickLanguage(BuildContext context, String current) async {
    final cubit = context.read<LocaleCubit>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: DesignSpace.sm),
            LabelGroup(
              children: [
                for (final (code, native, translated) in const [
                  ('ar', 'العربية', 'Arabic'),
                  ('en', 'English', 'الإنجليزية'),
                ])
                  LabelRow(
                    title: native,
                    subtitle: translated,
                    selected: code == current,
                    trailing: code == current
                        ? const Icon(CupertinoIcons.checkmark_alt)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, code),
                  ),
              ],
            ),
            const SizedBox(height: DesignSpace.lg),
          ],
        ),
      ),
    );
    if (choice != null && choice != current) await cubit.setLanguage(choice);
  }
}

/// The initial, stamped into a tape square.
class _Initial extends StatelessWidget {
  const _Initial({this.letter});

  final String? letter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.tapeRecessed,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(DesignRadius.slot),
      ),
      child: letter == null
          ? CareGlyphIcon(
              CareGlyph.custody,
              color: colors.inkTertiary,
              size: 26,
            )
          : Text(
              letter!.toUpperCase(),
              style: DesignTypography.serial(colors.ink, size: 26),
            ),
    );
  }
}

/// Log out lives in the header, where iOS keeps account-level actions, out of
/// the thumb's path through the list. It is set in the tint like any other
/// action; the red is saved for the sheet's commit.
class _LogoutAction extends StatelessWidget {
  const _LogoutAction({this.phone});

  final String? phone;

  Future<void> _confirm(BuildContext context) async {
    final l10n = context.l10n;
    final session = context.read<SessionCubit>();
    final number = formatUaePhone(phone ?? '');
    final confirmed = await showConfirmSheet(
      context,
      title: l10n.logoutConfirmTitle,
      // Isolated left-to-right so the number reads correctly in Arabic.
      message: l10n.logoutConfirmBody('\u2066$number\u2069'),
      confirmLabel: l10n.logout,
      cancelLabel: l10n.cancel,
    );
    if (confirmed) await session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return TintAction(
      label: context.l10n.logout,
      // The door arrow points out of the page in reading direction.
      trailing: Transform.flip(
        flipX: rtl,
        child: const Icon(CupertinoIcons.square_arrow_right),
      ),
      onPressed: () => _confirm(context),
    );
  }
}
