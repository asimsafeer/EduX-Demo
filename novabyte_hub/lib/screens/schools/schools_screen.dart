/// NovaByte Hub — Schools Screen (Phase 4)
/// Real-time list with search, license status dots, module count, sort options.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../models/school.dart';
import '../../models/license.dart';
import '../../providers/app_providers.dart';
import '../../router/app_router.dart';

enum _SortMode { newest, nameAZ, expiringSoon }

class SchoolsScreen extends ConsumerStatefulWidget {
  const SchoolsScreen({super.key});

  @override
  ConsumerState<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends ConsumerState<SchoolsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(allSchoolsProvider);

    return Scaffold(
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
              'Schools',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              PopupMenuButton<_SortMode>(
                icon: Icon(
                  LucideIcons.arrowDownUp,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                color: AppColors.surface,
                onSelected: (mode) => setState(() => _sortMode = mode),
                itemBuilder: (context) => [
                  _buildSortItem(
                    _SortMode.newest,
                    'Newest First',
                    LucideIcons.clock,
                  ),
                  _buildSortItem(
                    _SortMode.nameAZ,
                    'Name A–Z',
                    LucideIcons.arrowDownAZ,
                  ),
                  _buildSortItem(
                    _SortMode.expiringSoon,
                    'Expiring Soon',
                    LucideIcons.alertTriangle,
                  ),
                ],
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
                    hintText: 'Search by name, city, or ID...',
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
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── School List ──
          schoolsAsync.when(
            data: (schools) {
              // Apply search
              var filtered = schools;
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                filtered = filtered
                    .where(
                      (s) =>
                          s.schoolName.toLowerCase().contains(q) ||
                          (s.city?.toLowerCase().contains(q) ?? false) ||
                          s.schoolId.toLowerCase().contains(q),
                    )
                    .toList();
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
                    final school = filtered[index];
                    return _EnhancedSchoolCard(
                      school: school,
                      sortMode: _sortMode,
                    )
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
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: InlineLoader(message: 'Loading schools...'),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  PopupMenuItem<_SortMode> _buildSortItem(
    _SortMode mode,
    String label,
    IconData icon,
  ) {
    final isActive = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? LucideIcons.searchX : LucideIcons.school,
              color: AppColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No matching schools' : 'No schools registered',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Schools will appear here after installing EduX',
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

/// Enhanced school card with license status dot, module count, and expiry date.
class _EnhancedSchoolCard extends ConsumerWidget {
  final School school;
  final _SortMode sortMode;

  const _EnhancedSchoolCard({required this.school, required this.sortMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for license data to show status dot
    final licenseAsync = ref.watch(watchLicenseProvider(school.schoolId));

    return GestureDetector(
      onTap: () => context.go('${AppRoutes.schools}/${school.schoolId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Avatar with status dot
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      school.schoolName.isNotEmpty
                          ? school.schoolName[0].toUpperCase()
                          : 'S',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Status dot
                Positioned(
                  right: -2,
                  top: -2,
                  child: licenseAsync.when(
                    data: (license) => _buildStatusDot(license),
                    loading: () =>
                        _buildStatusDot(null, color: AppColors.textMuted),
                    error: (_, __) =>
                        _buildStatusDot(null, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // School info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.schoolName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (school.city != null && school.city!.isNotEmpty) ...[
                        Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          school.city!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        school.schoolId,
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
                  const SizedBox(height: 4),
                  // Module count and expiry
                  licenseAsync.when(
                    data: (license) {
                      if (license == null) {
                        return Text(
                          'No license',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${license.approvedModules.length} modules',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expires ${DateFormat('MMM d').format(license.expiresAt)}',
                            style: TextStyle(
                              color: license.isExpiringSoon
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(License? license, {Color? color}) {
    Color dotColor;
    if (color != null) {
      dotColor = color;
    } else if (license == null) {
      dotColor = AppColors.textMuted; // ⚪ No license
    } else if (!license.isActive) {
      dotColor = AppColors.error; // 🔴 Expired/Revoked
    } else if (license.isExpiringSoon) {
      dotColor = AppColors.warning; // 🟡 Expiring soon
    } else if (license.isValid) {
      dotColor = AppColors.success; // 🟢 Active
    } else {
      dotColor = AppColors.error; // 🔴 Expired
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: [
          BoxShadow(color: dotColor.withValues(alpha: 0.4), blurRadius: 4),
        ],
      ),
    );
  }
}
