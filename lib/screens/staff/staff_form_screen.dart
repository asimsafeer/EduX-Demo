/// EduX School Management System
/// Staff Form Screen - Add/Edit staff member
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../providers/staff_provider.dart';
import '../../services/staff_service.dart';
import '../../core/widgets/app_loading_indicator.dart';

/// Form screen for creating/editing staff members
class StaffFormScreen extends ConsumerStatefulWidget {
  final int? staffId;

  const StaffFormScreen({super.key, this.staffId});

  bool get isEditing => staffId != null;

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Personal Info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'male';
  final _cnicController = TextEditingController();
  Uint8List? _photo;

  // Contact Info
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Professional Info
  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _previousEmployerController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();

  // Employment Info
  int? _roleId;
  final _salaryController = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  String _status = 'active';

  // Bank Details
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  // Emergency Contact
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  // Notes
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadStaffData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadStaffData() async {
    final staff = await ref.read(staffByIdProvider(widget.staffId!).future);
    if (staff == null || !mounted) return;

    setState(() {
      _firstNameController.text = staff.staff.firstName;
      _lastNameController.text = staff.staff.lastName;
      _dateOfBirth = staff.staff.dateOfBirth;
      _gender = staff.staff.gender;
      _cnicController.text = staff.staff.cnic ?? '';
      _photo = staff.staff.photo;

      _phoneController.text = staff.staff.phone;
      _alternatePhoneController.text = staff.staff.alternatePhone ?? '';
      _emailController.text = staff.staff.email ?? '';
      _addressController.text = staff.staff.address ?? '';
      _cityController.text = staff.staff.city ?? '';

      _qualificationController.text = staff.staff.qualification ?? '';
      _specializationController.text = staff.staff.specialization ?? '';
      _experienceController.text =
          staff.staff.experienceYears?.toString() ?? '';
      _previousEmployerController.text = staff.staff.previousEmployer ?? '';
      _designationController.text = staff.staff.designation;
      _departmentController.text = staff.staff.department ?? '';

      _roleId = staff.staff.roleId;
      _salaryController.text = staff.staff.basicSalary.toStringAsFixed(0);
      _joiningDate = staff.staff.joiningDate;
      _status = staff.staff.status;

      _bankNameController.text = staff.staff.bankName ?? '';
      _accountNumberController.text = staff.staff.accountNumber ?? '';

      _emergencyContactNameController.text =
          staff.staff.emergencyContactName ?? '';
      _emergencyContactPhoneController.text =
          staff.staff.emergencyContactPhone ?? '';

      _notesController.text = staff.staff.notes ?? '';

      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _qualificationController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _previousEmployerController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _salaryController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _photo = bytes);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isJoining) async {
    final initialDate = isJoining
        ? _joiningDate
        : (_dateOfBirth ?? DateTime(1990));
    final firstDate = isJoining ? DateTime(2000) : DateTime(1950);
    final lastDate = isJoining
        ? DateTime.now().add(const Duration(days: 30))
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isJoining) {
          _joiningDate = picked;
        } else {
          _dateOfBirth = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final formData = StaffFormData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      cnic: _cnicController.text.isEmpty ? null : _cnicController.text.trim(),
      phone: _phoneController.text.trim(),
      alternatePhone: _alternatePhoneController.text.isEmpty
          ? null
          : _alternatePhoneController.text.trim(),
      email: _emailController.text.isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.isEmpty ? null : _cityController.text.trim(),
      photo: _photo?.toList(),
      qualification: _qualificationController.text.isEmpty
          ? null
          : _qualificationController.text.trim(),
      specialization: _specializationController.text.isEmpty
          ? null
          : _specializationController.text.trim(),
      experienceYears: _experienceController.text.isEmpty
          ? null
          : int.tryParse(_experienceController.text),
      previousEmployer: _previousEmployerController.text.isEmpty
          ? null
          : _previousEmployerController.text.trim(),
      designation: _designationController.text.trim(),
      department: _departmentController.text.isEmpty
          ? null
          : _departmentController.text.trim(),
      roleId: _roleId!,
      basicSalary: double.parse(_salaryController.text),
      joiningDate: _joiningDate,
      status: _status,
      bankName: _bankNameController.text.isEmpty
          ? null
          : _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.isEmpty
          ? null
          : _accountNumberController.text.trim(),
      emergencyContactName: _emergencyContactNameController.text.isEmpty
          ? null
          : _emergencyContactNameController.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneController.text.isEmpty
          ? null
          : _emergencyContactPhoneController.text.trim(),
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
    );

    bool success;
    if (widget.isEditing) {
      success = await ref
          .read(staffOperationProvider.notifier)
          .updateStaff(widget.staffId!, formData);
    } else {
      final id = await ref
          .read(staffOperationProvider.notifier)
          .createStaff(formData);
      success = id != null;
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Staff member updated' : 'Staff member created',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/staff');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(staffRolesProvider);

    if (_isLoading) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Staff Member' : 'Add Staff Member',
        ),
        actions: [
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(widget.isEditing ? 'Update' : 'Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Photo & Basic Info
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: 24),
                    _buildStatusSection(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column - Form Sections
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Personal Information',
                      icon: Icons.person,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name *',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name *',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of Birth',
                                    prefixIcon: Icon(Icons.cake_outlined),
                                  ),
                                  child: Text(
                                    _dateOfBirth != null
                                        ? DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_dateOfBirth!)
                                        : 'Select Date',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(
                                  labelText: 'Gender *',
                                  prefixIcon: Icon(Icons.wc),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text('Female'),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cnicController,
                          decoration: const InputDecoration(
                            labelText: 'CNIC',
                            prefixIcon: Icon(Icons.badge_outlined),
                            hintText: 'XXXXX-XXXXXXX-X',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.phone,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone *',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  hintText: '03XX-XXXXXXX',
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _alternatePhoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Alternate Phone',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Professional Information',
                      icon: Icons.work,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _designationController,
                                decoration: const InputDecoration(
                                  labelText: 'Designation *',
                                  prefixIcon: Icon(Icons.badge),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _departmentController,
                                decoration: const InputDecoration(
                                  labelText: 'Department',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _qualificationController,
                                decoration: const InputDecoration(
                                  labelText: 'Qualification',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _specializationController,
                                decoration: const InputDecoration(
                                  labelText: 'Specialization',
                                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _experienceController,
                                decoration: const InputDecoration(
                                  labelText: 'Experience (Years)',
                                  prefixIcon: Icon(Icons.timeline_outlined),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _previousEmployerController,
                                decoration: const InputDecoration(
                                  labelText: 'Previous Employer',
                                  prefixIcon: Icon(Icons.history_edu_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Employment Details',
                      icon: Icons.assignment_ind,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: rolesAsync.when(
                                data: (roles) => DropdownButtonFormField<int>(
                                  initialValue: _roleId,
                                  decoration: const InputDecoration(
                                    labelText: 'Role *',
                                    prefixIcon: Icon(
                                      Icons.admin_panel_settings_outlined,
                                    ),
                                  ),
                                  items: roles
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r.id,
                                          child: Text(r.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => _roleId = v),
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                ),
                                loading: () => const LinearProgressIndicator(),
                                error: (_, __) =>
                                    const Text('Failed to load roles'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _salaryController,
                                decoration: const InputDecoration(
                                  labelText: 'Basic Salary (PKR) *',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final salary = double.tryParse(v);
                                  if (salary == null || salary <= 0) {
                                    return 'Invalid salary';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Joining Date *',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_joiningDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Bank Details (Optional)',
                      icon: Icons.account_balance,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _bankNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Bank Name',
                                  prefixIcon: Icon(
                                    Icons.account_balance_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _accountNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Account Number',
                                  prefixIcon: Icon(Icons.credit_card_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Emergency Contact (Optional)',
                      icon: Icons.emergency,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emergencyContactNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _emergencyContactPhoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Phone',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Notes',
                      icon: Icons.notes,
                      children: [
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Additional Notes',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _photo != null ? MemoryImage(_photo!) : null,
                child: _photo == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text(_photo == null ? 'Add Photo' : 'Change Photo'),
            ),
            if (_photo != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _photo = null),
                child: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...['active', 'on_leave', 'resigned', 'terminated'].map((status) {
              return ListTile(
                title: Text(_formatStatus(status)),
                leading: Radio<String>(
                  // ignore: deprecated_member_use
                  value: status,
                  // ignore: deprecated_member_use
                  groupValue: _status,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _status = v!),
                ),
                onTap: () => setState(() => _status = status),
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'on_leave':
        return 'On Leave';
      case 'resigned':
        return 'Resigned';
      case 'terminated':
        return 'Terminated';
      default:
        return status;
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
