import 'package:flutter/material.dart';

import '../glyphs/care_glyph.dart';
import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';
import 'app_buttons.dart';

/// Loading, as a label being read rather than a spinner in a void.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.inkSecondary,
              ),
            ),
            if (label case final text?) ...[
              const SizedBox(height: DesignSpace.lg),
              Text(
                text.toUpperCase(),
                textAlign: TextAlign.center,
                style: DesignTypography.stamp(colors.inkTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The blank tape: a real, ruled, empty label rather than a shrug.
///
/// Every glyph outline, nothing filled, and the way out printed on the tape
/// itself. This is the first screen a new customer meets, so it carries the
/// primary action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.glyph = CareGlyph.custody,
    this.actionLabel,
    this.onAction,
    this.note,
  });

  final String message;
  final CareGlyph glyph;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSpace.xxxl,
          vertical: DesignSpace.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CareGlyphIcon(glyph, color: colors.inkTertiary, size: 40),
            const SizedBox(height: DesignSpace.lg),
            Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: DesignTypography.stamp(colors.inkSecondary, size: 13),
            ),
            if (note case final line?) ...[
              const SizedBox(height: DesignSpace.sm),
              Text(
                line,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: colors.inkTertiary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignSpace.xxl),
              ActionButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An error names the problem and the way back.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CareGlyphIcon(
              CareGlyph.custody,
              color: colors.signal,
              size: 36,
              crossed: true,
              crossColor: colors.signal,
            ),
            const SizedBox(height: DesignSpace.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.inkSecondary),
            ),
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: DesignSpace.xl),
              ActionButton(
                label: retryLabel!,
                onPressed: onRetry,
                tone: ActionTone.secondary,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tinted notice. Info borrows the tint wash, caution the signal wash;
/// neither invents a colour the palette does not already own.
enum NoticeTone { info, caution, done }

class NoticeBlock extends StatelessWidget {
  const NoticeBlock({
    super.key,
    required this.title,
    this.message,
    this.tone = NoticeTone.info,
    this.glyph,
  });

  final String title;
  final String? message;
  final NoticeTone tone;
  final Widget? glyph;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final (ground, ink) = switch (tone) {
      NoticeTone.info => (colors.tapeRecessed, colors.ink),
      NoticeTone.caution => (colors.signalWash, colors.signal),
      NoticeTone.done => (colors.tintWash, colors.tint),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignSpace.lg),
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(DesignRadius.panel),
        border: Border.all(
          color: tone == NoticeTone.info
              ? colors.rule
              : ink.withValues(alpha: .28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (glyph case final g?) ...[
            IconTheme(
              data: IconThemeData(color: ink, size: 22),
              child: g,
            ),
            const SizedBox(width: DesignSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title.toUpperCase(), style: DesignTypography.stamp(ink)),
                if (message case final body?) ...[
                  const SizedBox(height: DesignSpace.xs),
                  Text(
                    body,
                    style: text.bodySmall?.copyWith(
                      color: tone == NoticeTone.info
                          ? colors.inkSecondary
                          : ink.withValues(alpha: .92),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
