// lib/helpers/date_helpers.dart
import 'package:intl/intl.dart';

// "Wed, Nov 12, 2026"
String formatEventDate(DateTime date) {
  return DateFormat('EEE, MMM d, yyyy').format(date);
}

// "7:30 PM"
String formatEventTime(DateTime date) {
  return DateFormat('h:mm a').format(date);
}

// "7:30 PM – 9:00 PM"
String formatEventTimeRange(DateTime startAt, DateTime endAt) {
  return '${formatEventTime(startAt)} – ${formatEventTime(endAt)}';
}

// Today / Tomorrow / "In 3 days"
String countdownLabel(DateTime startAt, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final startDay = DateTime(startAt.year, startAt.month, startAt.day);
  final currentDay = DateTime(today.year, today.month, today.day);
  final days = startDay.difference(currentDay).inDays;

  if (days == 0) {
    return 'Today';
  }
  if (days == 1) {
    return 'Tomorrow';
  }
  return 'In $days days';
}
