// lib/services/registration_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../helpers/event_helpers.dart';

// All reads and writes for the `registrations` collection.
class RegistrationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String documentId(String uid, String eventId) {
    return '${uid}_$eventId';
  }

  // Register in a transaction so two students cannot take the last slot.
  static Future<void> register({
    required String uid,
    required String eventId,
  }) async {
    final eventRef = _db.collection('events').doc(eventId);
    final regRef = _db.collection('registrations').doc(documentId(uid, eventId));

    await _db.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw Exception('This event is no longer available.');
      }

      final event = eventSnapshot.data()!;
      final endAt = (event['endAt'] as Timestamp).toDate();
      final capacity = (event['capacity'] as num?)?.toInt() ?? 0;
      final registeredCount = (event['registeredCount'] as num?)?.toInt() ?? 0;

      if (eventHasEnded(endAt)) {
        throw Exception('This event has already ended.');
      }
      if (eventIsFull(capacity, registeredCount)) {
        throw Exception('Event is full.');
      }

      final regSnapshot = await transaction.get(regRef);
      if (regSnapshot.exists && regSnapshot.data()?['status'] == 'registered') {
        throw Exception('You are already registered.');
      }

      final startAt = (event['startAt'] as Timestamp).toDate();
      final reminderAt = startAt.subtract(const Duration(minutes: 60));

      transaction.set(regRef, {
        'userId': uid,
        'eventId': eventId,
        'eventName': event['name'] ?? '',
        'eventStartAt': event['startAt'],
        'eventEndAt': event['endAt'],
        'eventImageUrl': event['imageUrl'] ?? '',
        'venueName': event['venueName'] ?? '',
        'category': event['category'] ?? '',
        'status': 'registered',
        'registeredAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
        'reminderEnabled': true,
        'reminderAt':
            reminderAt.isAfter(DateTime.now()) ? Timestamp.fromDate(reminderAt) : null,
      });

      transaction.update(eventRef, {
        'registeredCount': FieldValue.increment(1),
      });
    });
  }

  // Soft delete: keep the document but mark it cancelled and free the slot.
  static Future<void> cancel({
    required String uid,
    required String eventId,
  }) async {
    final eventRef = _db.collection('events').doc(eventId);
    final regRef = _db.collection('registrations').doc(documentId(uid, eventId));

    await _db.runTransaction((transaction) async {
      // Firestore needs every read before the first write.
      final regSnapshot = await transaction.get(regRef);
      final eventSnapshot = await transaction.get(eventRef);

      if (!regSnapshot.exists || regSnapshot.data()?['status'] != 'registered') {
        return;
      }

      transaction.update(regRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'reminderEnabled': false,
        'reminderAt': null,
      });

      final registeredCount =
          (eventSnapshot.data()?['registeredCount'] as num?)?.toInt() ?? 0;
      if (eventSnapshot.exists && registeredCount > 0) {
        transaction.update(eventRef, {
          'registeredCount': FieldValue.increment(-1),
        });
      }
    });
  }

  // Used by the reminder toggle on the details screen.
  static Future<void> setReminder({
    required String uid,
    required String eventId,
    required bool enabled,
  }) async {
    await _db
        .collection('registrations')
        .doc(documentId(uid, eventId))
        .update({'reminderEnabled': enabled});
  }
}
