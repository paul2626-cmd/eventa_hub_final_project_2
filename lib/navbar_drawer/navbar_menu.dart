// lib/navbar_drawer/navbar_menu.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NavbarMenu extends StatelessWidget {
  const NavbarMenu({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.event, size: 40),
                const SizedBox(height: 8),
                Text(
                  user?.displayName ?? 'Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(user?.email ?? ''),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              onOpenProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
