/// EduX School Management System
/// Dashboard Screen - Main overview with live data
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/core.dart';
import '../../providers/dashboard_provider.dart';
import '../../router/app_router.dart';
import '../../services/license_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/rbac_service.dart';
import 'widgets/widgets.dart';
import '../../providers/school_settings_provider.dart';

/// Main dashboard screen with live statistics, charts, and quick actions
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.read(dashboardProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    final canViewFees = rbacService.hasPermission(user, RbacService.viewFees);
    final canViewStaff = rbacService.hasPermission(user, RbacService.viewStaff);
    final canManageFees = rbacService.hasPermission(
      user,
      RbacService.manageFees,
    );
    final canManageStaff = rbacService.hasPermission(
      user,
      RbacService.manageStaff,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child:
            dashboardState.isLoading &&
                dashboardState.stats.totalStudents == 0 &&
                dashboardState.stats.totalStaff == 0
            ? const Center(child: CircularProgressIndicator())
            : dashboardState.error != null
            ? _buildErrorState(context, ref, dashboardState.error!)
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: AppTheme.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page header
                        _buildHeader(context),
                        const SizedBox(height: 24),

                        // Stats cards
                        _buildStatsSection(
                          dashboardState.stats,
                          constraints.maxWidth,
                          canViewFees,
                          canViewStaff,
                        ),
                        const SizedBox(height: 24),

                        // Charts row
                        _buildChartsSection(
                          dashboardState,
                          constraints.maxWidth,
                          canViewFees,
                        ),
                        const SizedBox(height: 24),

                        // Quick actions, alerts, and activity
                        _buildBottomSection(
                          context,
                          dashboardState,
                          constraints.maxWidth,
                          canManageFees,
                          canManageStaff,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy').format(now);

    // Watch school settings for school name
    final schoolSettingsAsync = ref.watch(schoolSettingsProvider);
    final schoolName = schoolSettingsAsync.when(
      data: (settings) => settings?.schoolName ?? 'EduX School System',
      loading: () => 'Loading...',
      error: (_, __) => 'EduX School System',
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(schoolName, style: AppTextStyles.pageTitle),
            const SizedBox(height: 4),
            Text(
              dateFormatted,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<bool>(
              future: LicenseService.instance.isModuleAccessible('reporting'),
              builder: (context, snapshot) {
                final isAccessible = snapshot.data ?? false;
                return OutlinedButton.icon(
                  onPressed: isAccessible
                      ? () => context.push('/reports')
                      : () => _showModuleLockedDialog(context, 'reporting'),
                  icon: Icon(
                    LucideIcons.fileText,
                    size: 18,
                    color: isAccessible ? null : AppColors.textDisabled,
                  ),
                  label: Text(
                    'Reports',
                    style: TextStyle(
                      color: isAccessible ? null : AppColors.textDisabled,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showQuickAddMenu(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Quick Add'),
            ),
          ],
        ),
      ],
    );
  }

  void _showQuickAddMenu(BuildContext context) async {
    final route = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 20, 0),
      items: [
        _buildMenuItem(
          'Add Student',
          LucideIcons.userPlus,
          '/students/new',
          'student_management',
        ),
        _buildMenuItem(
          'Add Staff',
          LucideIcons.userCog,
          '/staff/new',
          'staff_management',
        ),
        _buildMenuItem(
          'Collect Fee',
          LucideIcons.banknote,
          '/fees',
          'fee_management',
        ),
        _buildMenuItem(
          'Mark Attendance',
          LucideIcons.calendarCheck,
          '/attendance',
          'attendance_tracking',
        ),
      ],
    );
    if (route != null && context.mounted) {
      _navigateWithLicenseCheck(context, route, _getModuleIdFromRoute(route));
    }
  }

  String? _getModuleIdFromRoute(String route) {
    if (route.startsWith('/students')) return 'student_management';
    if (route.startsWith('/staff')) return 'staff_management';
    if (route.startsWith('/fees')) return 'fee_management';
    if (route.startsWith('/attendance')) return 'attendance_tracking';
    if (route.startsWith('/exams')) return 'exam_management';
    if (route.startsWith('/reports')) return 'reporting';
    if (route.startsWith('/expenses')) return 'expense_tracking';
    if (route.startsWith('/canteen')) return 'canteen_management';
    if (route.startsWith('/academics')) return 'academic_management';
    return null;
  }

  Future<void> _navigateWithLicenseCheck(
    BuildContext context,
    String route,
    String? moduleId,
  ) async {
    if (moduleId == null) {
      context.push(route);
      return;
    }

    final isAccessible = await LicenseService.instance.isModuleAccessible(
      moduleId,
    );
    if (!context.mounted) return;

    if (isAccessible) {
      context.push(route);
    } else {
      // Show locked message
      _showModuleLockedDialog(context, moduleId);
    }
  }

  void _showModuleLockedDialog(BuildContext context, String moduleId) {
    final module = EduXModules.byId(moduleId);
    final moduleName = module?.name ?? 'This feature';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(LucideIcons.lock, color: AppColors.error, size: 48),
        title: Text('$moduleName Locked'),
        content: Text(
          'This feature requires an active license. Please request a license to unlock this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.requestLicense);
            },
            child: const Text('Request License'),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String label,
    IconData icon,
    String route,
    String moduleId,
  ) {
    return PopupMenuItem(
      value: route,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          FutureBuilder<bool>(
            future: LicenseService.instance.isModuleAccessible(moduleId),
            builder: (context, snapshot) {
              final isAccessible = snapshot.data ?? false;
              if (isAccessible) return const SizedBox.shrink();
              return Icon(LucideIcons.lock, size: 14, color: AppColors.error);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    DashboardStats stats,
    double maxWidth,
    bool canViewFees,
    bool canViewStaff,
  ) {
    int visibleCount = 2 + (canViewFees ? 1 : 0) + (canViewStaff ? 1 : 0);
    // Responsive grid layout
    int crossAxisCount = 4;
    double childAspectRatio = 1.3;
    double mainAxisSpacing = 16;
    double crossAxisSpacing = 16;

    if (maxWidth < 600) {
      crossAxisCount = 1;
      childAspectRatio = 2.0; // Taller for mobile
    } else if (maxWidth < 1100) {
      crossAxisCount = visibleCount < 2 ? visibleCount : 2;
      childAspectRatio = 1.6;
    } else {
      crossAxisCount = visibleCount < 4 ? visibleCount : 4;
      childAspectRatio = 1.3;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
      children: [
        _StatCard(
          title: 'Total Students',
          value: NumberFormat('#,###').format(stats.totalStudents),
          icon: LucideIcons.users,
          color: AppColors.info,
          trend: '+${stats.newStudentsThisMonth} this month',
        ),
        if (canViewStaff)
          _StatCard(
            title: 'Staff Members',
            value: '${stats.totalStaff}',
            icon: LucideIcons.userCog,
            color: AppColors.secondary,
            trend: '${stats.activeTeachers} teachers',
          ),
        if (canViewFees)
          _StatCard(
            title: 'Fee Collected',
            value: stats.feeCollectedFormatted,
            icon: LucideIcons.banknote,
            color: AppColors.success,
            trend: _getFeeCollectionTrend(stats),
          ),
        _StatCard(
          title: 'Attendance Today',
          value: stats.attendancePercentage,
          icon: LucideIcons.calendarCheck,
          color: AppColors.accent,
          trend: '${stats.presentToday}/${stats.totalEnrolledToday} present',
        ),
      ],
    );
  }

  String _getFeeCollectionTrend(DashboardStats stats) {
    final trend = stats.feeCollectionTrend;
    if (trend == 0) return 'This month';
    final sign = trend > 0 ? '+' : '';
    return '$sign${trend.toStringAsFixed(0)}% vs last month';
  }

  Widget _buildChartsSection(
    DashboardState state,
    double maxWidth,
    bool canViewFees,
  ) {
    final bool isMobile = maxWidth < 900;

    if (isMobile) {
      return Column(
        children: [
          _buildChartCard(
            'Attendance Trend',
            LucideIcons.trendingUp,
            AppColors.primary,
            'Last 7 days',
            AttendanceChart(data: state.attendanceTrend),
          ),
          const SizedBox(height: 16),
          if (canViewFees) ...[
            _buildChartCard(
              'Fee Collection',
              LucideIcons.barChart3,
              AppColors.success,
              'Last 6 months',
              FeeCollectionChart(data: state.feeCollectionTrend),
            ),
            const SizedBox(height: 16),
          ],
          _buildChartCard(
            'Class Distribution',
            LucideIcons.pieChart,
            AppColors.info,
            'Students by class',
            ClassDistributionChart(data: state.classDistribution),
          ),
          const SizedBox(height: 16),
          if (canViewFees) ...[
            _buildChartCard(
              'Financial Overview',
              LucideIcons.barChart2,
              AppColors.warning,
              'Last 7 days',
              ProfitLossChart(data: state.profitLossData),
            ),
            const SizedBox(height: 16),
          ],
          _buildChartCard(
            'Student Admissions',
            LucideIcons.userPlus,
            AppColors.primary,
            'Monthly trend',
            AdmissionsChart(data: state.admissionTrend),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildChartCard(
                'Attendance Trend',
                LucideIcons.trendingUp,
                AppColors.primary,
                'Last 7 days',
                AttendanceChart(data: state.attendanceTrend),
              ),
            ),
            const SizedBox(width: 16),
            if (canViewFees) ...[
              Expanded(
                flex: 4,
                child: _buildChartCard(
                  'Fee Collection',
                  LucideIcons.barChart3,
                  AppColors.success,
                  'Last 6 months',
                  FeeCollectionChart(data: state.feeCollectionTrend),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 3,
              child: _buildChartCard(
                'Class Distribution',
                LucideIcons.pieChart,
                AppColors.info,
                'Students by class',
                ClassDistributionChart(data: state.classDistribution),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canViewFees) ...[
              Expanded(
                flex: 2,
                child: _buildChartCard(
                  'Financial Overview',
                  LucideIcons.barChart2,
                  AppColors.warning,
                  'Year ${DateTime.now().year}',
                  ProfitLossChart(data: state.profitLossData),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: _buildChartCard(
                'Student Admissions',
                LucideIcons.userPlus,
                AppColors.primary,
                'Admission Trends',
                AdmissionsChart(data: state.admissionTrend),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    Widget chart,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.sectionTitle),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    DashboardState state,
    double maxWidth,
    bool canManageFees,
    bool canManageStaff,
  ) {
    if (maxWidth < 900) {
      return Column(
        children: [
          const SyncStatusCard(),
          const SizedBox(height: 16),
          _buildQuickActionsSection(context, canManageFees, canManageStaff),
          const SizedBox(height: 16),
          _buildAlertsSection(state.alerts),
          const SizedBox(height: 16),
          _buildRecentActivitySection(state),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const SyncStatusCard(),
              const SizedBox(height: 16),
              _buildQuickActionsSection(context, canManageFees, canManageStaff),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildAlertsSection(state.alerts)),
        const SizedBox(width: 16),
        Expanded(child: _buildRecentActivitySection(state)),
      ],
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    bool canManageFees,
    bool canManageStaff,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              children: [
                _QuickActionTile(
                  icon: LucideIcons.userPlus,
                  label: 'Add Student',
                  color: AppColors.info,
                  moduleId: 'student_management',
                  onTap: () => _navigateWithLicenseCheck(
                    context,
                    '/students/new',
                    'student_management',
                  ),
                ),
                _QuickActionTile(
                  icon: LucideIcons.calendarCheck,
                  label: 'Mark Attendance',
                  color: AppColors.success,
                  moduleId: 'attendance_tracking',
                  onTap: () => _navigateWithLicenseCheck(
                    context,
                    '/attendance',
                    'attendance_tracking',
                  ),
                ),
                if (canManageFees)
                  _QuickActionTile(
                    icon: LucideIcons.receipt,
                    label: 'Collect Fee',
                    color: AppColors.secondary,
                    moduleId: 'fee_management',
                    onTap: () => _navigateWithLicenseCheck(
                      context,
                      '/fees',
                      'fee_management',
                    ),
                  ),
                _QuickActionTile(
                  icon: LucideIcons.clipboardList,
                  label: 'Enter Marks',
                  color: AppColors.accent,
                  moduleId: 'exam_management',
                  onTap: () => _navigateWithLicenseCheck(
                    context,
                    '/exams',
                    'exam_management',
                  ),
                ),
                _QuickActionTile(
                  icon: LucideIcons.printer,
                  label: 'Print Report',
                  color: AppColors.primary,
                  moduleId: 'reporting',
                  onTap: () => _navigateWithLicenseCheck(
                    context,
                    '/reports',
                    'reporting',
                  ),
                ),
                if (canManageStaff) ...[
                  _QuickActionTile(
                    icon: LucideIcons.userCog,
                    label: 'Add Staff',
                    color: AppColors.textSecondary,
                    moduleId: 'staff_management',
                    onTap: () => _navigateWithLicenseCheck(
                      context,
                      '/staff/new',
                      'staff_management',
                    ),
                  ),
                  _QuickActionTile(
                    icon: LucideIcons.bookOpen,
                    label: 'Assignments',
                    color: AppColors.primary,
                    moduleId: 'staff_management',
                    onTap: () => _navigateWithLicenseCheck(
                      context,
                      '/staff/assignments',
                      'staff_management',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(List<DashboardAlert> alerts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(LucideIcons.bell, size: 20, color: AppColors.warning),
                const SizedBox(width: 8),
                Text('Alerts', style: AppTextStyles.sectionTitle),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SingleChildScrollView(
                child: AlertsSection(alerts: alerts),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(DashboardState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.activity,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Recent Activity', style: AppTextStyles.sectionTitle),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SingleChildScrollView(
                child: ActivityFeed(activities: state.recentActivity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.statValue),
            const SizedBox(height: 4),
            Text(
              trend,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? moduleId;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: moduleId != null
          ? LicenseService.instance.isModuleAccessible(moduleId!)
          : Future.value(true),
      builder: (context, snapshot) {
        final isAccessible = snapshot.data ?? false;
        final isLocked = moduleId != null && !isAccessible;

        return Material(
          color: isLocked
              ? AppColors.surfaceVariant.withValues(alpha: 0.5)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? AppColors.textDisabled.withValues(alpha: 0.2)
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          icon,
                          color: isLocked ? AppColors.textDisabled : color,
                          size: 20,
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Icon(
                              LucideIcons.lock,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isLocked
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
