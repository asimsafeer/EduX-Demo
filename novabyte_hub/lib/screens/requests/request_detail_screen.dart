/// NovaByte Hub — Request Detail Screen (Phase 4)
/// Full request info with school details, module grid, expiry shortcuts, haptic feedback.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/app_constants.dart';
import '../../core/constants/module_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/module_chip.dart';
import '../../core/widgets/gradient_card.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../providers/app_providers.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(requestDetailProvider(widget.requestId));

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
            'Request Detail',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: requestAsync.when(
          data: (request) {
            if (request == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.inbox,
                      color: AppColors.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Request not found',
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
                  // ── Hero Header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.getStatusColor(
                            request.status,
                          ).withValues(alpha: 0.15),
                          AppColors.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.getStatusColor(
                          request.status,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.getStatusGradient(
                              request.status,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              request.schoolName.isNotEmpty
                                  ? request.schoolName[0].toUpperCase()
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
                                request.schoolName,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              StatusBadge(
                                status: request.status,
                                fontSize: 12,
                              ),
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

                  // ── School Information Card (fetched from Firestore) ──
                  _buildSectionTitle('School Information'),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, child) {
                      final schoolAsync = ref.watch(
                        schoolDetailProvider(request.schoolId),
                      );
                      return schoolAsync.when(
                        data: (school) {
                          if (school == null) {
                            return GradientCard(
                              showBorder: false,
                              padding: const EdgeInsets.all(16),
                              child: _buildInfoRow(
                                LucideIcons.hash,
                                'School ID',
                                request.schoolId,
                                copyable: true,
                              ),
                            );
                          }
                          return GradientCard(
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
                                if (school.city != null &&
                                    school.city!.isNotEmpty) ...[
                                  _buildInfoRow(
                                    LucideIcons.mapPin,
                                    'City',
                                    school.city!,
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
                                if (school.email != null &&
                                    school.email!.isNotEmpty) ...[
                                  _buildInfoRow(
                                    LucideIcons.mail,
                                    'Email',
                                    school.email!,
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
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(school.installedAt),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const InlineLoader(
                          message: 'Loading school info...',
                        ),
                        error: (_, __) => GradientCard(
                          showBorder: false,
                          padding: const EdgeInsets.all(16),
                          child: _buildInfoRow(
                            LucideIcons.hash,
                            'School ID',
                            request.schoolId,
                            copyable: true,
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ── Request Details ──
                  _buildSectionTitle('Request Details'),
                  const SizedBox(height: 10),
                  GradientCard(
                    showBorder: false,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          LucideIcons.box,
                          'Package',
                          PackageType.getDisplayName(request.packageType),
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          LucideIcons.clock,
                          'Requested',
                          '${DateFormat('MMM d, yyyy').format(request.requestedAt)} (${timeago.format(request.requestedAt)})',
                        ),
                        if (request.reviewedAt != null) ...[
                          _buildDivider(),
                          _buildInfoRow(
                            LucideIcons.checkCircle2,
                            'Reviewed',
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(request.reviewedAt!),
                          ),
                        ],
                        if (request.rejectionReason != null &&
                            request.rejectionReason!.isNotEmpty) ...[
                          _buildDivider(),
                          _buildInfoRow(
                            LucideIcons.messageSquare,
                            'Reason',
                            request.rejectionReason!,
                          ),
                        ],
                        if (request.notes != null &&
                            request.notes!.isNotEmpty) ...[
                          _buildDivider(),
                          _buildInfoRow(
                            LucideIcons.stickyNote,
                            'Notes',
                            request.notes!,
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ── Requested Modules Grid (2 columns) ──
                  _buildSectionTitle(
                    'Requested Modules (${request.requestedModules.length})',
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: request.requestedModules.map((modId) {
                      final mod = EduXModules.getById(modId);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (mod?.color ?? AppColors.primary).withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  mod?.icon ?? LucideIcons.box,
                                  size: 16,
                                  color: mod?.color ?? AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    mod?.name ?? modId,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mod?.description ?? '',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // ── Action Bar (only for pending requests) ──
                  if (request.isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _showRejectDialog(),
                              icon: const Icon(
                                LucideIcons.xCircle,
                                size: 18,
                              ),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _showApproveDialog(request),
                              icon: const Icon(
                                LucideIcons.checkCircle,
                                size: 18,
                              ),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(
                          begin: 0.05,
                          end: 0,
                          delay: 500.ms,
                          duration: 400.ms,
                        ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () =>
              const InlineLoader(message: 'Loading request details...'),
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
            width: 80,
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

  // ── APPROVE DIALOG with module toggles + expiry shortcuts ──
  void _showApproveDialog(dynamic request) {
    debugPrint(
        'DEBUG: Request modules from Firestore: ${request.requestedModules}');
    debugPrint(
        'DEBUG: Request modules runtime type: ${request.requestedModules.runtimeType}');
    final selectedModules = List<String>.from(request.requestedModules);
    debugPrint('DEBUG: Selected modules after conversion: $selectedModules');
    final defaultDays = ref.read(defaultLicenseDurationProvider);
    var expiryDate = DateTime.now().add(Duration(days: defaultDays));
    int selectedPreset = 4; // default = "1 Year"

    final presets = [
      ('1 Month', 30),
      ('3 Months', 90),
      ('6 Months', 180),
      ('1 Year', 365),
      ('Custom', -1),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  // Handle bar
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
                    'Approve Request',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure the license for ${request.schoolName}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Module selection
                  Text(
                    'Modules (${selectedModules.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Module toggles
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: request.requestedModules.map<Widget>((
                              String id,
                            ) {
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
                          const SizedBox(height: 20),

                          // Expiry shortcuts
                          Text(
                            'License Duration',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(presets.length, (index) {
                              final (label, days) = presets[index];
                              final isSelected = selectedPreset == index;
                              return GestureDetector(
                                onTap: () async {
                                  if (days == -1) {
                                    // Custom picker
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: expiryDate,
                                      firstDate: DateTime.now().add(
                                        const Duration(days: 1),
                                      ),
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
                                      setModalState(() {
                                        expiryDate = picked;
                                        selectedPreset = index;
                                      });
                                    }
                                  } else {
                                    setModalState(() {
                                      expiryDate = DateTime.now().add(
                                        Duration(days: days),
                                      );
                                      selectedPreset = index;
                                    });
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expires: ${DateFormat('MMMM d, yyyy').format(expiryDate)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Approve button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: selectedModules.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              _approveRequest(
                                requestId: request.id,
                                schoolId: request.schoolId,
                                modules: selectedModules,
                                expiryDate: expiryDate,
                              );
                            },
                      icon: const Icon(LucideIcons.checkCircle, size: 18),
                      label: Text(
                        selectedModules.isEmpty
                            ? 'Select at least 1 module'
                            : 'Approve (${selectedModules.length} modules)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        disabledBackgroundColor: AppColors.success.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.outfit(
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

  Future<void> _approveRequest({
    required String requestId,
    required String schoolId,
    required List<String> modules,
    required DateTime expiryDate,
  }) async {
    debugPrint('DEBUG: _approveRequest called with modules: $modules');
    setState(() => _isProcessing = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final adminUid = authService.getAdminUid() ?? '';
      debugPrint('DEBUG: Admin UID: $adminUid');

      await firestoreService.approveRequest(
        requestId: requestId,
        schoolId: schoolId,
        approvedModules: modules,
        expiryDate: expiryDate,
        adminUid: adminUid,
      );

      // Haptic feedback
      HapticFeedback.heavyImpact();

      if (mounted) {
        ref.invalidate(requestDetailProvider(widget.requestId));
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
                const Text('Request approved successfully'),
              ],
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── REJECT DIALOG ──
  void _showRejectDialog() {
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
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
                  'Reject Request',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Provide a reason for rejecting this request.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // Reason field
                TextFormField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Rejection Reason',
                    hintText: 'e.g., Payment not received',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes field
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Internal Notes (optional)',
                    hintText: 'Additional notes...',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 24),

                // Reject button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _rejectRequest(
                        reasonController.text.trim(),
                        notesController.text.trim(),
                      );
                    },
                    icon: const Icon(LucideIcons.xCircle, size: 18),
                    label: const Text('Reject Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rejectRequest(String reason, String notes) async {
    setState(() => _isProcessing = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final adminUid = authService.getAdminUid() ?? '';

      await firestoreService.rejectRequest(
        requestId: widget.requestId,
        adminUid: adminUid,
        rejectionReason: reason.isNotEmpty ? reason : null,
        notes: notes.isNotEmpty ? notes : null,
      );

      // Haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        ref.invalidate(requestDetailProvider(widget.requestId));
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
                const Text('Request rejected'),
              ],
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
