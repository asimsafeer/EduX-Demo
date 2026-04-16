/// EduX School Management System
/// Guardian Form Screen - Add/Edit guardian details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/guardian_provider.dart';
import '../../core/widgets/app_loading_indicator.dart';

/// Screen for adding or editing a guardian
class GuardianFormScreen extends ConsumerStatefulWidget {
  final int? guardianId; // null for new guardian
  final int?
  studentId; // If provided, link guardian to this student after creation

  const GuardianFormScreen({super.key, this.guardianId, this.studentId});

  @override
  ConsumerState<GuardianFormScreen> createState() => _GuardianFormScreenState();
}

class _GuardianFormScreenState extends ConsumerState<GuardianFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _occupationController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _relation = 'Father';
  bool _isPrimary = false;
  bool _canPickup = true;
  bool _isEmergencyContact = false;

  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isEditing => widget.guardianId != null;

  static const List<String> _relationOptions = [
    'Father',
    'Mother',
    'Guardian',
    'Uncle',
    'Aunt',
    'Grandparent',
    'Sibling',
    'Other',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _occupationController.dispose();
    _workplaceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadGuardianData() async {
    if (isEditing && !_isInitialized) {
      final guardian = await ref.read(
        guardianByIdProvider(widget.guardianId!).future,
      );
      if (guardian != null && mounted) {
        setState(() {
          _firstNameController.text = guardian.firstName;
          _lastNameController.text = guardian.lastName;
          _phoneController.text = guardian.phone;
          _alternatePhoneController.text = guardian.alternatePhone ?? '';
          _emailController.text = guardian.email ?? '';
          _cnicController.text = guardian.cnic ?? '';
          _occupationController.text = guardian.occupation ?? '';
          _workplaceController.text = guardian.workplace ?? '';
          _addressController.text = guardian.address ?? '';
          _cityController.text = guardian.city ?? '';
          _relation = guardian.relation;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final formData = GuardianFormData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        relation: _relation,
        phone: _phoneController.text.trim(),
        alternatePhone: _alternatePhoneController.text.isEmpty
            ? null
            : _alternatePhoneController.text.trim(),
        email: _emailController.text.isEmpty
            ? null
            : _emailController.text.trim(),
        cnic: _cnicController.text.isEmpty ? null : _cnicController.text.trim(),
        occupation: _occupationController.text.isEmpty
            ? null
            : _occupationController.text.trim(),
        workplace: _workplaceController.text.isEmpty
            ? null
            : _workplaceController.text.trim(),
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.isEmpty ? null : _cityController.text.trim(),
      );

      if (isEditing) {
        final success = await ref
            .read(guardianOperationProvider.notifier)
            .updateGuardian(widget.guardianId!, formData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guardian updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _goBack();
        }
      } else {
        final guardianId = await ref
            .read(guardianOperationProvider.notifier)
            .createGuardian(formData);
        if (guardianId != null && mounted) {
          // If student ID provided, link the guardian
          if (widget.studentId != null) {
            await ref
                .read(guardianOperationProvider.notifier)
                .linkToStudent(
                  widget.studentId!,
                  guardianId,
                  GuardianLinkSettings(
                    isPrimary: _isPrimary,
                    canPickup: _canPickup,
                    isEmergencyContact: _isEmergencyContact,
                  ),
                );
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Guardian created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _goBack();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBack() {
    if (widget.studentId != null) {
      context.go('/students/${widget.studentId}');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load guardian data if editing
    if (isEditing && !_isInitialized) {
      _loadGuardianData();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Guardian' : 'Add Guardian'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: _isLoading && isEditing && !_isInitialized
          ? const Center(child: AppLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader('Personal Information', Icons.person),
                    const SizedBox(height: 16),
                    _buildPersonalInfoSection(),

                    const SizedBox(height: 32),

                    // Contact Information Section
                    _buildSectionHeader('Contact Information', Icons.phone),
                    const SizedBox(height: 16),
                    _buildContactSection(),

                    const SizedBox(height: 32),

                    // Employment Information Section
                    _buildSectionHeader('Employment Information', Icons.work),
                    const SizedBox(height: 16),
                    _buildEmploymentSection(),

                    // Link settings (only for new guardians with student)
                    if (!isEditing && widget.studentId != null) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader('Relationship Settings', Icons.link),
                      const SizedBox(height: 16),
                      _buildLinkSettingsSection(),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading ? null : _goBack,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitForm,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            isEditing ? 'Update Guardian' : 'Create Guardian',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // First Name
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'First name is required';
              }
              if (value.trim().length < 2) {
                return 'Minimum 2 characters';
              }
              return null;
            },
          ),
        ),

        // Last Name
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Last name is required';
              }
              if (value.trim().length < 2) {
                return 'Minimum 2 characters';
              }
              return null;
            },
          ),
        ),

        // Relation
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _relation,
            decoration: const InputDecoration(
              labelText: 'Relation *',
              border: OutlineInputBorder(),
            ),
            items: _relationOptions.map((rel) {
              return DropdownMenuItem(value: rel, child: Text(rel));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _relation = value);
              }
            },
          ),
        ),

        // CNIC
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _cnicController,
            decoration: const InputDecoration(
              labelText: 'CNIC',
              hintText: 'XXXXX-XXXXXXX-X',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Phone
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone *',
              hintText: '03XX-XXXXXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone is required';
              }
              return null;
            },
          ),
        ),

        // Alternate Phone
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _alternatePhoneController,
            decoration: const InputDecoration(
              labelText: 'Alternate Phone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_android),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),

        // Email
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ),

        // Address
        SizedBox(
          width: 400,
          child: TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
        ),

        // City
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Occupation
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _occupationController,
            decoration: const InputDecoration(
              labelText: 'Occupation',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
          ),
        ),

        // Workplace
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _workplaceController,
            decoration: const InputDecoration(
              labelText: 'Workplace',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Primary Guardian'),
              subtitle: const Text(
                'This is the primary contact for the student',
              ),
              value: _isPrimary,
              onChanged: (value) => setState(() => _isPrimary = value),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Can Pick Up'),
              subtitle: const Text(
                'Authorized to pick up the student from school',
              ),
              value: _canPickup,
              onChanged: (value) => setState(() => _canPickup = value),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Emergency Contact'),
              subtitle: const Text('Contact in case of emergencies'),
              value: _isEmergencyContact,
              onChanged: (value) => setState(() => _isEmergencyContact = value),
            ),
          ],
        ),
      ),
    );
  }
}
