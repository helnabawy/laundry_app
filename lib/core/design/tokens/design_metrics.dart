import 'package:flutter/widgets.dart';

/// Spacing, rule weights, radii and motion.
///
/// One rhythm runs through the whole app: tight inside a group, generous
/// between groups, and always more room above a heading than below it.
abstract final class DesignSpace {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const vast = 56.0;

  /// The page gutter. Everything that is not full-bleed tape starts here.
  static const gutter = 20.0;

  /// Space above a heading, against [belowHeading] under it.
  static const aboveHeading = 32.0;
  static const belowHeading = 12.0;

  /// Apple's floor for anything you can touch.
  static const touchTarget = 44.0;
}

abstract final class DesignRule {
  /// The stitch hairline. Resolved against device pixel ratio at paint time.
  static const hair = 1.0;
  static const medium = 1.5;
  static const heavy = 2.0;

  /// Stroke weight for every glyph in the pictogram family, at 24pt.
  static const glyphStroke = 1.9;
}

abstract final class DesignRadius {
  /// The system is drawn with rules and tape, not with rounded boxes. These
  /// exist for the few surfaces iOS itself rounds.
  static const none = 0.0;
  static const slot = 4.0;
  static const panel = 10.0;
  static const sheet = 14.0;
  static const control = 12.0;
}

abstract final class DesignMotion {
  /// A glyph filling, a dot appearing, a numeral changing in place.
  static const quick = Duration(milliseconds: 140);

  /// The strip advancing one stage.
  static const base = Duration(milliseconds: 260);

  /// The authored moment: a modifier being added.
  static const authored = Duration(milliseconds: 420);

  /// Undo windows after an irreversible-feeling confirm.
  static const undoWindow = Duration(seconds: 5);

  static const enter = Curves.easeOutCubic;
  static const settle = Curves.easeOutQuart;
  static const exit = Curves.easeInCubic;
}
