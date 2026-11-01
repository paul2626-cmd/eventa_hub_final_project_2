// lib/pages/profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../strings.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text(AppStrings.appName));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.account_circle, size: 80),
        const SizedBox(height: 8),
        Text(
          user.displayName ?? AppStrings.profileTab,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          user.email ?? '',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Profile document from Firestore (kept in sync with sign up).
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final lead = data?['reminderLeadMinutes'] ?? 60;
            return ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(AppStrings.reminderLead(lead as int)),
            );
          },
        ),
        FutureBuilder<bool>(
          future: NotificationService.areEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? true;
            return ListTile(
              leading: Icon(
                enabled ? Icons.notifications : Icons.notifications_off,
              ),
              title: Text(
                enabled ? AppStrings.notificationsOn : AppStrings.notificationsOff,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text(AppStrings.logout),
        ),
      ],
    );
  }
}
