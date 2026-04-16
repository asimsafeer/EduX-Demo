/// EduX School Management System
/// App Shell - Main navigation shell with sidebar
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

import 'dart:io';
import '../../core/core.dart';
import '../../router/app_router.dart';
import '../../services/license_service.dart';
import '../../sync/server/server.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../sync/providers/providers.dart';
import '../../services/rbac_service.dart';

/// App shell with sidebar navigation
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isExpanded = true;
  int _selectedIndex = 0;
  final SyncServerManager _syncServerManager = SyncServerManager();

  final List<_NavItem> _navItems = [
    const _NavItem(
      icon: LucideIcons.layoutDashboard,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    const _NavItem(
      icon: LucideIcons.users,
      label: 'Students',
      route: AppRoutes.students,
      permission: RbacService.viewStudents,
      moduleId: 'student_management',
    ),
    const _NavItem(
      icon: LucideIcons.userCog,
      label: 'Staff',
      route: AppRoutes.staff,
      permission: RbacService.viewStaff,
      moduleId: 'staff_management',
    ),
    const _NavItem(
      icon: LucideIcons.school,
      label: 'Classes',
      route: AppRoutes.classes,
      permission: RbacService.viewAcademics,
      moduleId: 'academic_management',
    ),
    const _NavItem(
      icon: LucideIcons.calendarCheck,
      label: 'Attendance',
      route: AppRoutes.attendance,
      permission: RbacService.viewAttendance,
      moduleId: 'attendance_tracking',
    ),
    const _NavItem(
      icon: LucideIcons.clipboardList,
      label: 'Exams',
      route: AppRoutes.exams,
      permission: RbacService.viewExams,
      moduleId: 'exam_management',
    ),
    const _NavItem(
      icon: LucideIcons.receipt,
      label: 'Fees',
      route: AppRoutes.fees,
      permission: RbacService.viewFees,
      moduleId: 'fee_management',
    ),
    const _NavItem(
      icon: LucideIcons.barChart3,
      label: 'Reports',
      route: AppRoutes.reports,
      permission: RbacService.viewReports,
      moduleId: 'reporting',
    ),
    const _NavItem(
      icon: LucideIcons.wallet,
      label: 'Expenses',
      route: AppRoutes.expenses,
      permission: RbacService.viewExpenses,
      moduleId: 'expense_tracking',
    ),
    const _NavItem(
      icon: LucideIcons.store,
      label: 'Canteen',
      route: AppRoutes.canteen,
      permission: RbacService.viewCanteen,
      moduleId: 'canteen_management',
    ),
    const _NavItem(
      icon: LucideIcons.settings,
      label: 'Settings',
      route: AppRoutes.settings,
      permission: RbacService.viewSettings,
    ),
  ];

  // Cache the license status to avoid repeated async checks
  AppLicenseStatus? _licenseStatus;
  LicenseData? _licenseData;

  @override
  void initState() {
    super.initState();
    _loadLicenseStatus();
    _autoStartSyncServer();
  }

  Future<void> _loadLicenseStatus() async {
    final status = await LicenseService.instance.getAppStatus();
    final data = await LicenseService.instance.getLicenseData();
    if (mounted) {
      setState(() {
        _licenseStatus = status;
        _licenseData = data;
      });
    }
  }

  /// Auto-start sync server for teacher app connections
  Future<void> _autoStartSyncServer() async {
    try {
      // Check if server is already running
      if (!_syncServerManager.isServerRunning) {
        await _syncServerManager.start();
        debugPrint('Sync server auto-started successfully');
      }
    } catch (e) {
      // Don't show error to user, just log it
      debugPrint('Failed to auto-start sync server: $e');
    }
  }

  bool _isModuleLocked(String? moduleId) {
    if (moduleId == null) return false;

    // During pending request, all modules are unlocked
    if (_licenseStatus == AppLicenseStatus.pendingRequest) {
      return false;
    }

    // With valid license, check specific module approval
    if (_licenseStatus == AppLicenseStatus.licensed) {
      return !(_licenseData?.hasModule(moduleId) ?? false);
    }

    // Expired - lock all modules
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        setState(() => _selectedIndex = i);
        return;
      }
    }
  }

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to background sync events to refresh UI
    ref.listen(syncEventsProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        // A background sync occurred. Invalidate UI data.
        ref.invalidate(dashboardProvider);
        ref.invalidate(classAttendanceProvider);
        ref.invalidate(dailySummaryProvider);
        ref.invalidate(isAttendanceMarkedProvider);
        ref.invalidate(todayUnmarkedClassesProvider);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom title bar
          _buildTitleBar(),

          // Main content with responsive sidebar
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Auto-collapse sidebar on narrow widths
                final shouldCollapse = ResponsiveHelper.shouldCollapseSidebar(
                  constraints.maxWidth,
                );
                if (shouldCollapse && _isExpanded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isExpanded = false);
                  });
                }

                return Row(
                  children: [
                    // Sidebar
                    _buildSidebar(),

                    // Main content area
                    Expanded(child: widget.child),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        color: AppColors.sidebarBackground,
        child: Row(
          children: [
            SizedBox(width: Platform.isMacOS ? 80 : 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/icon.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),

            // Window controls (Hide on macOS as we use native ones)
            if (!Platform.isMacOS) ...[
              _WindowButton(
                icon: LucideIcons.minus,
                onPressed: () => windowManager.minimize(),
              ),
              _WindowButton(
                icon: LucideIcons.square,
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              _WindowButton(
                icon: LucideIcons.x,
                onPressed: () => windowManager.close(),
                isClose: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 240 : 72,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Toggle button
          _buildToggleButton(),

          const SizedBox(height: 16),

          // Navigation items
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final user = ref.watch(currentUserProvider);
                final rbacService = ref.watch(rbacServiceProvider);

                // Filter items based on permissions
                final visibleItems = _navItems.where((item) {
                  if (item.permission == null) return true;
                  return rbacService.hasPermission(user, item.permission!);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];

                    // Find original index for selection state (since we filtered the list)
                    final originalIndex = _navItems.indexOf(item);
                    final isSelected = _selectedIndex == originalIndex;

                    // Add divider before Settings if it's the last item and not the only item
                    if (item.route == AppRoutes.settings &&
                        visibleItems.length > 1) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Divider(
                              color: AppColors.textOnDark.withValues(
                                alpha: 0.1,
                              ),
                              height: 1,
                            ),
                          ),
                          _buildNavItem(item, isSelected, originalIndex),
                        ],
                      );
                    }

                    return _buildNavItem(item, isSelected, originalIndex);
                  },
                );
              },
            ),
          ),

          // User section
          _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: _isExpanded
                ? MainAxisAlignment.end
                : MainAxisAlignment.center,
            children: [
              Icon(
                _isExpanded
                    ? LucideIcons.panelLeftClose
                    : LucideIcons.panelLeft,
                color: AppColors.textOnDark.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, int index) {
    final isLocked = _isModuleLocked(item.moduleId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.label} requires an active license.'),
                  action: SnackBarAction(
                    label: 'Request',
                    onPressed: () => context.go(AppRoutes.requestLicense),
                  ),
                ),
              );
              return;
            }
            _navigateTo(index);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 0),
            decoration: BoxDecoration(
              color: isSelected && !isLocked
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isLocked
                          ? AppColors.textOnDark.withValues(alpha: 0.3)
                          : isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textOnDark.withValues(alpha: 0.7),
                    ),
                    if (isLocked)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Icon(
                          LucideIcons.lock,
                          size: 10,
                          color: AppColors.textOnDark.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTextStyles.navItem.copyWith(
                        color: isLocked
                            ? AppColors.textOnDark.withValues(alpha: 0.3)
                            : isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textOnDark.withValues(alpha: 0.7),
                        fontWeight: isSelected && !isLocked
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isLocked)
                    Icon(
                      LucideIcons.lock,
                      size: 14,
                      color: AppColors.textOnDark.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.fullName ?? 'User';
    final roleName = user != null
        ? UserRoles.getDisplayName(user.role)
        : 'Guest';
    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              avatarLetter,
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    roleName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.logOut,
                size: 18,
                color: AppColors.textOnDark.withValues(alpha: 0.6),
              ),
              onPressed: () async {
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

                if (confirm == true && mounted) {
                  // Clear session and state
                  await ref.read(currentUserProvider.notifier).logout();

                  if (mounted) {
                    context.go(AppRoutes.login);
                  }
                }
              },
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final String? permission;
  final String? moduleId;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.permission,
    this.moduleId,
  });
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: _isHovered
              ? (widget.isClose
                    ? Colors.red
                    : Colors.white.withValues(alpha: 0.1))
              : Colors.transparent,
          child: Icon(widget.icon, size: 16, color: AppColors.textOnDark),
        ),
      ),
    );
  }
}
