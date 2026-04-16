/// NovaByte Hub — Requests Screen (Phase 4)
/// Real-time list with tab filtering, search, swipe actions, sort, counter badges.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/app_constants.dart';
import '../../core/constants/module_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../models/license_request.dart';
import '../../providers/app_providers.dart';
import '../../router/app_router.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  String? _selectedFilter;
  String _searchQuery = '';
  bool _sortNewest = true;
  bool _isProcessing = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(filteredRequestsProvider(_selectedFilter));
    final statusCounts = ref.watch(requestCountByStatusProvider);

    return LoadingOverlay(
      isLoading: _isProcessing,
      message: 'Processing...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverAppBar(
              expandedHeight: 64,
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              title: Text(
                'License Requests',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [
                // Sort toggle
                IconButton(
                  onPressed: () => setState(() => _sortNewest = !_sortNewest),
                  icon: Icon(
                    _sortNewest
                        ? LucideIcons.arrowDownUp
                        : LucideIcons.arrowUpDown,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: _sortNewest
                      ? 'Showing newest first'
                      : 'Showing oldest first',
                ),
              ],
            ),

            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by school name...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              color: AppColors.textSecondary,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Filter Tabs with Counter Badges ──
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: statusCounts['all'] ?? 0,
                      isSelected: _selectedFilter == null,
                      onTap: () => setState(() => _selectedFilter = null),
                    ),
                    ...RequestStatus.all.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: RequestStatus.getDisplayName(status),
                          count: statusCounts[status] ?? 0,
                          isSelected: _selectedFilter == status,
                          color: AppColors.getStatusColor(status),
                          onTap: () => setState(() => _selectedFilter = status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Request List ──
            requestsAsync.when(
              data: (requests) {
                // Apply search filter
                var filtered = requests;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where((r) => r.schoolName.toLowerCase().contains(q))
                      .toList();
                }

                // Apply sort
                if (!_sortNewest) {
                  filtered = List.from(filtered.reversed);
                }

                if (filtered.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final req = filtered[index];
                      return _buildDismissibleCard(req, index);
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: InlineLoader(message: 'Loading requests...'),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: AppColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load requests',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.toString(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

  /// Swipeable card wrapper — only for pending requests
  Widget _buildDismissibleCard(LicenseRequest req, int index) {
    final card = _RequestCard(request: req)
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 40),
          duration: 350.ms,
        )
        .slideY(
          begin: 0.03,
          end: 0,
          delay: Duration(milliseconds: index * 40),
          duration: 350.ms,
        );

    if (!req.isPending) return card;

    return Dismissible(
      key: ValueKey(req.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right → Quick approve
          return await _quickApprove(req);
        } else {
          // Swipe left → Quick reject
          return await _quickReject(req);
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: AppColors.success, size: 24),
            const SizedBox(width: 8),
            Text(
              'Approve',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Reject',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.xCircle, color: AppColors.error, size: 24),
          ],
        ),
      ),
      child: card,
    );
  }

  /// Quick approve: approve with all requested modules and default 365-day expiry
  Future<bool> _quickApprove(LicenseRequest req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: AppColors.success, size: 22),
            const SizedBox(width: 10),
            Text(
              'Quick Approve',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Approve "${req.schoolName}" with all ${req.requestedModules.length} requested modules and a 1-year license?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    setState(() => _isProcessing = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final adminUid = authService.getAdminUid() ?? '';
      final defaultDays = ref.read(defaultLicenseDurationProvider);

      await firestoreService.approveRequest(
        requestId: req.id,
        schoolId: req.schoolId,
        approvedModules: req.requestedModules,
        expiryDate: DateTime.now().add(Duration(days: defaultDays)),
        adminUid: adminUid,
      );

      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text('${req.schoolName} approved'),
              ],
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Quick reject: reject with an optional reason
  Future<bool> _quickReject(LicenseRequest req) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.xCircle, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            Text(
              'Reject Request',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject "${req.schoolName}"?',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: reasonController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Payment not received',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    setState(() => _isProcessing = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final adminUid = authService.getAdminUid() ?? '';

      await firestoreService.rejectRequest(
        requestId: req.id,
        adminUid: adminUid,
        rejectionReason: reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : null,
      );

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  LucideIcons.xCircle,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text('${req.schoolName} rejected'),
              ],
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildEmptyState() {
    final isFiltered = _selectedFilter != null || _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? LucideIcons.searchX : LucideIcons.inbox,
              color: AppColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No matching requests' : 'No requests yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Try a different filter or search term'
                  : 'License requests from schools will appear here',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter chip with animated counter badge.
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? chipColor : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.3)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? chipColor : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Request card with status-colored left border.
class _RequestCard extends StatelessWidget {
  final LicenseRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(request.status);

    return GestureDetector(
      onTap: () => context.go('${AppRoutes.requests}/${request.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Status-colored left border
            Container(
              width: 4,
              height: 100,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: school name + status
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.getStatusGradient(
                              request.status,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              request.schoolName.isNotEmpty
                                  ? request.schoolName[0].toUpperCase()
                                  : 'S',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.schoolName,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'ID: ${request.schoolId}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: request.status, fontSize: 10),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Module chips row (horizontal scroll)
                    SizedBox(
                      height: 24,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: request.requestedModules.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, idx) {
                          final modId = request.requestedModules[idx];
                          final mod = EduXModules.getById(modId);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (mod?.color ?? AppColors.primary)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              mod?.name ?? modId,
                              style: TextStyle(
                                color: mod?.color ?? AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Bottom row: package type + time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.box,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              PackageType.getDisplayName(request.packageType),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}
