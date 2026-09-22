import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens/design_colors.dart';
import '../tokens/design_metrics.dart';
import '../tokens/design_typography.dart';

/// The Care Label theme, in both appearances.
///
/// Light is the default because the driver works outdoors in Gulf sun and the
/// tape has to stay readable there; dark is a first-class appearance for the
/// customer booking a collection at night.
abstract final class AppTheme {
  static ThemeData light() => _build(DesignColors.light);

  static ThemeData dark() => _build(DesignColors.dark);

  static ThemeData _build(DesignColors c) {
    final text = DesignTypography.textTheme(c.ink);
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.tint,
      onPrimary: c.onTint,
      secondary: c.ink,
      onSecondary: c.onInk,
      error: c.signal,
      onError: c.onSignal,
      surface: c.tape,
      onSurface: c.ink,
      surfaceContainerHighest: c.tapeRecessed,
      outline: c.rule,
      outlineVariant: c.ruleStrong,
    );

    InputBorder rule(Color color, double width) => UnderlineInputBorder(
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.tape,
      canvasColor: c.tape,
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      extensions: [c],

      // iOS navigation everywhere: push slides, sheets rise, dismiss reverses.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: c.brightness,
        primaryColor: c.tint,
        scaffoldBackgroundColor: c.tape,
        barBackgroundColor: c.tape,
        applyThemeToAll: true,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: c.tape,
        foregroundColor: c.ink,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.tint, size: 22),
        actionsIconTheme: IconThemeData(color: c.tint, size: 22),
      ),

      dividerTheme: DividerThemeData(
        color: c.rule,
        thickness: DesignRule.hair,
        space: DesignRule.hair,
      ),

      iconTheme: IconThemeData(color: c.ink, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(vertical: DesignSpace.md),
        hintStyle: text.bodyLarge?.copyWith(color: c.inkTertiary),
        labelStyle: DesignTypography.stamp(c.inkSecondary),
        floatingLabelStyle: DesignTypography.stamp(c.tint),
        errorStyle: text.labelLarge?.copyWith(color: c.signal),
        border: rule(c.rule, DesignRule.hair),
        enabledBorder: rule(c.rule, DesignRule.hair),
        focusedBorder: rule(c.tint, DesignRule.heavy),
        errorBorder: rule(c.signal, DesignRule.hair),
        focusedErrorBorder: rule(c.signal, DesignRule.heavy),
        disabledBorder: rule(c.rule, DesignRule.hair),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.tint,
        selectionColor: c.tint.withValues(alpha: .24),
        selectionHandleColor: c.tint,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.ink,
        linearTrackColor: c.tapeSunken,
        circularTrackColor: const Color(0x00000000),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.tape,
        surfaceTintColor: const Color(0x00000000),
        showDragHandle: true,
        dragHandleColor: c.ruleStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignRadius.sheet),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.bodySmall?.copyWith(color: c.onInk),
        actionTextColor: c.tag,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(DesignRadius.panel)),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.tape),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.tint : c.ruleStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Color(0x00000000)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.tint : c.ruleStrong,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.tint
              : const Color(0x00000000),
        ),
        side: BorderSide(color: c.ruleStrong, width: DesignRule.medium),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.tint,
          textStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size(0, DesignSpace.touchTarget),
        ),
      ),
    );
  }
}
