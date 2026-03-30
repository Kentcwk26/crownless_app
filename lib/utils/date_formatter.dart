import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static String _locale(BuildContext context) {
    return context.locale.toString();
  }

    /// dd/MM/yyyy
  static String shortDate(BuildContext context, DateTime date) {
    return DateFormat('dd/MM/yyyy', _locale(context)).format(date);
  }

  /// dd/MM/yyyy (EEEE)
  static String fullDate(BuildContext context, DateTime date) {
    return DateFormat('dd/MM/yyyy (EEEE)', _locale(context)).format(date);
  }

  /// dd/MM/yyyy (EEEE) hh:mm:ss aa
  static String fullDateTime(BuildContext context, DateTime date) {
    return DateFormat('dd/MM/yyyy (EEEE) hh:mm:ss aa', _locale(context))
        .format(date);
  }

  /// dd/MM/yyyy hh:mm aa
  static String shortDateTime(BuildContext context, DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm aa', _locale(context)).format(date);
  }

  /// hh:mm:ss aa
  static String format12HourMinuteSeconds(BuildContext context, DateTime date) {
    return DateFormat('hh:mm:ss aa', _locale(context)).format(date);
  }

  /// HH:mm (24-hour)
  static String format24Hour(BuildContext context, DateTime date) {
    return DateFormat('HH:mm', _locale(context)).format(date);
  }

  /// Timestamp wrappers
  static String formatDateTime(BuildContext context, Timestamp timestamp) {
    return fullDateTime(context, timestamp.toDate());
  }

  static String formatShortDate(BuildContext context, Timestamp timestamp) {
    return shortDate(context, timestamp.toDate());
  }

  static String formatLongDate(BuildContext context, Timestamp timestamp) {
    return fullDate(context, timestamp.toDate());
  }

  static String format12Hour(BuildContext context, DateTime date) {
    return DateFormat.jm(_locale(context)).format(date);
  }

  static String formatTimestamp(BuildContext context, Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (_isSameDay(now, date)) {
      return format12Hour(context, date);
    } else if (diff.inDays < 7) {
      return DateFormat.E(_locale(context)).format(date);
    } else {
      return DateFormat.MMMd(_locale(context)).format(date);
    }
  }

  static String timeAgo(
    BuildContext context,
    Timestamp timestamp, {
    bool short = false,
  }) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 10) {
      return 'just_now'.tr();
    }

    if (diff.inMinutes < 1) {
      return 'just_now'.tr();
    }

    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return short
          ? 'mins_short'.plural(minutes, args: [minutes.toString()])
          : 'minutes_ago'.plural(minutes, args: [minutes.toString()]);
    }

    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return short
          ? 'hrs_short'.plural(hours, args: [hours.toString()])
          : 'hours_ago'.plural(hours, args: [hours.toString()]);
    }

    if (diff.inDays == 1) {
      return 'yesterday'.tr();
    }

    if (diff.inDays < 7) {
      final days = diff.inDays;
      return short
          ? 'days_short'.plural(days, args: [days.toString()])
          : 'days_ago'.plural(days, args: [days.toString()]);
    }

    return shortDate(context, date);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}