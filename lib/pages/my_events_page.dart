// lib/pages/my_events_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helpers/date_helpers.dart';
import '../helpers/error_helpers.dart';
import '../services/notification_service.dart';
import '../services/registration_service.dart';
import '../strings.dart';
import 'event_details_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key, this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> registrationsStream;

  @override
  void initState() {
    super.initState();
    registrationsStream = newRegistrationsStream();
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
              Tab(text: AppStrings.upcomingTab),
              Tab(text: AppStrings.historyTab),
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
                        const Text(AppStrings.couldNotLoadEvents),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              registrationsStream = newRegistrationsStream();
                            });
                          },
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final upcoming = _upcoming(docs);
                final history = _history(docs);

                return TabBarView(children: [_buildUpcoming(upcoming), _buildHistory(history)]);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _upcoming(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result =
        docs.where((doc) {
          final endAt = (doc.data()['eventEndAt'] as Timestamp).toDate();
          return endAt.isAfter(DateTime.now());
        }).toList()..sort((a, b) {
          final aStart = (a.data()['eventStartAt'] as Timestamp).toDate();
          final bStart = (b.data()['eventStartAt'] as Timestamp).toDate();
          return aStart.compareTo(bStart);
        });
    return result;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _history(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result =
        docs.where((doc) {
          final endAt = (doc.data()['eventEndAt'] as Timestamp).toDate();
          return !endAt.isAfter(DateTime.now());
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
              const Text(AppStrings.noRegistrations, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: widget.onBrowse,
                child: const Text(AppStrings.browseEvents),
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
                                tooltip: AppStrings.cancelRegistration,
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
      return const Center(child: Text(AppStrings.noHistory));
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
                          Text(data['category'] as String? ?? AppStrings.unknownCategory),
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
          title: const Text(AppStrings.cancelRegistration),
          content: Text('${AppStrings.cancelConfirm} ${data['eventName'] ?? ''}?'),
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

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final eventId = data['eventId'] as String? ?? '';

    try {
      await RegistrationService.cancel(uid: uid, eventId: eventId);
      await NotificationService.cancelReminder(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(AppStrings.cancelSuccess)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(readableError(error))));
      }
    }
  }
}
