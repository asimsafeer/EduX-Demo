/// NovaByte Hub — School Detail Screen
/// Full school info, license status, module management, and request history.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants/module_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/module_chip.dart';
import '../../core/widgets/gradient_card.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../models/license.dart';
import '../../providers/app_providers.dart';
import '../../router/app_router.dart';

class SchoolDetailScreen extends ConsumerStatefulWidget {
  final String schoolId;

  const SchoolDetailScreen({super.key, required this.schoolId});

  @override
  ConsumerState<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends ConsumerState<SchoolDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(schoolDetailProvider(widget.schoolId));
    final licenseAsync = ref.watch(watchLicenseProvider(widget.schoolId));
    final requestsAsync = ref.watch(schoolRequestsProvider(widget.schoolId));

    return LoadingOverlay(
      isLoading: _isProcessing,
      message: 'Processing...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'School Details',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: schoolAsync.when(
          data: (school) {
            if (school == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.building2,
                      color: AppColors.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'School not found',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── School Header ──
                  Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E2A5E), AppColors.surface],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  school.schoolName.isNotEmpty
                                      ? school.schoolName[0].toUpperCase()
                                      : 'S',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    school.schoolName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (school.city != null &&
                                      school.city!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.mapPin,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          school.city!,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.03, end: 0, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ── School Info ──
                  _buildSectionTitle('School Information'),
                  const SizedBox(height: 10),
                  GradientCard(
                    showBorder: false,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          LucideIcons.hash,
                          'School ID',
                          school.schoolId,
                          copyable: true,
                        ),
                        _buildDivider(),
                        if (school.email != null &&
                            school.email!.isNotEmpty) ...[
                          _buildInfoRow(
                            LucideIcons.mail,
                            'Email',
                            school.email!,
                          ),
                          _buildDivider(),
                        ],
                        if (school.phone != null &&
                            school.phone!.isNotEmpty) ...[
                          _buildInfoRow(
                            LucideIcons.phone,
                            'Phone',
                            school.phone!,
                          ),
                          _buildDivider(),
                        ],
                        _buildInfoRow(
                          LucideIcons.smartphone,
                          'Device ID',
                          school.deviceId.isNotEmpty
                              ? school.deviceId
                              : 'Not recorded',
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          LucideIcons.calendar,
                          'Installed',
                          DateFormat('MMM d, yyyy').format(school.installedAt),
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          LucideIcons.calendarPlus,
                          'Registered',
                          DateFormat('MMM d, yyyy').format(school.createdAt),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── License Section ──
                  _buildSectionTitle('License'),
                  const SizedBox(height: 10),
                  licenseAsync.when(
                    data: (license) {
                      if (license == null) {
                        return GradientCard(
                          showBorder: false,
                          child: Column(
                            children: [
                              Icon(
                                LucideIcons.shieldOff,
                                color: AppColors.textMuted,
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Active License',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This school does not have a license yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return _buildLicenseCard(license);
                    },
                    loading: () =>
                        const InlineLoader(message: 'Loading license...'),
                    error: (e, _) => Text(
                      'Error: $e',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Request History ──
                  _buildSectionTitle('Request History'),
                  const SizedBox(height: 10),
                  requestsAsync.when(
                    data: (requests) {
                      if (requests.isEmpty) {
                        return GradientCard(
                          showBorder: false,
                          child: Center(
                            child: Text(
                              'No requests from this school',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: List.generate(requests.length, (index) {
                          final req = requests[index];
                          final isLast = index == requests.length - 1;
                          final statusColor = AppColors.getStatusColor(
                            req.status,
                          );

                          return GestureDetector(
                            onTap: () =>
                                context.go('${AppRoutes.requests}/${req.id}'),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline line + dot
                                SizedBox(
                                  width: 30,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isLast)
                                        Container(
                                          width: 2,
                                          height: 64,
                                          color: AppColors.border,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'MMM d, yyyy',
                                                ).format(req.requestedAt),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              StatusBadge(
                                                status: req.status,
                                                fontSize: 9,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${req.requestedModules.length} modules • ${req.packageType}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (req.reviewedBy != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Reviewed by: ${req.reviewedBy}',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    },
                    loading: () =>
                        const InlineLoader(message: 'Loading history...'),
                    error: (e, _) => Text(
                      'Error: $e',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () =>
              const InlineLoader(message: 'Loading school details...'),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.alertCircle, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Error: $e',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseCard(License license) {
    final statusStr = license.isValid
        ? (license.isExpiringSoon ? 'expiring' : 'active')
        : 'expired';

    return GradientCard(
      showBorder: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: statusStr, fontSize: 12),
              Text(
                '${license.daysRemaining} days left',
                style: TextStyle(
                  color: license.isExpiringSoon
                      ? AppColors.warning
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Expiry progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: license.expiryProgress,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                license.isExpiringSoon ? AppColors.warning : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // Dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateChip(
                'Granted',
                DateFormat('MMM d, yyyy').format(license.grantedAt),
              ),
              _buildDateChip(
                'Expires',
                DateFormat('MMM d, yyyy').format(license.expiresAt),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Granted by admin
          if (license.grantedBy.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.userCheck,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Granted by: ${license.grantedBy}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Modules
          Text(
            'Licensed Modules (${license.approvedModules.length})',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: license.approvedModules
                .map((id) => ModuleChip(moduleId: id, isSelected: true))
                .toList(),
          ),

          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showExtendDialog(license),
                  icon: const Icon(LucideIcons.calendarPlus, size: 16),
                  label: const Text('Extend'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showModifyModulesDialog(license),
                  icon: const Icon(LucideIcons.settings2, size: 16),
                  label: const Text('Modules'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: license.isActive
                      ? () => _showRevokeDialog()
                      : null,
                  icon: Icon(
                    LucideIcons.shieldOff,
                    size: 16,
                    color: license.isActive
                        ? AppColors.error
                        : AppColors.textMuted,
                  ),
                  label: Text(
                    'Revoke',
                    style: TextStyle(
                      color: license.isActive
                          ? AppColors.error
                          : AppColors.textMuted,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: license.isActive
                          ? AppColors.error.withValues(alpha: 0.5)
                          : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildDateChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: copyable ? 'monospace' : null,
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    backgroundColor: AppColors.surface,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(
                LucideIcons.copy,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: AppColors.border.withValues(alpha: 0.4), height: 1);
  }

  // ── EXTEND LICENSE DIALOG ──
  void _showExtendDialog(License license) {
    var newExpiry = license.expiresAt.add(const Duration(days: 365));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Extend License',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current expiry: ${DateFormat('MMMM d, yyyy').format(license.expiresAt)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: newExpiry,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary,
                                surface: AppColors.surface,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => newExpiry = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMMM d, yyyy').format(newExpiry),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _extendLicense(newExpiry);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirm Extension',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── MODIFY MODULES DIALOG ──
  void _showModifyModulesDialog(License license) {
    final selectedModules = List<String>.from(license.approvedModules);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Modify Modules',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedModules.length} of ${EduXModules.allIds.length} modules selected',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EduXModules.allIds.map((id) {
                          return ModuleToggleChip(
                            moduleId: id,
                            isSelected: selectedModules.contains(id),
                            onChanged: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedModules.add(id);
                                } else {
                                  selectedModules.remove(id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedModules.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              _updateModules(selectedModules);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: AppColors.accent.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        selectedModules.isEmpty
                            ? 'Select at least 1 module'
                            : 'Save Changes (${selectedModules.length} modules)',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── REVOKE DIALOG ──
  void _showRevokeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            Text(
              'Revoke License',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will deactivate the license for this school. They will lose access to all licensed modules immediately.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _revokeLicense();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  // ── ACTION HANDLERS ──

  Future<void> _extendLicense(DateTime newExpiry) async {
    setState(() => _isProcessing = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final adminUid = authService.getAdminUid() ?? '';
      await firestoreService.extendLicense(
        schoolId: widget.schoolId,
        newExpiryDate: newExpiry,
        adminUid: adminUid,
      );
      if (mounted) {
        _showSuccessSnackbar('License extended successfully');
        ref.invalidate(watchLicenseProvider(widget.schoolId));
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateModules(List<String> modules) async {
    setState(() => _isProcessing = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final adminUid = authService.getAdminUid() ?? '';
      await firestoreService.updateLicenseModules(
        schoolId: widget.schoolId,
        modules: modules,
        adminUid: adminUid,
      );
      if (mounted) {
        _showSuccessSnackbar('Modules updated successfully');
        ref.invalidate(watchLicenseProvider(widget.schoolId));
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _revokeLicense() async {
    setState(() => _isProcessing = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final adminUid = authService.getAdminUid() ?? '';
      await firestoreService.revokeLicense(widget.schoolId, adminUid: adminUid);
      if (mounted) {
        _showSuccessSnackbar('License revoked');
        ref.invalidate(watchLicenseProvider(widget.schoolId));
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessSnackbar(String message) {
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
            Text(message),
          ],
        ),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}
