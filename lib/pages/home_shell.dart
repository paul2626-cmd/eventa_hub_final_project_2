// lib/pages/home_shell.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../navbar_drawer/navbar_menu.dart';
import '../services/notification_service.dart';
import '../strings.dart';
import 'event_list_page.dart';
import 'my_events_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;

  late final List<Widget> pages = [
    const EventListPage(),
    MyEventsPage(onBrowse: () {
      setState(() {
        selectedIndex = 0;
      });
    }),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    syncReminders();
  }

  // Re-sync reminders on launch: add missing ones, remove stale ones.
  Future<void> syncReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('registrations')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'registered')
          .limit(50)
          .get();
      await NotificationService.resync(snapshot.docs);
    } catch (_) {
      // Offline or permission error: reminders keep their current state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.retry,
            onPressed: syncReminders,
          ),
        ],
      ),
      drawer: NavbarMenu(
        onOpenProfile: () {
          setState(() {
            selectedIndex = 2;
          });
        },
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: AppStrings.eventsTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: AppStrings.myEventsTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profileTab,
          ),
        ],
      ),
    );
  }

  String _title() {
    if (selectedIndex == 1) {
      return AppStrings.myEventsTab;
    }
    if (selectedIndex == 2) {
      return AppStrings.profileTab;
    }
    return AppStrings.appName;
  }
}
