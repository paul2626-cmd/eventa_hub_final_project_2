// lib/helpers/event_helpers.dart
// Small checks shared by the event list and the details screen.
bool eventHasEnded(DateTime endAt, {DateTime? now}) {
  return !endAt.isAfter(now ?? DateTime.now());
}

int remainingSlots(int capacity, int registeredCount) {
  if (capacity <= 0) {
    return -1; // -1 means unlimited
  }
  final left = capacity - registeredCount;
  return left < 0 ? 0 : left;
}

bool eventIsFull(int capacity, int registeredCount) {
  return capacity > 0 && registeredCount >= capacity;
}
