// lib/navbar_drawer/navbar_menu.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

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
                  user?.displayName ?? AppStrings.profileTab,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(user?.email ?? ''),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text(AppStrings.profileTab),
            onTap: () {
              Navigator.pop(context); // close the drawer first
              onOpenProfile();
            },
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text(AppStrings.darkMode),
                value: mode == ThemeMode.dark,
                onChanged: (value) {
                  setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(AppStrings.logout),
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
