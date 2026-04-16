/// EduX School Management System
/// License Request Screen — Submit license requests to NovaByte Hub
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/core.dart';
import '../../router/app_router.dart';
import '../../services/license_service.dart';

/// Screen where school admins request/manage their license.
class LicenseRequestScreen extends StatefulWidget {
  const LicenseRequestScreen({super.key});

  @override
  State<LicenseRequestScreen> createState() => _LicenseRequestScreenState();
}

class _LicenseRequestScreenState extends State<LicenseRequestScreen> {
  // State
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _schoolId;
  String? _schoolName;
  String? _requestStatus;
  LicenseData? _licenseData;

  String _selectedPackage = 'standard';
  Set<String> _selectedModules = {};

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final svc = LicenseService.instance;

    _schoolId = await svc.getSchoolId();
    _schoolName = await svc.getSchoolName();
    _licenseData = await svc.getLicenseData();

    // Check for pending request - both locally and in Firestore
    final hasPending = await svc.hasPendingRequest();
    if (hasPending) {
      _requestStatus = 'pending';
    } else {
      final prefs = await svc.getSchoolId() != null
          ? await svc.checkRequestStatus()
          : null;
      _requestStatus = prefs;
    }

    _onPackageChanged('standard');

    setState(() => _isLoading = false);
  }

  void _onPackageChanged(String packageId) {
    setState(() {
      _selectedPackage = packageId;
      final pkg = EduXPackages.all.firstWhere((p) => p.id == packageId);
      _selectedModules = Set<String>.from(pkg.moduleIds);
    });
  }

  void _toggleModule(String moduleId) {
    setState(() {
      if (_selectedModules.contains(moduleId)) {
        _selectedModules.remove(moduleId);
      } else {
        _selectedModules.add(moduleId);
      }
      // Switch to custom if selection no longer matches any package
      _selectedPackage = 'custom';
      for (final pkg in EduXPackages.all) {
        if (Set<String>.from(pkg.moduleIds).length == _selectedModules.length &&
            _selectedModules.containsAll(pkg.moduleIds)) {
          _selectedPackage = pkg.id;
          break;
        }
      }
    });
  }

  Future<void> _submitRequest() async {
    if (_schoolId == null) return;
    if (_selectedModules.isEmpty) {
      context.showErrorSnackBar('Please select at least one module');
      return;
    }

    // Check if already has pending request
    final hasPending = await LicenseService.instance.hasPendingRequest();
    if (hasPending) {
      if (mounted) {
        setState(() => _requestStatus = 'pending');
        context.showErrorSnackBar(
          'You already have a pending request. Please wait for approval.',
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await LicenseService.instance.submitLicenseRequest(
        schoolId: _schoolId!,
        schoolName: _schoolName ?? 'Unknown School',
        packageType: _selectedPackage,
        requestedModules: _selectedModules.toList(),
      );

      if (mounted) {
        setState(() => _requestStatus = 'pending');
        String message = _licenseData != null && !_licenseData!.isExpired
            ? 'Upgrade request submitted successfully!'
            : 'License request submitted successfully!';
        context.showSuccessSnackBar(message);
      }
    } catch (e) {
      debugPrint('License request error: $e');
      if (mounted) {
        context.showErrorSnackBar('Failed to submit request: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLicense() async {
    setState(() => _isRefreshing = true);

    try {
      final found = await LicenseService.instance.refreshLicenseFromFirestore();
      if (found && mounted) {
        context.showSuccessSnackBar('License activated! Redirecting…');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go(AppRoutes.login);
      } else if (mounted) {
        final status = await LicenseService.instance.checkRequestStatus();
        if (!mounted) return;
        setState(() => _requestStatus = status);
        context.showErrorSnackBar('No approved license found yet.');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to check license status.');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Custom Title Bar ───────────────────────
          if (isDesktop) _buildTitleBar(),

          // ── Main Content ──────────────────────────
          Expanded(
            child: _isLoading && _schoolId == null
                ? const Center(child: CircularProgressIndicator())
                : isWide
                ? Row(
                    children: [
                      // ── Left Panel ─────────────────
                      Expanded(flex: 4, child: _buildLeftPanel(size)),
                      // ── Right Panel ────────────────
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: 48,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 550),
                              child: _requestStatus == 'pending'
                                  ? _buildPendingView()
                                  : _buildRequestForm(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                // ── Single column for narrow windows ──
                : Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.06,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: _requestStatus == 'pending'
                            ? _buildPendingView()
                            : _buildRequestForm(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Custom Title Bar (Desktop)
  // ─────────────────────────────────────────────────────────────

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

            // Window controls (hidden on macOS — uses native traffic lights)
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

  // ─────────────────────────────────────────────────────────────
  //  Left Branding Panel
  // ─────────────────────────────────────────────────────────────

  Widget _buildLeftPanel(Size size) {
    final hPad = size.width * 0.03;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppConstants.appName,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // License info chip
          if (_licenseData != null && !_licenseData!.isExpired)
            _buildInfoChip(
              LucideIcons.checkCircle,
              'Licensed • ${_licenseData!.daysRemaining} days left',
              Colors.green,
            )
          else if (_requestStatus == 'pending')
            _buildInfoChip(
              LucideIcons.hourglass,
              'Request Pending - Full Access Enabled',
              Colors.orange,
            )
          else
            _buildInfoChip(
              LucideIcons.alertTriangle,
              'License Required',
              Colors.red,
            ),

          const SizedBox(height: 32),

          // School ID card
          if (_schoolId != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'School ID',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _schoolId!,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          LucideIcons.copy,
                          size: 18,
                          color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _schoolId!));
                          context.showSuccessSnackBar('School ID copied!');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Pending Request View
  // ─────────────────────────────────────────────────────────────

  Widget _buildPendingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(LucideIcons.hourglass, size: 64, color: AppColors.warning),
        const SizedBox(height: 24),
        Text(
          'Request Pending',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your license request has been submitted and is awaiting approval '
          'from the NovaByte Hub admin.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 20, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can only have one pending request at a time. '
                  'Please wait for the admin to review your request.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Refresh button
        AppButton.primary(
          text: 'Check License Status',
          icon: LucideIcons.refreshCw,
          isLoading: _isRefreshing,
          size: AppButtonSize.large,
          isExpanded: true,
          onPressed: _refreshLicense,
        ),
        const SizedBox(height: 32),
        _buildContactSupport(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Request Form
  // ─────────────────────────────────────────────────────────────

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(LucideIcons.shieldCheck, size: 64, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          _licenseData != null && !_licenseData!.isExpired
              ? 'Upgrade Plan'
              : 'Request License',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _licenseData != null && !_licenseData!.isExpired
              ? 'Select a higher package or additional modules to upgrade your school plan.'
              : 'Select a package and modules to activate for your school.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Package selector
        Text('Package', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: EduXPackages.all.map((pkg) {
            final isSelected = _selectedPackage == pkg.id;
            return _PackageChip(
              name: pkg.name,
              icon: pkg.icon,
              color: pkg.color,
              isSelected: isSelected,
              onTap: () => _onPackageChanged(pkg.id),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Module selection
        Text('Modules', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Customize which modules you need',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...EduXModules.all.map((mod) {
          final isOwned = _licenseData?.hasModule(mod.id) ?? false;
          return _ModuleTile(
            module: mod,
            isSelected: isOwned || _selectedModules.contains(mod.id),
            isOwned: isOwned,
            onTap: isOwned ? () {} : () => _toggleModule(mod.id),
          );
        }),

        const SizedBox(height: 32),

        // Submit
        AppButton.primary(
          text: _licenseData != null && !_licenseData!.isExpired
              ? 'Submit Upgrade Request'
              : 'Submit License Request',
          icon: LucideIcons.send,
          isLoading: _isLoading,
          size: AppButtonSize.large,
          isExpanded: true,
          onPressed: _submitRequest,
        ),

        const SizedBox(height: 16),

        // Already have a license? Check
        AppButton.secondary(
          text: 'Already Approved? Check Status',
          icon: LucideIcons.refreshCw,
          isLoading: _isRefreshing,
          size: AppButtonSize.large,
          onPressed: _refreshLicense,
        ),

        const SizedBox(height: 32),
        _buildContactSupport(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.headphones,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            'Need Help? Contact Us',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Tap to view contact details',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _ContactRow(
              icon: LucideIcons.messageCircle,
              label: 'WhatsApp',
              value: NovaByteContact.phoneDisplay,
              color: const Color(0xFF25D366),
              onTap: () => _launchUrl(
                'https://wa.me/${NovaByteContact.whatsApp.replaceAll("+", "")}',
              ),
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: LucideIcons.mail,
              label: 'Email',
              value: NovaByteContact.email,
              color: AppColors.info,
              onTap: () => _launchUrl(
                'mailto:${NovaByteContact.email}?subject=EduX Support - ${_schoolId ?? ""}&body=School: ${_schoolName ?? ""}%0ASchool ID: ${_schoolId ?? ""}%0A%0A',
              ),
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: LucideIcons.phone,
              label: 'Phone',
              value: NovaByteContact.phoneDisplay,
              color: AppColors.success,
              onTap: () => _launchUrl('tel:${NovaByteContact.whatsApp}'),
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: LucideIcons.globe,
              label: 'Website',
              value: 'novabyte.studio',
              color: AppColors.primary,
              onTap: () => _launchUrl(NovaByteContact.website),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  Window Button (Desktop title bar control)
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
//  Package selection chip
// ─────────────────────────────────────────────────────────────

class _PackageChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageChip({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Module selection tile
// ─────────────────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  final ModuleInfo module;
  final bool isSelected;
  final bool isOwned;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.module,
    required this.isSelected,
    this.isOwned = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? module.color.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? module.color : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  module.icon,
                  size: 22,
                  color: isSelected ? module.color : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isSelected
                              ? module.color
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        module.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isOwned)
                  Icon(LucideIcons.checkCircle, color: AppColors.success)
                else
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    activeColor: module.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Contact Row (for support card)
// ─────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.externalLink,
                size: 16,
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
