import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';

/// The photography this product ships with.
///
/// A care label sits on cloth, so the photograph is the ground and the tape,
/// rules, stamps and glyphs are what is printed over it. Every slot here is
/// placeholder stock — see `assets/images/CREDITS.md` for what replaces it.
abstract final class Photo {
  static const heroLinen = 'assets/images/hero-linen.webp';
  static const confirmFolded = 'assets/images/confirm-folded.webp';

  static const _categories = {
    'cat-clothes': 'assets/images/cat-clothes.webp',
    'cat-textiles': 'assets/images/cat-textiles.webp',
    'cat-carpets': 'assets/images/cat-carpets.webp',
    'cat-curtains': 'assets/images/cat-curtains.webp',
  };

  /// Null when a category has no photograph yet — callers fall back to the
  /// glyph rather than showing a broken or borrowed image.
  static String? category(String categoryId) => _categories[categoryId];
}

/// How much the scrim has to carry.
enum ScrimWeight {
  /// Nothing sits on the image.
  none,

  /// A line or two anchored low.
  light,

  /// A full block of type over the whole frame.
  heavy,
}

/// A photograph with the ink scrim that makes type on it legible.
///
/// The scrim is not decoration: text over an uncontrolled photograph has no
/// contrast guarantee, so every image that carries words gets one.
class PhotoBand extends StatelessWidget {
  const PhotoBand({
    super.key,
    required this.image,
    this.height,
    this.aspectRatio,
    this.child,
    this.scrim = ScrimWeight.light,
    this.alignment = Alignment.center,
    this.semanticLabel,
  });

  final String image;
  final double? height;
  final double? aspectRatio;
  final Widget? child;
  final ScrimWeight scrim;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The scrim is always built from the ink, so it reads as the system's own
    // material rather than a generic black wash.
    final ink = colors.isDark ? const Color(0xFF000000) : colors.ink;

    Widget frame = Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.cover,
          alignment: alignment,
          // Photographs fade in rather than popping once decoded.
          frameBuilder: (context, child, frame, wasSyncLoaded) {
            if (wasSyncLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: DesignMotion.base,
              curve: DesignMotion.enter,
              child: child,
            );
          },
          errorBuilder: (context, _, _) =>
              ColoredBox(color: colors.tapeRecessed),
        ),
        if (scrim != ScrimWeight.none)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Three stops, not two: the top stays airy while the foot is
                // dark enough to carry a two-line block at the 4.5:1 body
                // floor, whatever the photograph is doing underneath.
                colors: switch (scrim) {
                  ScrimWeight.light => [
                    ink.withValues(alpha: .06),
                    ink.withValues(alpha: .34),
                    ink.withValues(alpha: .82),
                  ],
                  ScrimWeight.heavy => [
                    ink.withValues(alpha: .46),
                    ink.withValues(alpha: .68),
                    ink.withValues(alpha: .90),
                  ],
                  ScrimWeight.none => [
                    const Color(0x00000000),
                    const Color(0x00000000),
                    const Color(0x00000000),
                  ],
                },
                stops: const [0, .46, 1],
              ),
            ),
          ),
        ?child,
      ],
    );

    if (aspectRatio != null) {
      frame = AspectRatio(aspectRatio: aspectRatio!, child: frame);
    } else if (height != null) {
      frame = SizedBox(height: height, child: frame);
    }

    return Semantics(image: true, label: semanticLabel, child: frame);
  }
}
