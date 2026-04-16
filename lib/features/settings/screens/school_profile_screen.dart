/// EduX School Management System
/// School Profile Screen - Edit school information
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../providers/providers.dart';
import '../../../services/services.dart';

/// Screen for editing school profile information
class SchoolProfileScreen extends ConsumerStatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  ConsumerState<SchoolProfileScreen> createState() =>
      _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends ConsumerState<SchoolProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;
  Uint8List? _newLogoBytes;

  // Institution Type
  String _institutionType = 'School';
  final _institutionTypes = ['School', 'College', 'Institute', 'Academy'];

  // Form controllers
  late TextEditingController _schoolNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;
  late TextEditingController _alternatePhoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _principalNameController;
  late TextEditingController _currencyController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;

  // Bank details controllers
  late TextEditingController _bankNameController;
  late TextEditingController _accountTitleController;
  late TextEditingController _accountNumberController;
  late TextEditingController _onlinePaymentInfoController;

  List<String> _selectedWorkingDays = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadSettings();
  }

  void _initControllers() {
    _schoolNameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();
    _phoneController = TextEditingController();
    _alternatePhoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _principalNameController = TextEditingController();
    _currencyController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountTitleController = TextEditingController();
    _accountNumberController = TextEditingController();
    _onlinePaymentInfoController = TextEditingController();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(schoolSettingsProvider.future);
    if (settings != null && mounted) {
      setState(() {
        _institutionType = settings.institutionType;
        _schoolNameController.text = settings.schoolName;
        _addressController.text = settings.address ?? '';
        _cityController.text = settings.city ?? '';
        _stateController.text = settings.state ?? '';
        _postalCodeController.text = settings.postalCode ?? '';
        _countryController.text = settings.country;
        _phoneController.text = settings.phone ?? '';
        _alternatePhoneController.text = settings.alternatePhone ?? '';
        _emailController.text = settings.email ?? '';
        _websiteController.text = settings.website ?? '';
        _principalNameController.text = settings.principalName ?? '';
        _currencyController.text = settings.currencySymbol;
        _startTimeController.text = settings.schoolStartTime;
        _endTimeController.text = settings.schoolEndTime;
        _bankNameController.text = settings.bankName ?? '';
        _accountTitleController.text = settings.accountTitle ?? '';
        _accountNumberController.text = settings.accountNumber ?? '';
        _onlinePaymentInfoController.text = settings.onlinePaymentInfo ?? '';
        _selectedWorkingDays = settings.workingDays
            .split(',')
            .where((d) => d.isNotEmpty)
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _principalNameController.dispose();
    _currencyController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _bankNameController.dispose();
    _accountTitleController.dispose();
    _accountNumberController.dispose();
    _onlinePaymentInfoController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _newLogoBytes = bytes;
        _hasChanges = true;
      });
    }
  }

  void _removeLogo() {
    setState(() {
      _newLogoBytes = Uint8List(0); // Empty bytes signals removal
      _hasChanges = true;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(schoolSettingsServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      // Update settings
      await service.updateSettings(
        schoolName: _schoolNameController.text,
        institutionType: _institutionType,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        state: _stateController.text.isEmpty ? null : _stateController.text,
        postalCode: _postalCodeController.text.isEmpty
            ? null
            : _postalCodeController.text,
        country: _countryController.text.isEmpty
            ? null
            : _countryController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        alternatePhone: _alternatePhoneController.text.isEmpty
            ? null
            : _alternatePhoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        website: _websiteController.text.isEmpty
            ? null
            : _websiteController.text,
        principalName: _principalNameController.text.isEmpty
            ? null
            : _principalNameController.text,
        currencySymbol: _currencyController.text.isEmpty
            ? null
            : _currencyController.text,
        workingDays: _selectedWorkingDays.join(','),
        schoolEndTime: _endTimeController.text.isEmpty
            ? null
            : _endTimeController.text,
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        accountTitle: _accountTitleController.text.trim().isEmpty
            ? null
            : _accountTitleController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        onlinePaymentInfo: _onlinePaymentInfoController.text.trim().isEmpty
            ? null
            : _onlinePaymentInfoController.text.trim(),
      );

      // Update logo if changed
      if (_newLogoBytes != null) {
        if (_newLogoBytes!.isEmpty) {
          await service.removeLogo();
        } else {
          await service.updateLogo(_newLogoBytes!);
        }
      }

      // Log activity
      await activityLog.logUpdate(
        userId: currentUser?.id,
        module: 'settings',
        entityType: 'school_settings',
        entityId: 1,
        description: 'Updated $_institutionType profile',
      );

      // Refresh providers
      ref.invalidate(schoolSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_institutionType profile updated successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(schoolSettingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => _buildContent(settings),
      ),
    );
  }

  Widget _buildContent(dynamic settings) {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              onChanged: _markChanged,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo section
                  _buildLogoSection(settings),
                  const SizedBox(height: 32),

                  // Basic info
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _institutionType,
                    decoration: const InputDecoration(
                      labelText: 'Institution Type',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: _institutionTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _institutionType = value;
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _schoolNameController,
                    label: '$_institutionType Name',
                    icon: LucideIcons.building2,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _principalNameController,
                    label: 'Principal Name',
                    icon: LucideIcons.user,
                  ),
                  const SizedBox(height: 32),

                  // Contact info
                  _buildSectionTitle('Contact Information'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          icon: LucideIcons.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _alternatePhoneController,
                          label: 'Alternate Phone',
                          icon: LucideIcons.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: LucideIcons.mail,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _websiteController,
                          label: 'Website',
                          icon: LucideIcons.globe,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Address
                  _buildSectionTitle('Address'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Street Address',
                    icon: LucideIcons.mapPin,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'City',
                          icon: LucideIcons.building,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _stateController,
                          label: 'State/Province',
                          icon: LucideIcons.map,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _postalCodeController,
                          label: 'Postal Code',
                          icon: LucideIcons.hash,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _countryController,
                          label: 'Country',
                          icon: LucideIcons.globe2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // School timing
                  _buildSectionTitle('School Timing'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _startTimeController,
                          label: 'Start Time (HH:mm)',
                          icon: LucideIcons.clock,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _endTimeController,
                          label: 'End Time (HH:mm)',
                          icon: LucideIcons.clock,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWorkingDaysSelector(),
                  const SizedBox(height: 32),

                  // Bank Details
                  _buildSectionTitle('Bank Details & Online Payment'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bankNameController,
                    label: 'Bank Name',
                    icon: LucideIcons.landmark,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _accountTitleController,
                          label: 'Account Title',
                          icon: LucideIcons.user,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _accountNumberController,
                          label: 'Account Number / IBAN',
                          icon: LucideIcons.creditCard,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _onlinePaymentInfoController,
                    label: 'Online Payment Instructions',
                    icon: LucideIcons.smartphone,
                  ),
                  const SizedBox(height: 32),

                  // Currency
                  _buildSectionTitle('Regional Settings'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: _buildTextField(
                      controller: _currencyController,
                      label: 'Currency Symbol',
                      icon: LucideIcons.dollarSign,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_institutionType Profile',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Edit ${_institutionType.toLowerCase()} information',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_hasChanges)
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.save, size: 18),
              label: const Text('Save Changes'),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(dynamic settings) {
    final hasLogo = _newLogoBytes != null || (settings?.logo != null);
    final logoBytes = _newLogoBytes ?? settings?.logo;
    final showLogo = hasLogo && logoBytes != null && logoBytes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Logo preview
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: showLogo
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(logoBytes!, fit: BoxFit.cover),
                  )
                : Icon(
                    LucideIcons.image,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 24),

          // Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_institutionType Logo',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload your ${_institutionType.toLowerCase()} logo (PNG or JPG)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(LucideIcons.upload, size: 18),
                      label: const Text('Upload'),
                    ),
                    if (showLogo) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _removeLogo,
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.error,
                        ),
                        label: Text(
                          'Remove',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildWorkingDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Working Days', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SchoolSettingsService.allDays.map((day) {
            final isSelected = _selectedWorkingDays.contains(day);
            return FilterChip(
              label: Text(
                SchoolSettingsService.dayDisplayNames[day] ?? day,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.textOnPrimary,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWorkingDays.add(day);
                  } else {
                    _selectedWorkingDays.remove(day);
                  }
                  _hasChanges = true;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
