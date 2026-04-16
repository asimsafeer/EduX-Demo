/// EduX School Management System
/// Staff Import Screen - Excel import wizard with preview
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../services/staff_import_service.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/staff_import_preview_table.dart';

enum ImportStep { selectFile, preview, import, complete }

/// Screen for bulk importing staff from Excel
class StaffImportScreen extends ConsumerStatefulWidget {
  const StaffImportScreen({super.key});

  @override
  ConsumerState<StaffImportScreen> createState() => _StaffImportScreenState();
}

class _StaffImportScreenState extends ConsumerState<StaffImportScreen> {
  ImportStep _currentStep = ImportStep.selectFile;
  String? _selectedFilePath;
  String? _selectedFileName;
  ImportPreviewResult? _previewResult;
  bool _isLoading = false;
  String? _errorMessage;
  ImportResult? _importResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Staff'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff'),
        ),
      ),
      body: Column(
        children: [
          // Stepper header
          _buildStepperHeader(theme),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildCurrentStep(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          _buildStepIndicator(1, 'Select File', ImportStep.selectFile, theme),
          _buildStepConnector(ImportStep.selectFile, theme),
          _buildStepIndicator(
            2,
            'Preview & Validate',
            ImportStep.preview,
            theme,
          ),
          _buildStepConnector(ImportStep.preview, theme),
          _buildStepIndicator(3, 'Import', ImportStep.import, theme),
          _buildStepConnector(ImportStep.import, theme),
          _buildStepIndicator(4, 'Complete', ImportStep.complete, theme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    int number,
    String label,
    ImportStep step,
    ThemeData theme,
  ) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep.index > step.index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    number.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(ImportStep afterStep, ThemeData theme) {
    final isCompleted = _currentStep.index > afterStep.index;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
        color: isCompleted
            ? Colors.green
            : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _currentStep == ImportStep.preview
                ? 'Validating file...'
                : 'Importing staff...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case ImportStep.selectFile:
        return _buildSelectFileStep(theme);
      case ImportStep.preview:
        return _buildPreviewStep(theme);
      case ImportStep.import:
        return _buildImportStep(theme);
      case ImportStep.complete:
        return _buildCompleteStep(theme);
    }
  }

  Widget _buildSelectFileStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Import Instructions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload an Excel file (.xlsx) with staff data. '
                    'The file should have the following columns:',
                  ),
                  const SizedBox(height: 12),
                  _buildColumnList(theme),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Template'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // File Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_selectedFileName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 48,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName!,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                'File selected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedFilePath = null;
                              _selectedFileName = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  InkWell(
                    onTap: _selectFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFileName != null
                                ? 'Select a different file'
                                : 'Click to select Excel file',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supports .xlsx files',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => context.go('/staff'),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _selectedFilePath != null ? _validateFile : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next: Preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnList(ThemeData theme) {
    final columns = [
      ('First Name', 'Required'),
      ('Last Name', 'Required'),
      ('Phone', 'Required'),
      ('Gender', 'male/female'),
      ('Designation', 'Required'),
      ('Role', 'Required - Must match system'),
      ('Joining Date', 'Optional'),
      ('Basic Salary', 'Optional'),
      ('Email', 'Optional'),
      ('CNIC', 'Optional'),
      ('Address', 'Optional'),
      ('Department', 'Optional'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: columns.map((col) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(col.$1, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text(
                '(${col.$2})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewStep(ThemeData theme) {
    if (_previewResult == null) {
      return const Center(child: Text('No preview data available'));
    }

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              _buildSummaryChip(
                Icons.people,
                '${_previewResult!.totalRows} Total Rows',
                theme,
              ),
              const SizedBox(width: 16),
              _buildSummaryChip(
                Icons.check_circle,
                '${_previewResult!.validRows} Valid',
                theme,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _buildSummaryChip(
                Icons.error,
                '${_previewResult!.errorRows} Errors',
                theme,
                color: _previewResult!.errorRows > 0 ? Colors.red : null,
              ),
              /*
              const Spacer(),
              if (_previewResult!.errors.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    // _showErrorsDialog();
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Errors'),
                ),
                */
            ],
          ),
        ),

        // Preview table
        Expanded(
          child: StaffImportPreviewTable(
            previewItems: _previewResult!.previewItems,
            errors: _previewResult!.errors,
          ),
        ),

        // Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = ImportStep.selectFile;
                    _previewResult = null;
                  });
                },
                child: const Text('Back'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _previewResult!.validRows > 0 ? _startImport : null,
                icon: const Icon(Icons.upload),
                label: Text('Import ${_previewResult!.validRows} Staff'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(
    IconData icon,
    String label,
    ThemeData theme, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportStep(ThemeData theme) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text('Importing Staff...', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Please wait while we import the staff members.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteStep(ThemeData theme) {
    final result = _importResult;
    if (result == null) {
      return const Center(child: Text('No import result'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Import Complete!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.successCount} staff members imported successfully',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Successful',
                  result.successCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                  theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Failed',
                  result.failedCount.toString(),
                  Icons.error,
                  Colors.red,
                  theme,
                ),
              ),
            ],
          ),

          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Errors',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...result.errors
                        .take(10)
                        .map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(error)),
                              ],
                            ),
                          ),
                        ),
                    if (result.errors.length > 10)
                      Text(
                        '... and ${result.errors.length - 10} more errors',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = ImportStep.selectFile;
                    _selectedFilePath = null;
                    _selectedFileName = null;
                    _previewResult = null;
                    _importResult = null;
                  });
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Import More'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(staffListProvider);
                  ref.invalidate(staffCountProvider);
                  ref.invalidate(teachersProvider);
                  ref.invalidate(dashboardProvider);
                  context.go('/staff');
                },
                icon: const Icon(Icons.list),
                label: const Text('View Staff List'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Header row
      final headers = [
        'First Name',
        'Last Name',
        'Phone',
        'Gender (male/female)',
        'Designation',
        'Role',
        'Joining Date (DD/MM/YYYY)',
        'Basic Salary',
        'Email',
        'CNIC',
        'Address',
        'Department',
        'Bank Name',
        'Account Number',
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = xl.TextCellValue(
          headers[i],
        );
      }

      // Add a sample row
      final sampleRow = [
        'Jane',
        'Doe',
        '03009876543',
        'female',
        'Teacher',
        'Teacher',
        '01/01/2024',
        '50000',
        'jane@example.com',
        '35201-1234567-8',
        '456 Avenue',
        'Science',
        'Bank ABC',
        '1234567890',
      ];

      for (var i = 0; i < sampleRow.length; i++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            .value = xl.TextCellValue(
          sampleRow[i],
        );
      }

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to encode Excel file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await FilePicker.platform.saveFile(
        fileName: 'staff_import_template.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: kIsWeb ? Uint8List.fromList(fileBytes) : null,
      );

      if (result != null) {
        if (!kIsWeb) {
          final file = File(result);
          await file.writeAsBytes(fileBytes);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedFilePath = result.files.first.path;
            _selectedFileName = result.files.first.name;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to select file: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _validateFile() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = File(_selectedFilePath!);
      final bytes = await file.readAsBytes();

      final importService = ref.read(staffImportServiceProvider);
      final previewResult = await importService.previewImport(bytes);

      if (mounted) {
        setState(() {
          _previewResult = previewResult;
          _currentStep = ImportStep.preview;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to validate file: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startImport() async {
    if (_previewResult == null) return;

    setState(() {
      _currentStep = ImportStep.import;
      _isLoading = true;
    });

    try {
      final file = File(_selectedFilePath!);
      final bytes = await file.readAsBytes();
      final userState = ref.read(currentUserProvider);
      final userId = userState!.id;

      final importService = ref.read(staffImportServiceProvider);
      final result = await importService.importStaff(bytes, userId: userId);

      if (mounted) {
        setState(() {
          _importResult = result;
          _currentStep = ImportStep.complete;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Import failed: ${e.toString()}';
          _isLoading = false;
          _currentStep = ImportStep.preview;
        });
      }
    }
  }
}
