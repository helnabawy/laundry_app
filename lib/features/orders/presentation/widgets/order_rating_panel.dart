import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../addresses/presentation/widgets/address_form_fields.dart';
import '../../domain/entities/order_rating.dart';

/// Step 5.5 on the delivered order: five stars and an optional note, sent
/// once. After that the panel keeps showing what the customer gave.
class OrderRatingPanel extends StatefulWidget {
  const OrderRatingPanel({
    super.key,
    required this.rating,
    required this.submitting,
    required this.onSubmit,
  });

  /// Null until the customer has rated.
  final OrderRating? rating;
  final bool submitting;
  final void Function(int stars, String? comment) onSubmit;

  @override
  State<OrderRatingPanel> createState() => _OrderRatingPanelState();
}

class _OrderRatingPanelState extends State<OrderRatingPanel> {
  var _stars = 0;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _note.text.trim();
    widget.onSubmit(_stars, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    if (widget.rating case final given?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StampHeading(
            l10n.yourRating,
            padding: const EdgeInsets.only(bottom: DesignSpace.belowHeading),
          ),
          Row(
            children: [
              _StarRow(stars: given.stars, size: 22),
              const SizedBox(width: DesignSpace.md),
              Text(
                _starsWord(l10n, given.stars),
                style: text.bodyMedium?.copyWith(color: colors.inkSecondary),
              ),
            ],
          ),
          if (given.comment case final comment?) ...[
            const SizedBox(height: DesignSpace.sm),
            Text(comment, style: text.bodyMedium),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StampHeading(
          l10n.rateOrderTitle,
          padding: const EdgeInsets.only(bottom: DesignSpace.xs),
        ),
        Text(
          l10n.rateOrderBody,
          style: text.bodyMedium?.copyWith(color: colors.inkSecondary),
        ),
        const SizedBox(height: DesignSpace.md),
        Row(
          children: [
            _StarRow(
              stars: _stars,
              size: 32,
              onChanged: widget.submitting
                  ? null
                  : (n) => setState(() => _stars = n),
            ),
            const SizedBox(width: DesignSpace.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: DesignMotion.quick,
                child: Text(
                  _stars == 0 ? '' : _starsWord(l10n, _stars),
                  key: ValueKey(_stars),
                  style: text.bodyMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        // The note and the send only matter once a star is down, so they
        // arrive with it rather than asking for everything up front.
        AnimatedSize(
          duration: DesignMotion.base,
          curve: DesignMotion.settle,
          alignment: AlignmentDirectional.topStart,
          child: _stars == 0
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: DesignSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabelField(
                        controller: _note,
                        label: l10n.ratingNoteHint,
                        textInputAction: TextInputAction.done,
                      ),
                      ActionButton(
                        label: l10n.submitRating,
                        loading: widget.submitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

String _starsWord(AppLocalizations l10n, int stars) => switch (stars) {
  1 => l10n.ratingPoor,
  2 => l10n.ratingFair,
  3 => l10n.ratingGood,
  4 => l10n.ratingVeryGood,
  _ => l10n.ratingExcellent,
};

/// Five stars; tappable when [onChanged] is given. Each keeps a full touch
/// target even when drawn small.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars, required this.size, this.onChanged});

  final int stars;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final onChanged = this.onChanged;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var n = 1; n <= OrderRating.maxStars; n++)
          _Star(
            filled: n <= stars,
            size: size,
            color: n <= stars ? colors.ink : colors.ruleStrong,
            label: l10n.ratingStarsOf(n),
            selected: n == stars,
            onTap: onChanged == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onChanged(n);
                  },
          ),
      ],
    );
    if (onChanged != null) return row;
    return Semantics(
      label: l10n.ratingStarsOf(stars),
      excludeSemantics: true,
      child: row,
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.filled,
    required this.size,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final bool filled;
  final double size;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedSwitcher(
      duration: DesignMotion.quick,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        filled ? CupertinoIcons.star_fill : CupertinoIcons.star,
        key: ValueKey(filled),
        size: size,
        color: color,
      ),
    );
    if (onTap == null) return icon;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: DesignSpace.touchTarget,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
