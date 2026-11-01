// lib/pages/event_details_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../helpers/date_helpers.dart';
import '../helpers/error_helpers.dart';
import '../helpers/event_helpers.dart';
import '../helpers/maps_helper.dart';
import '../services/notification_service.dart';
import '../services/registration_service.dart';
import '../strings.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool isBusy = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>> get eventStream {
    return FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get registrationStream {
    return FirebaseFirestore.instance
        .collection('registrations')
        .doc(RegistrationService.documentId(uid, widget.eventId))
        .snapshots();
  }

  Future<void> register(Map<String, dynamic> event) async {
    setState(() {
      isBusy = true;
    });

    try {
      // Ask once, before the first reminder is scheduled.
      await NotificationService.requestPermission();
      await RegistrationService.register(uid: uid, eventId: widget.eventId);

      if (NotificationService.remindersAllowed) {
        await NotificationService.scheduleReminder(
          eventId: widget.eventId,
          eventName: event['name'] as String? ?? '',
          startAt: (event['startAt'] as Timestamp).toDate(),
          venueName: event['venueName'] as String? ?? '',
        );
      }

      if (mounted) {
        _showMessage(AppStrings.registrationSuccess);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> cancel(String eventName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.cancelRegistration),
          content: Text('${AppStrings.cancelConfirm} $eventName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.no),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.yes),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isBusy = true;
    });

    try {
      await RegistrationService.cancel(uid: uid, eventId: widget.eventId);
      await NotificationService.cancelReminder(widget.eventId);
      if (mounted) {
        _showMessage(AppStrings.cancelSuccess);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> toggleReminder(
    bool enabled,
    Map<String, dynamic> event,
  ) async {
    try {
      await RegistrationService.setReminder(
        uid: uid,
        eventId: widget.eventId,
        enabled: enabled,
      );

      if (enabled) {
        await NotificationService.scheduleReminder(
          eventId: widget.eventId,
          eventName: event['name'] as String? ?? '',
          startAt: (event['startAt'] as Timestamp).toDate(),
          venueName: event['venueName'] as String? ?? '',
        );
      } else {
        await NotificationService.cancelReminder(widget.eventId);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(readableError(error));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.eventDetails),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: eventStream,
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventSnapshot.hasError || !eventSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.couldNotLoadEvents),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          final event = eventSnapshot.data!.data();
          if (event == null) {
            return const Center(child: Text(AppStrings.eventCancelled));
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: registrationStream,
            builder: (context, regSnapshot) {
              final registration = regSnapshot.data?.data();
              final isRegistered = registration?['status'] == 'registered';
              return _buildContent(event, registration, isRegistered);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    Map<String, dynamic> event,
    Map<String, dynamic>? registration,
    bool isRegistered,
  ) {
    final startAt = (event['startAt'] as Timestamp).toDate();
    final endAt = (event['endAt'] as Timestamp).toDate();
    final capacity = (event['capacity'] as num?)?.toInt() ?? 0;
    final registeredCount = (event['registeredCount'] as num?)?.toInt() ?? 0;
    final ended = eventHasEnded(endAt);
    final full = eventIsFull(capacity, registeredCount);
    final geo = event['geo'] as GeoPoint?;
    final imageUrl = event['imageUrl'] as String? ?? '';

    return ListView(
      children: [
        if (imageUrl.isEmpty)
          Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.image_not_supported, size: 56),
          )
        else
          CachedNetworkImage(
            imageUrl: imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.image_not_supported, size: 56),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event['name'] as String? ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(
                    label: Text(
                      event['category'] as String? ??
                          AppStrings.unknownCategory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _iconRow(Icons.calendar_today_outlined, formatEventDate(startAt)),
              _iconRow(
                Icons.schedule,
                formatEventTimeRange(startAt, endAt),
              ),
              _iconRow(
                Icons.place_outlined,
                '${event['venueName'] ?? ''}\n${event['address'] ?? ''}',
              ),
              _iconRow(
                Icons.groups_outlined,
                _capacityLabel(capacity, registeredCount),
              ),
              _iconRow(
                Icons.person_outline,
                event['organizerName'] as String? ?? '',
              ),
              const SizedBox(height: 8),
              if (geo != null)
                OutlinedButton.icon(
                  onPressed: () => openInMaps(geo),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text(AppStrings.openInMaps),
                ),
              const SizedBox(height: 16),
              Text(
                AppStrings.description,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(event['description'] as String? ?? ''),
              const SizedBox(height: 24),
              if (isRegistered && !ended)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.reminder),
                  value: registration?['reminderEnabled'] != false,
                  onChanged: isBusy
                      ? null
                      : (value) => toggleReminder(value, event),
                ),
              if (isRegistered && !NotificationService.remindersAllowed)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(AppStrings.remindersOff),
                ),
              _buildActionButtons(ended, full, isRegistered, event),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    bool ended,
    bool full,
    bool isRegistered,
    Map<String, dynamic> event,
  ) {
    if (ended) {
      return const ElevatedButton(
        onPressed: null,
        child: Text(AppStrings.eventEnded),
      );
    }

    if (isRegistered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ElevatedButton(
            onPressed: null,
            child: Text(AppStrings.registered),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: isBusy
                ? null
                : () => cancel(event['name'] as String? ?? ''),
            child: const Text(AppStrings.cancelRegistration),
          ),
        ],
      );
    }

    if (full) {
      return const ElevatedButton(
        onPressed: null,
        child: Text(AppStrings.eventFull),
      );
    }

    return ElevatedButton(
      onPressed: isBusy ? null : () => register(event),
      child: isBusy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(AppStrings.register),
    );
  }

  String _capacityLabel(int capacity, int registeredCount) {
    final left = remainingSlots(capacity, registeredCount);
    if (left < 0) {
      return AppStrings.unlimitedSlots;
    }
    return '$left ${AppStrings.slotsLeft}';
  }

  Widget _iconRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
