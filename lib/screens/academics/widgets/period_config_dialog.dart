/// EduX School Management System
/// Period Configuration Dialog - Manage School Periods
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../database/app_database.dart';
import '../../../providers/academics_provider.dart';
// import '../../../repositories/period_definition_repository.dart'; // Removed unused import or if needed keep it but it says unused

/// Dialog for managing period definitions (timings, breaks, order)
class PeriodConfigDialog extends ConsumerStatefulWidget {
  final String academicYear;

  const PeriodConfigDialog({super.key, required this.academicYear});

  @override
  ConsumerState<PeriodConfigDialog> createState() => _PeriodConfigDialogState();
}

class _PeriodConfigDialogState extends ConsumerState<PeriodConfigDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for adding/editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isBreak = false;

  // Editing state
  int? _editingId;
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _isAdding = false;
      _nameController.clear();
      _durationController.clear();
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _isBreak = false;
    });
  }

  void _startEditing(PeriodDefinition period) {
    setState(() {
      _editingId = period.id;
      _isAdding = false;
      _nameController.text = period.name;
      _durationController.text = period.durationMinutes.toString();
      _isBreak = period.isBreak;

      final parts = period.startTime.split(':');
      if (parts.length == 2) {
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Calculate end time
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final duration = int.parse(_durationController.text);
    final endMinutes = startMinutes + duration;

    final endHour = (endMinutes ~/ 60) % 24;
    final endMinute = endMinutes % 60;

    final startTimeStr =
        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

    final notifier = ref.read(periodDefinitionOperationProvider.notifier);
    bool success = false;

    if (_editingId != null) {
      // Update existing
      success = await notifier.updatePeriod(
        id: _editingId!,
        academicYear: widget.academicYear,
        name: _nameController.text.trim(),
        startTime: startTimeStr,
        endTime: endTimeStr,
        durationMinutes: duration,
        isBreak: _isBreak,
      );
    } else {
      // Create new
      // Default period number will be handled by repo based on order
      success = await notifier.createPeriod(
        academicYear: widget.academicYear,
        name: _nameController.text.trim(),
        startTime: startTimeStr,
        endTime: endTimeStr,
        durationMinutes: duration,
        isBreak: _isBreak,
        periodNumber: 99, // Temp, will be reordered
        displayOrder: 99,
      );
    }

    if (success && mounted) {
      _resetForm();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() => _startTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodsAsync = ref.watch(
      periodDefinitionsProvider(widget.academicYear),
    );
    final operationState = ref.watch(periodDefinitionOperationProvider);

    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Period Configuration',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      'Academic Year: ${widget.academicYear}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const Divider(),

            // Error handling
            if (operationState.error != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                color: theme.colorScheme.errorContainer,
                child: Text(
                  operationState.error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),

            // Main Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: List of periods
                  Expanded(
                    flex: 3,
                    child: periodsAsync.when(
                      data: (periods) => _buildPeriodsList(context, periods),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ),
                  const VerticalDivider(width: 32),
                  // Right: Add/Edit Form
                  Expanded(flex: 2, child: _buildForm(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodsList(
    BuildContext context,
    List<PeriodDefinition> periods,
  ) {
    final theme = Theme.of(context);

    if (periods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.clock, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No periods defined'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                ref
                    .read(periodDefinitionOperationProvider.notifier)
                    .seedDefaults(widget.academicYear);
              },
              child: const Text('Load Defaults'),
            ),
            const SizedBox(height: 8),
            const Text('(8 periods + breaks)'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // List Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              SizedBox(width: 32), // Drag handle space
              Expanded(
                flex: 2,
                child: Text(
                  '# Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 30), // Actions space
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Reorderable List
        Expanded(
          child: ReorderableListView.builder(
            itemCount: periods.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = periods.removeAt(oldIndex);
              periods.insert(newIndex, item);

              // Only IDs needed for reorder
              final ids = periods.map((p) => p.id).toList();
              // Original display orders not strictly needed if we just pass IDs in new order
              // but logic in repo might need clarification.
              // Assuming repo reorders based on ID list order.
              final newOrders = List.generate(periods.length, (i) => i + 1);

              ref
                  .read(periodDefinitionOperationProvider.notifier)
                  .reorderPeriods(ids, newOrders, widget.academicYear);
            },
            itemBuilder: (context, index) {
              final period = periods[index];
              final isSelected = _editingId == period.id;

              return Container(
                key: ValueKey(period.id),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : period.isBreak
                      ? Colors.orange.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.gripVertical, size: 16),
                  title: Text(
                    period.name,
                    style: TextStyle(
                      fontWeight: period.isBreak
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontStyle: period.isBreak
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${period.startTime} - ${period.endTime} (${period.durationMinutes}m)',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.edit2, size: 16),
                        onPressed: () => _startEditing(period),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete Period?'),
                              content: Text('Delete "${period.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref
                                .read(
                                  periodDefinitionOperationProvider.notifier,
                                )
                                .deletePeriod(period.id, widget.academicYear);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    // Show either "Add New" button or the Form
    if (!_isAdding && _editingId == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: () {
            setState(() {
              _isAdding = true;
              _resetForm();
              _isAdding = true; // reset clears it, so set again
            });
          },
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add Period'),
        ),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editingId != null ? 'Edit Period' : 'New Period',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Period 1, Logic Break',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Start Time
            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_startTime.format(context)),
                    const Icon(LucideIcons.clock, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Duration
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Is Break Checkbox
            CheckboxListTile(
              title: const Text('Is Break?'),
              subtitle: const Text('Timetable slots cannot be assigned'),
              value: _isBreak,
              onChanged: (v) => setState(() => _isBreak = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _resetForm, child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _handleSubmit,
                  child: Text(_editingId != null ? 'Update' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
