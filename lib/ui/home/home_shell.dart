import 'package:flutter/material.dart';

import '../../config/locale_controller.dart';
import '../profile/profile_screen.dart';
import '../record/record_screen.dart';
import 'feed_screen.dart';

/// Bottom-nav shell: Startseite · Entdecken · Aufnehmen · Profil (matches the
/// mockups' tab bar; the record tab is the amber accent).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    FeedScreen(),
    FeedScreen(),
    RecordScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: s.navHome),
          NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: s.navDiscover),
          NavigationDestination(
              icon: const Icon(Icons.mic_none),
              selectedIcon: const Icon(Icons.mic),
              label: s.navRecord),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: s.navProfile),
        ],
      ),
    );
  }
}
