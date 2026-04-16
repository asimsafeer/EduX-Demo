/// EduX School Management System
/// Student Form Screen - Add/Edit student details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/student_provider.dart';
import '../../services/student_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_loading_indicator.dart';

/// Screen for adding or editing a student
class StudentFormScreen extends ConsumerStatefulWidget {
  final int? studentId; // null for new student

  const StudentFormScreen({super.key, this.studentId});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();

  final _fatherNameController = TextEditingController();
  final _fatherOccupationController = TextEditingController(); // Added
  final _castController = TextEditingController(); // Added
  final _motherTongueController = TextEditingController(); // Added
  final _admissionNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  final _rollNumberController = TextEditingController();

  DateTime _admissionDate = DateTime.now();
  DateTime? _dateOfBirth;
  String _gender = 'male';
  String _status = 'active';
  String? _bloodGroup;
  String? _religion;
  String _nationality = 'Pakistani';
  int? _selectedClassId;
  int? _selectedSectionId;

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isRollNumberManual = false;
  int? _originalClassId;
  int? _originalSectionId;

  bool get isEditing => widget.studentId != null;

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _fatherOccupationController.dispose();
    _castController.dispose();
    _motherTongueController.dispose();
    _admissionNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchNextRollNumber() async {
    if (_isRollNumberManual) return;

    final shouldFetch =
        !isEditing ||
        (_selectedClassId != _originalClassId ||
            _selectedSectionId != _originalSectionId);

    if (shouldFetch && _selectedClassId != null && _selectedSectionId != null) {
      try {
        final repo = ref.read(enrollmentRepositoryProvider);
        final nextRoll = await repo.generateNextRollNumber(
          _selectedClassId!,
          _selectedSectionId!,
        );
        if (mounted) {
          setState(() {
            _rollNumberController.text = nextRoll;
          });
        }
      } catch (e) {
        debugPrint('Error fetching next roll number: $e');
      }
    }
  }

  Future<void> _loadStudentData() async {
    if (isEditing && !_isInitialized) {
      final studentData = await ref.read(
        studentByIdProvider(widget.studentId!).future,
      );
      if (studentData != null && mounted) {
        final student = studentData.student;
        final enrollment = studentData.currentEnrollment;
        setState(() {
          _studentNameController.text = student.studentName;
          _fatherNameController.text = student.fatherName ?? '';
          _fatherOccupationController.text = student.fatherOccupation ?? '';
          _castController.text = student.cast ?? '';
          _motherTongueController.text = student.motherTongue ?? '';
          _admissionNumberController.text = student.admissionNumber;
          _phoneController.text = student.phone ?? '';
          _emailController.text = student.email ?? '';
          _cnicController.text = student.cnic ?? '';
          _addressController.text = student.address ?? '';
          _cityController.text = student.city ?? '';
          _notesController.text = student.notes ?? '';
          _admissionDate = student.admissionDate;
          _dateOfBirth = student.dateOfBirth;
          _gender = student.gender;
          _status = student.status; // Load status
          _bloodGroup = student.bloodGroup;
          _religion = student.religion;
          _nationality = student.nationality;
          if (enrollment != null) {
            _selectedClassId = enrollment.classId;
            _selectedSectionId = enrollment.sectionId;
            _originalClassId = enrollment.classId;
            _originalSectionId = enrollment.sectionId;
            _rollNumberController.text = enrollment.rollNumber ?? '';
          }
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isAdmissionDate) async {
    final initialDate = isAdmissionDate
        ? _admissionDate
        : (_dateOfBirth ??
              DateTime.now().subtract(const Duration(days: 365 * 10)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isAdmissionDate) {
          _admissionDate = picked;
        } else {
          _dateOfBirth = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class and section'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current academic year
      final academicYear = await ref.read(currentAcademicYearProvider.future);

      final formData = StudentFormData(
        studentName: _studentNameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        fatherOccupation: _fatherOccupationController.text.trim().isEmpty
            ? null
            : _fatherOccupationController.text.trim(),
        cast: _castController.text.trim().isEmpty
            ? null
            : _castController.text.trim(),
        motherTongue: _motherTongueController.text.trim().isEmpty
            ? null
            : _motherTongueController.text.trim(),
        admissionNumber: _admissionNumberController.text.isEmpty
            ? null
            : _admissionNumberController.text.trim(),
        admissionDate: _admissionDate,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        bloodGroup: _bloodGroup,
        religion: _religion,
        nationality: _nationality,
        cnic: _cnicController.text.isEmpty ? null : _cnicController.text.trim(),
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.isEmpty ? null : _cityController.text.trim(),
        phone: _phoneController.text.isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.isEmpty
            ? null
            : _emailController.text.trim(),
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        classId: _selectedClassId!,
        sectionId: _selectedSectionId!,
        academicYear: academicYear,
        rollNumber: _rollNumberController.text.isEmpty
            ? null
            : _rollNumberController.text.trim(),
        status: _status, // Pass status
      );

      if (isEditing) {
        final success = await ref
            .read(studentOperationProvider.notifier)
            .updateStudent(widget.studentId!, formData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/students/${widget.studentId}');
        }
      } else {
        final studentId = await ref
            .read(studentOperationProvider.notifier)
            .createStudent(formData);
        if (studentId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/students/$studentId');
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
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Load student data if editing
    if (isEditing && !_isInitialized) {
      _loadStudentData();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add New Student'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/students'),
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
                    _buildPersonalInfoSection(dateFormat),

                    const SizedBox(height: 32),

                    // Academic Information Section
                    _buildSectionHeader('Academic Information', Icons.school),
                    const SizedBox(height: 16),
                    _buildAcademicSection(dateFormat),

                    const SizedBox(height: 32),

                    // Contact Information Section
                    _buildSectionHeader('Contact Information', Icons.phone),
                    const SizedBox(height: 16),
                    _buildContactSection(),

                    const SizedBox(height: 32),

                    // Additional Information Section
                    _buildSectionHeader('Additional Information', Icons.info),
                    const SizedBox(height: 16),
                    _buildAdditionalSection(),

                    const SizedBox(height: 32),

                    // Submit Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.go('/students'),
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
                            isEditing ? 'Update Student' : 'Create Student',
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

  Widget _buildPersonalInfoSection(DateFormat dateFormat) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Student Name
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _studentNameController,
            decoration: const InputDecoration(
              labelText: 'Student Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Student name is required';
              }
              if (value.trim().length < 2) {
                return 'Minimum 2 characters';
              }
              return null;
            },
          ),
        ),

        // Father Name (Optional)
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _fatherNameController,
            decoration: const InputDecoration(
              labelText: 'Father Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Father Occupation
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _fatherOccupationController,
            decoration: const InputDecoration(
              labelText: 'Father Occupation',
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Gender
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _gender = value);
              }
            },
          ),
        ),

        // Date of Birth
        SizedBox(
          width: 200,
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, false),
              ),
            ),
            controller: TextEditingController(
              text: _dateOfBirth != null
                  ? dateFormat.format(_dateOfBirth!)
                  : '',
            ),
            onTap: () => _selectDate(context, false),
          ),
        ),

        // Blood Group
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String?>(
            initialValue: _bloodGroup,
            decoration: const InputDecoration(
              labelText: 'Blood Group',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Select')),
              DropdownMenuItem(value: 'A+', child: Text('A+')),
              DropdownMenuItem(value: 'A-', child: Text('A-')),
              DropdownMenuItem(value: 'B+', child: Text('B+')),
              DropdownMenuItem(value: 'B-', child: Text('B-')),
              DropdownMenuItem(value: 'AB+', child: Text('AB+')),
              DropdownMenuItem(value: 'AB-', child: Text('AB-')),
              DropdownMenuItem(value: 'O+', child: Text('O+')),
              DropdownMenuItem(value: 'O-', child: Text('O-')),
            ],
            onChanged: (value) => setState(() => _bloodGroup = value),
          ),
        ),

        // Religion
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _religion,
            decoration: const InputDecoration(
              labelText: 'Religion',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Select')),
              DropdownMenuItem(value: 'Islam', child: Text('Islam')),
              DropdownMenuItem(
                value: 'Christianity',
                child: Text('Christianity'),
              ),
              DropdownMenuItem(value: 'Hinduism', child: Text('Hinduism')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) => setState(() => _religion = value),
          ),
        ),

        // Nationality
        SizedBox(
          width: 180,
          child: TextFormField(
            initialValue: _nationality,
            decoration: const InputDecoration(
              labelText: 'Nationality',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _nationality = value,
          ),
        ),

        // Cast
        SizedBox(
          width: 180,
          child: TextFormField(
            controller: _castController,
            decoration: const InputDecoration(
              labelText: 'Cast',
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Mother Tongue
        SizedBox(
          width: 180,
          child: TextFormField(
            controller: _motherTongueController,
            decoration: const InputDecoration(
              labelText: 'Mother Tongue',
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // CNIC
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _cnicController,
            decoration: const InputDecoration(
              labelText: 'CNIC/B-Form',
              hintText: 'XXXXX-XXXXXXX-X',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicSection(DateFormat dateFormat) {
    final classesAsync = ref.watch(classesProvider);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Admission Number
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _admissionNumberController,
            decoration: InputDecoration(
              labelText: isEditing ? 'Admission No *' : 'Admission No',
              hintText: isEditing ? '' : 'Auto-generated if empty',
              border: const OutlineInputBorder(),
            ),
            enabled: !isEditing, // Can't change admission number when editing
          ),
        ),

        // Admission Date
        SizedBox(
          width: 200,
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Admission Date *',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, true),
              ),
            ),
            controller: TextEditingController(
              text: dateFormat.format(_admissionDate),
            ),
            onTap: () => _selectDate(context, true),
          ),
        ),

        // Class
        SizedBox(
          width: 200,
          child: classesAsync.when(
            data: (classes) => DropdownButtonFormField<int?>(
              initialValue: _selectedClassId,
              decoration: const InputDecoration(
                labelText: 'Class *',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Select Class'),
                ),
                ...classes.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                  _selectedSectionId = null; // Reset section
                  _rollNumberController.clear();
                });
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Text('Error loading classes'),
          ),
        ),

        // Section (dependent on class)
        if (_selectedClassId != null)
          SizedBox(
            width: 150,
            child: Consumer(
              builder: (context, ref, child) {
                final sectionsAsync = ref.watch(
                  sectionsByClassProvider(_selectedClassId!),
                );

                return sectionsAsync.when(
                  data: (sections) => DropdownButtonFormField<int?>(
                    initialValue: _selectedSectionId,
                    decoration: const InputDecoration(
                      labelText: 'Section *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Select'),
                      ),
                      ...sections.map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedSectionId = value);
                      if (value != null) {
                        _fetchNextRollNumber();
                      }
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const Text('Error'),
                );
              },
            ),
          ),

        // Roll Number
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: _rollNumberController,
            readOnly: !_isRollNumberManual,
            decoration: InputDecoration(
              labelText: 'Roll Number',
              border: const OutlineInputBorder(),
              helperText: _isRollNumberManual
                  ? 'Manual Entry'
                  : 'Auto-generated',
              suffixIcon: IconButton(
                icon: Icon(
                  _isRollNumberManual ? Icons.auto_awesome : Icons.edit,
                  size: 20,
                ),
                tooltip: _isRollNumberManual
                    ? 'Switch to Auto'
                    : 'Edit Manually',
                onPressed: () {
                  setState(() {
                    _isRollNumberManual = !_isRollNumberManual;
                    if (!_isRollNumberManual) {
                      _fetchNextRollNumber();
                    }
                  });
                },
              ),
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
              labelText: 'Phone',
              hintText: '03XX-XXXXXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
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

  Widget _buildAdditionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Dropdown (only when editing)
        if (isEditing) ...[
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Student Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: StudentStatus.all.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(StudentStatus.getDisplayName(status)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Any additional notes about the student...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
  }
}
