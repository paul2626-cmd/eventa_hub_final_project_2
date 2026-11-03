// lib/pages/my_events_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helpers/date_helpers.dart';
import '../helpers/error_helpers.dart';
import '../services/notification_service.dart';
import '../services/registration_service.dart';
import 'event_details_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key, this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> registrationsStream;
  late Stream<Set<String>> ongoingEventIdsStream;

  @override
  void initState() {
    super.initState();
    registrationsStream = newRegistrationsStream();
    ongoingEventIdsStream = newOngoingEventIdsStream();
  }

  // Live list of events that have not ended yet. Registrations store a copy of
  // the old end date, so the Upcoming/History split must use the event itself.
  Stream<Set<String>> newOngoingEventIdsStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .where('endAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> newRegistrationsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('registrations')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'registered')
        .orderBy('eventEndAt')
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: registrationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Could not load events.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              registrationsStream = newRegistrationsStream();
                              ongoingEventIdsStream = newOngoingEventIdsStream();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                return StreamBuilder<Set<String>>(
                  stream: ongoingEventIdsStream,
                  builder: (context, ongoingSnapshot) {
                    if (ongoingSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final ongoingIds = ongoingSnapshot.data ?? <String>{};
                    final upcoming = _upcoming(docs, ongoingIds);
                    final history = _history(docs, ongoingIds);

                    return TabBarView(
                      children: [_buildUpcoming(upcoming), _buildHistory(history)],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _upcoming(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Set<String> ongoingIds,
  ) {
    final result =
        docs.where((doc) {
          final eventId = doc.data()['eventId'] as String? ?? '';
          return ongoingIds.contains(eventId);
        }).toList()..sort((a, b) {
          final aStart = (a.data()['eventStartAt'] as Timestamp).toDate();
          final bStart = (b.data()['eventStartAt'] as Timestamp).toDate();
          return aStart.compareTo(bStart);
        });
    return result;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _history(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Set<String> ongoingIds,
  ) {
    final result =
        docs.where((doc) {
          final eventId = doc.data()['eventId'] as String? ?? '';
          return !ongoingIds.contains(eventId);
        }).toList()..sort((a, b) {
          final aEnd = (a.data()['eventEndAt'] as Timestamp).toDate();
          final bEnd = (b.data()['eventEndAt'] as Timestamp).toDate();
          return bEnd.compareTo(aEnd);
        });
    return result;
  }

  Widget _buildUpcoming(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_available, size: 56),
              const SizedBox(height: 12),
              const Text("You haven't registered for any events yet.", textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: widget.onBrowse,
                child: const Text('Browse events'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data();
        final startAt = (data['eventStartAt'] as Timestamp).toDate();
        final eventId = data['eventId'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDetails(eventId),
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 110,
                    child: _cardImage(context, eventId, data['eventImageUrl'] as String? ?? ''),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['eventName'] as String? ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('${formatEventDate(startAt)} • ${formatEventTime(startAt)}'),
                          Text('${data['venueName'] ?? ''} • ${countdownLabel(startAt)}'),
                          Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined),
                                tooltip: 'Cancel Registration',
                                onPressed: () => _cancel(data),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistory(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text('No past events yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data();
        final startAt = (data['eventStartAt'] as Timestamp).toDate();

        final eventId = data['eventId'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDetails(eventId),
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 110,
                    child: _cardImage(context, eventId, data['eventImageUrl'] as String? ?? ''),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['eventName'] as String? ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('${formatEventDate(startAt)} • ${data['venueName'] ?? ''}'),
                          Text(data['category'] as String? ?? 'Uncategorized'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Reads the image live from the event, so old registrations stay current.
  Widget _cardImage(BuildContext context, String eventId, String savedImageUrl) {
    if (eventId.isEmpty) {
      return _imageBox(context, savedImageUrl);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('events').doc(eventId).snapshots(),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data?.data()?['imageUrl'] as String? ?? savedImageUrl;
        return _imageBox(context, imageUrl);
      },
    );
  }

  Widget _imageBox(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 110,
        height: 160,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 110,
      height: 160,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 110,
        height: 160,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
    );
  }

  void _openDetails(String eventId) {
    if (eventId.isEmpty) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailsPage(eventId: eventId)),
    );
  }

  Future<void> _cancel(Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Registration'),
          content: Text('Cancel your registration for ${data['eventName'] ?? ''}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final eventId = data['eventId'] as String? ?? '';

    try {
      await RegistrationService.cancel(uid: uid, eventId: eventId);
      await NotificationService.cancelReminder(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Registration cancelled.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(readableError(error))));
      }
    }
  }
}
