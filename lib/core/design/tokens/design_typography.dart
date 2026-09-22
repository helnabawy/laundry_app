import 'package:flutter/material.dart';

/// Type in the Care Label system.
///
/// SF (the platform face) carries every word the user reads as prose: body,
/// labels, controls, all of it under Dynamic Type. Archivo appears only where
/// the label itself speaks — serials, fibre-content lines, stamped caps — and
/// Noto Kufi Arabic stands in for it when the display string is Arabic.
abstract final class DesignTypography {
  /// Arabic is a connected script: tracking pulls the joins apart and is a
  /// typographic error, not a stylistic choice. It also needs a slightly
  /// larger optical size than Latin to read at the same point size. Both are
  /// set once from the app's resolved locale.
  static var _isArabicScript = false;

  static set script(String languageCode) =>
      _isArabicScript = languageCode == 'ar';

  static bool get isArabicScript => _isArabicScript;

  /// Latin tracking, zeroed for Arabic.
  static double _track(double latin) => _isArabicScript ? 0 : latin;

  /// Arabic runs a touch larger for equal legibility.
  static double _optical(double size) => _isArabicScript ? size * 1.09 : size;

  /// Passing null lets Flutter resolve the platform UI face (SF on iOS,
  /// and SF Arabic automatically for Arabic runs).
  static const platformFace = null;

  static const displayFace = 'Archivo';
  static const displayFaceArabic = 'NotoKufiArabic';

  /// Tabular figures: numerals must hold their slot and change in place.
  static const tabular = [FontFeature.tabularFigures()];

  /// The narrow, stamped caps of a fibre-content line.
  static const _narrow = [
    FontVariation('wdth', 84),
    FontVariation('wght', 600),
  ];

  /// The expanded mass of a serial.
  static const _expanded = [
    FontVariation('wdth', 118),
    FontVariation('wght', 800),
  ];

  /// iOS text styles, in points. Flutter scales these by the user's
  /// Dynamic Type setting, so nothing here is a fixed rendered size.
  static TextTheme textTheme(Color ink) {
    TextStyle base(
      double size,
      FontWeight weight, {
      double? height,
      double? tracking,
    }) => TextStyle(
      fontFamily: platformFace,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: tracking,
      color: ink,
    );

    return TextTheme(
      // Large Title
      displayLarge: base(34, FontWeight.w700, height: 1.12, tracking: -.4),
      // Title 1
      displayMedium: base(28, FontWeight.w700, height: 1.15, tracking: -.3),
      // Title 2
      displaySmall: base(22, FontWeight.w700, height: 1.2, tracking: -.2),
      headlineLarge: base(22, FontWeight.w700, height: 1.2, tracking: -.2),
      // Title 3
      headlineMedium: base(20, FontWeight.w600, height: 1.25, tracking: -.15),
      headlineSmall: base(18, FontWeight.w600, height: 1.28),
      // Headline
      titleLarge: base(17, FontWeight.w600, height: 1.3),
      titleMedium: base(16, FontWeight.w600, height: 1.3),
      titleSmall: base(15, FontWeight.w600, height: 1.3),
      // Body
      bodyLarge: base(17, FontWeight.w400, height: 1.4),
      // Callout
      bodyMedium: base(16, FontWeight.w400, height: 1.4),
      // Subheadline
      bodySmall: base(15, FontWeight.w400, height: 1.4),
      // Footnote
      labelLarge: base(13, FontWeight.w600, height: 1.3),
      // Caption 1
      labelMedium: base(12, FontWeight.w500, height: 1.3),
      // Caption 2
      labelSmall: base(11, FontWeight.w500, height: 1.3),
    );
  }

  /// A serial: the order number set as matter. Scale carries identity here,
  /// so this is the one place type is allowed to be large.
  static TextStyle serial(Color ink, {double size = 40}) => TextStyle(
    fontFamily: displayFace,
    fontFamilyFallback: const [displayFaceArabic],
    fontSize: size,
    height: 1,
    letterSpacing: _track(-1),
    color: ink,
    fontVariations: _expanded,
    fontFeatures: tabular,
  );

  /// The fibre-content line: narrow caps, tracked wide, printed small.
  static TextStyle fibreLine(Color ink, {double size = 11.5}) => TextStyle(
    fontFamily: displayFace,
    fontFamilyFallback: const [displayFaceArabic],
    fontSize: _optical(size),
    height: 1.35,
    letterSpacing: _track(1.1),
    color: ink,
    fontVariations: _narrow,
    fontFeatures: tabular,
  );

  /// A stamped caps label — section headings, tag panels, ticket fields.
  static TextStyle stamp(Color ink, {double size = 12.5}) => TextStyle(
    fontFamily: displayFace,
    fontFamilyFallback: const [displayFaceArabic],
    fontSize: _optical(size),
    height: 1.25,
    letterSpacing: _track(1.4),
    color: ink,
    fontVariations: _narrow,
  );

  /// A numeric slot: reserved width, changes in place, never reflows.
  static TextStyle numeric(
    Color ink, {
    double size = 17,
    FontWeight weight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: platformFace,
    fontSize: size,
    fontWeight: weight,
    height: 1.2,
    color: ink,
    fontFeatures: tabular,
  );
}
