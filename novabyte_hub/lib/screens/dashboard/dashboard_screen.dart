/// NovaByte Hub — Dashboard Screen
/// Real-time stats, recent pending requests, and quick actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_colors.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/gradient_card.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../models/license_request.dart';
import '../../providers/app_providers.dart';
import '../../router/app_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final pendingAsync = ref.watch(pendingRequestsProvider);
    final adminName = ref.watch(adminNameProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: pendingCount > 0
          ? FloatingActionButton.extended(
                  onPressed: () {
                    final pending = ref.read(pendingRequestsProvider);
                    pending.whenData((requests) {
                      if (requests.isNotEmpty) {
                        context.go('${AppRoutes.requests}/${requests.last.id}');
                      }
                    });
                  },
                  backgroundColor: AppColors.success,
                  icon: const Icon(LucideIcons.checkCircle, size: 20),
                  label: Text(
                    'Quick Approve',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 800.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0, delay: 800.ms, duration: 400.ms)
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(pendingRequestsProvider);
          ref.invalidate(adminNameProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName.when(
                          data: (name) => 'Welcome back, $name 👋',
                          loading: () => 'Welcome 👋',
                          error: (_, __) => 'Welcome 👋',
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 4),
                      Text(
                        'Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats Grid ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: statsAsync.when(
                  data: (stats) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                    children: [
                      StatCard(
                            label: 'Total Schools',
                            value: stats.totalSchools,
                            icon: LucideIcons.school,
                            gradient: AppColors.infoGradient,
                            onTap: () => context.go(AppRoutes.schools),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideX(
                            begin: -0.05,
                            end: 0,
                            delay: 200.ms,
                            duration: 500.ms,
                          ),
                      StatCard(
                            label: 'Pending Requests',
                            value: stats.pendingRequests,
                            icon: LucideIcons.clock,
                            gradient: AppColors.warningGradient,
                            onTap: () => context.go(AppRoutes.requests),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms)
                          .slideX(
                            begin: 0.05,
                            end: 0,
                            delay: 300.ms,
                            duration: 500.ms,
                          ),
                      StatCard(
                            label: 'Active Licenses',
                            value: stats.activeLicenses,
                            icon: LucideIcons.shieldCheck,
                            gradient: AppColors.successGradient,
                          )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideX(
                            begin: -0.05,
                            end: 0,
                            delay: 400.ms,
                            duration: 500.ms,
                          ),
                      StatCard(
                            label: 'Expiring Soon',
                            value: stats.expiringSoon,
                            icon: LucideIcons.alertTriangle,
                            gradient: AppColors.errorGradient,
                          )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 500.ms)
                          .slideX(
                            begin: 0.05,
                            end: 0,
                            delay: 500.ms,
                            duration: 500.ms,
                          ),
                    ],
                  ),
                  loading: () =>
                      const InlineLoader(message: 'Loading statistics...'),
                  error: (e, _) =>
                      _buildErrorCard('Failed to load stats', e.toString()),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Recent Pending Requests ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Requests',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go(AppRoutes.requests),
                      icon: const Text('View All'),
                      label: const Icon(LucideIcons.arrowRight, size: 16),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Pending List ──
            pendingAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GradientCard(
                        showBorder: false,
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.checkCircle2,
                              color: AppColors.success,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'All caught up!',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No pending license requests',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final displayRequests = requests.take(5).toList();
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: displayRequests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final request = displayRequests[index];
                      return _PendingRequestCard(request: request)
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 600 + (index * 80)),
                            duration: 400.ms,
                          )
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            delay: Duration(milliseconds: 600 + (index * 80)),
                            duration: 400.ms,
                          );
                    },
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: InlineLoader(message: 'Loading requests...'),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildErrorCard(
                    'Failed to load requests',
                    e.toString(),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title, String message) {
    return GradientCard(
      showBorder: false,
      child: Column(
        children: [
          Icon(LucideIcons.alertCircle, color: AppColors.error, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Card displaying a pending license request.
class _PendingRequestCard extends ConsumerWidget {
  final LicenseRequest request;

  const _PendingRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go('${AppRoutes.requests}/${request.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // School avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  request.schoolName.isNotEmpty
                      ? request.schoolName[0].toUpperCase()
                      : 'S',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.schoolName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${request.requestedModules.length} modules • ${request.packageType.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Time + badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const StatusBadge(status: 'pending', fontSize: 10),
                const SizedBox(height: 4),
                Text(
                  timeago.format(request.requestedAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
