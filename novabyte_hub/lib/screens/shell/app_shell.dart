/// NovaByte Hub — App Shell with Bottom Navigation (Phase 4)
/// Premium dark glassmorphism bottom nav + notification initialization on first load.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../router/app_router.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _notificationsInitialized = false;

  static const _tabs = [
    _TabItem(
      icon: LucideIcons.layoutDashboard,
      activeIcon: LucideIcons.layoutDashboard,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    _TabItem(
      icon: LucideIcons.inbox,
      activeIcon: LucideIcons.inbox,
      label: 'Requests',
      route: AppRoutes.requests,
    ),
    _TabItem(
      icon: LucideIcons.school,
      activeIcon: LucideIcons.school,
      label: 'Schools',
      route: AppRoutes.schools,
    ),
    _TabItem(
      icon: LucideIcons.settings,
      activeIcon: LucideIcons.settings,
      label: 'Settings',
      route: AppRoutes.settings,
    ),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;

    final notificationsEnabled = ref.read(notificationEnabledProvider);
    if (!notificationsEnabled) return;

    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize(
        onNotificationTap: (requestId) {
          if (requestId != null && requestId.isNotEmpty && mounted) {
            context.go('${AppRoutes.requests}/$requestId');
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final pendingCount = ref.watch(pendingCountProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isActive = index == currentIndex;
                final showBadge = index == 1 && pendingCount > 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (index != currentIndex) {
                        context.go(tab.route);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isActive ? tab.activeIcon : tab.icon,
                                size: 22,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              if (showBadge)
                                Positioned(
                                  right: -8,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.error.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      pendingCount > 99
                                          ? '99+'
                                          : pendingCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
