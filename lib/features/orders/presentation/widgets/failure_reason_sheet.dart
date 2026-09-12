import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../domain/repositories/driver_task_repository.dart';

/// "تعذّر الاستلام" / "تعذّر التسليم" (plan §9, stages 3 & 5 open points):
/// pick a reason, optionally add a note.
Future<({TaskFailureReason reason, String? note})?> showFailureReasonSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<({TaskFailureReason reason, String? note})>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _FailureReasonSheet(title: title),
  );
}

class _FailureReasonSheet extends StatefulWidget {
  const _FailureReasonSheet({required this.title});

  final String title;

  @override
  State<_FailureReasonSheet> createState() => _FailureReasonSheetState();
}

class _FailureReasonSheetState extends State<_FailureReasonSheet> {
  TaskFailureReason _reason = TaskFailureReason.customerAbsent;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = {
      TaskFailureReason.customerAbsent: l10n.reasonCustomerAbsent,
      TaskFailureReason.wrongAddress: l10n.reasonWrongAddress,
      TaskFailureReason.customerRescheduled: l10n.reasonCustomerRescheduled,
      TaskFailureReason.other: l10n.reasonOther,
    };
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(l10n.failureReasonTitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          RadioGroup<TaskFailureReason>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v!),
            child: Column(
              children: [
                for (final entry in options.entries)
                  RadioListTile<TaskFailureReason>(
                    contentPadding: EdgeInsets.zero,
                    value: entry.key,
                    title: Text(entry.value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: l10n.reasonNotesHint),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.submit,
            onPressed: () => Navigator.pop(context, (
              reason: _reason,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            )),
          ),
        ],
      ),
    );
  }
}
