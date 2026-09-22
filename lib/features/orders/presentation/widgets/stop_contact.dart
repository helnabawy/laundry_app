import 'package:flutter/cupertino.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/phone_format.dart';
import '../utils/launchers.dart';

/// Who the driver is meeting, and the two ways to reach them.
///
/// Reaching the customer is the driver's most time-critical action after
/// navigating, so both routes sit on one strip at full touch size.
class StopContact extends StatelessWidget {
  const StopContact({super.key, required this.name, required this.phone});

  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabelGroup(
          children: [
            LabelRow(
              leading: Icon(CupertinoIcons.person, color: colors.ink),
              title: name,
              subtitle: formatUaePhone(phone),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSpace.gutter,
            DesignSpace.md,
            DesignSpace.gutter,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: l10n.call,
                  tone: ActionTone.secondary,
                  icon: const Icon(CupertinoIcons.phone),
                  onPressed: () => launchTel(phone),
                ),
              ),
              const SizedBox(width: DesignSpace.md),
              Expanded(
                child: ActionButton(
                  label: l10n.message,
                  tone: ActionTone.secondary,
                  icon: const Icon(CupertinoIcons.chat_bubble),
                  onPressed: () => launchSms(phone),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
