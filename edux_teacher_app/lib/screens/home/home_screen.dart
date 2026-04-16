/// EduX Teacher App - Home Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../classes/classes_screen.dart';
import '../settings/settings_screen.dart';
import '../sync/sync_screen.dart';
import 'home_content.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Refresh pending count on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider.notifier).refreshPendingCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);

    final screens = [
      const HomeContent(),
      const ClassesScreen(),
      const SyncScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: syncState.pendingCount > 0,
              label: Text('${syncState.pendingCount}'),
              child: const Icon(Icons.sync_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: syncState.pendingCount > 0,
              label: Text('${syncState.pendingCount}'),
              child: const Icon(Icons.sync),
            ),
            label: 'Sync',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// AppBar for home screen
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  const HomeAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(currentTeacherProvider);
    final syncState = ref.watch(syncProvider);

    return AppBar(
      title: Text(title),
      actions: [
        // Sync indicator
        if (syncState.pendingCount > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pending_outlined,
                    size: 16,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${syncState.pendingCount}',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Profile
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => _showProfileMenu(context, ref),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryLight,
              backgroundImage: teacher?.photoUrl != null
                  ? NetworkImage(teacher!.photoUrl!)
                  : null,
              child: teacher?.photoUrl == null
                  ? Text(
                      teacher?.name.substring(0, 1).toUpperCase() ?? 'T',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
