import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../addresses/presentation/widgets/address_form_fields.dart';
import '../../domain/entities/task_failure.dart';
import 'proof_photo_field.dart';

typedef FailureReport = ({
  TaskFailureReason reason,
  String? note,
  bool hasPhoto,
});

/// "Couldn't pick up" / "Couldn't deliver": pick a reason, optionally add a
/// note. With [requirePhoto] the driver must also photograph the stop before
/// submitting — it is the evidence if the customer disputes the report. The
/// cross modifier is the system's mark for a refusal, so the sheet wears it.
Future<FailureReport?> showFailureReasonSheet(
  BuildContext context, {
  required String title,
  bool requirePhoto = false,
}) {
  return showModalBottomSheet<FailureReport>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _FailureReasonSheet(title: title, requirePhoto: requirePhoto),
  );
}

class _FailureReasonSheet extends StatefulWidget {
  const _FailureReasonSheet({required this.title, required this.requirePhoto});

  final String title;
  final bool requirePhoto;

  @override
  State<_FailureReasonSheet> createState() => _FailureReasonSheetState();
}

class _FailureReasonSheetState extends State<_FailureReasonSheet> {
  TaskFailureReason _reason = TaskFailureReason.customerAbsent;
  final _noteController = TextEditingController();

  // TODO(camera): capture a real image and upload it with the report; until
  // the upload endpoint exists this marks the photo as taken, like proof of
  // delivery does.
  var _hasPhoto = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final options = {
      TaskFailureReason.customerAbsent: l10n.reasonCustomerAbsent,
      TaskFailureReason.wrongAddress: l10n.reasonWrongAddress,
      TaskFailureReason.customerRescheduled: l10n.reasonCustomerRescheduled,
      TaskFailureReason.other: l10n.reasonOther,
    };

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignSpace.gutter,
                0,
                DesignSpace.gutter,
                DesignSpace.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CareGlyphIcon(
                    CareGlyph.custody,
                    color: colors.ink,
                    size: 26,
                    crossed: true,
                    crossColor: colors.signal,
                  ),
                  const SizedBox(width: DesignSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: DesignSpace.xxs),
                        Text(
                          l10n.failureReasonTitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            LabelGroup(
              children: [
                for (final entry in options.entries)
                  LabelRow(
                    title: entry.value,
                    selected: _reason == entry.key,
                    trailing: _reason == entry.key
                        ? const Icon(CupertinoIcons.checkmark_alt)
                        : null,
                    onTap: () => setState(() => _reason = entry.key),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignSpace.gutter,
                DesignSpace.xxl,
                DesignSpace.gutter,
                0,
              ),
              child: LabelField(
                controller: _noteController,
                label: l10n.reasonNotesHint,
                textInputAction: TextInputAction.done,
              ),
            ),
            if (widget.requirePhoto)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSpace.gutter,
                  DesignSpace.xl,
                  DesignSpace.gutter,
                  0,
                ),
                child: ProofPhotoField(
                  hasPhoto: _hasPhoto,
                  prompt: l10n.takePhotoOfStop,
                  onTap: () => setState(() => _hasPhoto = !_hasPhoto),
                ),
              ),
            ActionBar(
              note: widget.requirePhoto && !_hasPhoto
                  ? l10n.photoRequiredFirst
                  : null,
              children: [
                ActionButton(
                  label: l10n.submit,
                  tone: ActionTone.danger,
                  onPressed: widget.requirePhoto && !_hasPhoto
                      ? null
                      : () => Navigator.pop(context, (
                          reason: _reason,
                          note: _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim(),
                          hasPhoto: _hasPhoto,
                        )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
