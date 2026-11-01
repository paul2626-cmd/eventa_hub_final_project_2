import 'package:eventa_hub_final_project_2/helpers/date_helpers.dart';
import 'package:eventa_hub_final_project_2/helpers/event_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('countdownLabel says Today for the same day', () {
    final now = DateTime(2026, 11, 1, 8);
    expect(countdownLabel(DateTime(2026, 11, 1, 19), now: now), 'Today');
  });

  test('countdownLabel says Tomorrow for the next day', () {
    final now = DateTime(2026, 11, 1, 8);
    expect(countdownLabel(DateTime(2026, 11, 2, 9), now: now), 'Tomorrow');
  });

  test('countdownLabel counts the days', () {
    final now = DateTime(2026, 11, 1, 8);
    expect(countdownLabel(DateTime(2026, 11, 4, 9), now: now), 'In 3 days');
  });

  test('eventHasEnded compares the end time', () {
    final now = DateTime(2026, 11, 1, 8);
    expect(eventHasEnded(DateTime(2026, 11, 1, 7), now: now), isTrue);
    expect(eventHasEnded(DateTime(2026, 11, 1, 9), now: now), isFalse);
  });

  test('remainingSlots handles unlimited, free and full events', () {
    expect(remainingSlots(0, 10), -1);
    expect(remainingSlots(20, 3), 17);
    expect(remainingSlots(20, 20), 0);
  });

  test('eventIsFull needs a capacity and a reached count', () {
    expect(eventIsFull(0, 100), isFalse);
    expect(eventIsFull(5, 5), isTrue);
    expect(eventIsFull(5, 4), isFalse);
  });
}
