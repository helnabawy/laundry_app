import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

/// Locale-aware display formatting. Digits stay Western (as in the designs);
/// only words (weekday, month, AM/PM, currency) are localized.
class AppFormat {
  AppFormat(this._l10n) : _locale = _l10n.localeName;

  factory AppFormat.of(BuildContext context) => AppFormat(context.l10n);

  final AppLocalizations _l10n;
  final String _locale;

  String money(double amount) {
    final isWhole = amount == amount.roundToDouble();
    return _l10n.currencyAed(amount.toStringAsFixed(isWhole ? 0 : 2));
  }

  /// `4:00 م` / `4:00 PM`
  String time(DateTime t, {bool withPeriod = true}) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minutes = t.minute.toString().padLeft(2, '0');
    return withPeriod ? '$hour:$minutes ${_period(t)}' : '$hour:$minutes';
  }

  /// `4:00 - 6:00 م`
  String timeRange(DateTime start, DateTime end) =>
      '${time(start, withPeriod: false)} - ${time(end)}';

  String weekday(DateTime d) => DateFormat.EEEE(_locale).format(d);

  String month(DateTime d) => DateFormat.MMMM(_locale).format(d);

  /// `اليوم` / `غدًا` / weekday name.
  String relativeDay(DateTime d, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final diff = DateUtils.dateOnly(d).difference(today).inDays;
    if (diff == 0) return _l10n.today;
    if (diff == 1) return _l10n.tomorrow;
    return weekday(d);
  }

  /// `الأحد 12 · 4:00 - 6:00 م`
  String slotWithDate(DateTime start, DateTime end) =>
      '${weekday(start)} ${start.day} · ${timeRange(start, end)}';

  /// `غدًا 4:00 - 6:00 م`
  String slotRelative(DateTime start, DateTime end) =>
      '${relativeDay(start)} ${timeRange(start, end)}';

  /// `الأحد 3:12 م`
  String dayAndTime(DateTime d) => '${weekday(d)} ${time(d)}';

  String _period(DateTime t) => t.hour < 12 ? _l10n.am : _l10n.pm;
}
