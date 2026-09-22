import 'package:flutter/material.dart';

/// The Care Label palette.
///
/// One ink carries every word, one tint carries every action, and colour is
/// never asked to say what structure already says. Values are contrast-checked
/// against the ground they sit on — see DESIGN.md for the measured pairs.
@immutable
class DesignColors extends ThemeExtension<DesignColors> {
  const DesignColors({
    required this.tape,
    required this.tapeRecessed,
    required this.tapeSunken,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.inkDisabled,
    required this.onInk,
    required this.rule,
    required this.ruleStrong,
    required this.tint,
    required this.tintPressed,
    required this.tintWash,
    required this.onTint,
    required this.signal,
    required this.signalWash,
    required this.onSignal,
    required this.tag,
    required this.onTag,
    required this.brightness,
  });

  /// Label tape: the ground everything is printed on.
  final Color tape;

  /// Grouped-list ground, one step back from [tape].
  final Color tapeRecessed;

  /// The deepest recess, for wells and reserved slots.
  final Color tapeSunken;

  /// The single ink. Every word in the app is this colour or a step of it.
  final Color ink;

  /// Supporting label text. Passes AA on [tape].
  final Color inkSecondary;

  /// Placeholders and fibre-content lines. Passes AA on [tape].
  final Color inkTertiary;

  /// Genuinely inert text. Exempt from contrast minimums by definition.
  final Color inkDisabled;

  /// Reads on an [ink] field.
  final Color onInk;

  /// The stitch hairline.
  final Color rule;

  /// A rule that has to divide rather than whisper.
  final Color ruleStrong;

  /// Marking-ink violet: the one interactive tint, on both roles' grounds.
  final Color tint;
  final Color tintPressed;

  /// The faintest wash of tint, for selected rows.
  final Color tintWash;
  final Color onTint;

  /// Thread red. Prohibition, failure, unpaid, destructive — nothing else.
  final Color signal;
  final Color signalWash;
  final Color onSignal;

  /// Hi-vis routing tag: the driver's field colour. One tone only — bands are
  /// separated by rule weight and inversion, never by a second yellow.
  final Color tag;
  final Color onTag;

  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  static const light = DesignColors(
    tape: Color(0xFFFBFBF9),
    tapeRecessed: Color(0xFFF2F2EE),
    tapeSunken: Color(0xFFE9E9E3),
    ink: Color(0xFF16181C),
    inkSecondary: Color(0xFF5E6068),
    inkTertiary: Color(0xFF6E7077),
    inkDisabled: Color(0xFF7C7E77),
    onInk: Color(0xFFFBFBF9),
    rule: Color(0xFFD8D6D0),
    ruleStrong: Color(0xFFB9B7AF),
    tint: Color(0xFF5B2D8E),
    tintPressed: Color(0xFF472170),
    tintWash: Color(0xFFF0E9F8),
    onTint: Color(0xFFFBFBF9),
    signal: Color(0xFFE0311F),
    signalWash: Color(0xFFFBE7E4),
    onSignal: Color(0xFFFBFBF9),
    tag: Color(0xFFCFE317),
    onTag: Color(0xFF16181C),
    brightness: Brightness.light,
  );

  static const dark = DesignColors(
    tape: Color(0xFF0E0F11),
    tapeRecessed: Color(0xFF17191C),
    tapeSunken: Color(0xFF212429),
    ink: Color(0xFFF2F2EE),
    inkSecondary: Color(0xFFA8AAB0),
    inkTertiary: Color(0xFF7E8087),
    inkDisabled: Color(0xFF6C7076),
    onInk: Color(0xFF0E0F11),
    rule: Color(0xFF2A2D31),
    ruleStrong: Color(0xFF3D4147),
    tint: Color(0xFFB18AE8),
    tintPressed: Color(0xFFC9AAF2),
    tintWash: Color(0xFF241A33),
    onTint: Color(0xFF0E0F11),
    signal: Color(0xFFFF6B57),
    signalWash: Color(0xFF3A1A15),
    onSignal: Color(0xFF0E0F11),
    tag: Color(0xFFCFE317),
    onTag: Color(0xFF16181C),
    brightness: Brightness.dark,
  );

  @override
  DesignColors copyWith({
    Color? tape,
    Color? tapeRecessed,
    Color? tapeSunken,
    Color? ink,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? inkDisabled,
    Color? onInk,
    Color? rule,
    Color? ruleStrong,
    Color? tint,
    Color? tintPressed,
    Color? tintWash,
    Color? onTint,
    Color? signal,
    Color? signalWash,
    Color? onSignal,
    Color? tag,
    Color? onTag,
    Brightness? brightness,
  }) {
    return DesignColors(
      tape: tape ?? this.tape,
      tapeRecessed: tapeRecessed ?? this.tapeRecessed,
      tapeSunken: tapeSunken ?? this.tapeSunken,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      inkDisabled: inkDisabled ?? this.inkDisabled,
      onInk: onInk ?? this.onInk,
      rule: rule ?? this.rule,
      ruleStrong: ruleStrong ?? this.ruleStrong,
      tint: tint ?? this.tint,
      tintPressed: tintPressed ?? this.tintPressed,
      tintWash: tintWash ?? this.tintWash,
      onTint: onTint ?? this.onTint,
      signal: signal ?? this.signal,
      signalWash: signalWash ?? this.signalWash,
      onSignal: onSignal ?? this.onSignal,
      tag: tag ?? this.tag,
      onTag: onTag ?? this.onTag,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  DesignColors lerp(ThemeExtension<DesignColors>? other, double t) {
    if (other is! DesignColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return DesignColors(
      tape: mix(tape, other.tape),
      tapeRecessed: mix(tapeRecessed, other.tapeRecessed),
      tapeSunken: mix(tapeSunken, other.tapeSunken),
      ink: mix(ink, other.ink),
      inkSecondary: mix(inkSecondary, other.inkSecondary),
      inkTertiary: mix(inkTertiary, other.inkTertiary),
      inkDisabled: mix(inkDisabled, other.inkDisabled),
      onInk: mix(onInk, other.onInk),
      rule: mix(rule, other.rule),
      ruleStrong: mix(ruleStrong, other.ruleStrong),
      tint: mix(tint, other.tint),
      tintPressed: mix(tintPressed, other.tintPressed),
      tintWash: mix(tintWash, other.tintWash),
      onTint: mix(onTint, other.onTint),
      signal: mix(signal, other.signal),
      signalWash: mix(signalWash, other.signalWash),
      onSignal: mix(onSignal, other.onSignal),
      tag: mix(tag, other.tag),
      onTag: mix(onTag, other.onTag),
      brightness: t < .5 ? brightness : other.brightness,
    );
  }
}

extension DesignColorsX on BuildContext {
  /// The palette for the current appearance.
  DesignColors get colors =>
      Theme.of(this).extension<DesignColors>() ?? DesignColors.light;
}
