// lib/pages/event_list_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../helpers/date_helpers.dart';
import 'event_details_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  static const categories = [
    'All',
    'Academic',
    'Sports',
    'Seminar',
    'Organization',
    'Entertainment',
  ];

  String selectedCategory = 'All';
  late Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream;

  // Set from a real server read, so the banner never guesses from metadata.
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    eventsStream = newEventsStream();
    checkConnection();
  }

  // Source.server skips the cache, so a failure here means really offline.
  Future<void> checkConnection() async {
    try {
      await FirebaseFirestore.instance.collection('events').limit(1).get(
        const GetOptions(source: Source.server),
      );
      if (mounted) {
        setState(() {
          isOffline = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isOffline = true;
        });
      }
    }
  }

  // Only upcoming events, soonest first, capped at 50 documents.
  Stream<QuerySnapshot<Map<String, dynamic>>> newEventsStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .where('endAt', isGreaterThan: Timestamp.now())
        .orderBy('endAt')
        .orderBy('startAt')
        .limit(50)
        .snapshots();
  }

  Future<void> refresh() async {
    setState(() {
      eventsStream = newEventsStream();
    });
    await checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Center(
                child: ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: eventsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildError();
              }

              final allDocs = snapshot.data?.docs ?? [];
              final docs = allDocs.where((doc) {
                if (selectedCategory == 'All') {
                  return true;
                }
                return doc.data()['category'] == selectedCategory;
              }).toList()
                ..sort((a, b) {
                  final startA = (a.data()['startAt'] as Timestamp).toDate();
                  final startB = (b.data()['startAt'] as Timestamp).toDate();
                  return startA.compareTo(startB);
                });

              return Column(
                children: [
                  if (isOffline)
                    GestureDetector(
                      onTap: checkConnection,
                      child: Container(
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          'You are offline. Showing saved events.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (docs.isEmpty)
                    Expanded(child: _buildEmpty())
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            return _buildEventCard(docs[index]);
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 8),
          const Text('Could not load events.'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 56),
            const SizedBox(height: 12),
            Text(
              'No upcoming events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Check back later for new school events.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final event = doc.data();
    final startAt = (event['startAt'] as Timestamp).toDate();
    final imageUrl = event['imageUrl'] as String? ?? '';
    final category = event['category'] as String? ?? 'Uncategorized';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsPage(eventId: doc.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(imageUrl),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event['name'] as String? ?? '',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text(category),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatEventDate(startAt)} • ${formatEventTime(startAt)}',
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(event['venueName'] as String? ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _placeholderImage();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 160,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported, size: 48),
    );
  }
}
