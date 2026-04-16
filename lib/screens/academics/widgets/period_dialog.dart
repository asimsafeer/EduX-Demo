/// EduX School Management System
/// Period Dialog - Add/Edit period definition
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../database/app_database.dart';
import '../../../providers/academics_provider.dart';
// import '../../../repositories/period_definition_repository.dart'; // Unused

class PeriodDialog extends ConsumerStatefulWidget {
  final String academicYear;
  final PeriodDefinition? period;

  const PeriodDialog({super.key, required this.academicYear, this.period});

  @override
  ConsumerState<PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends ConsumerState<PeriodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _periodNumberController = TextEditingController();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isBreak = false;
  bool _isSubmitting = false;

  bool get isEditing => widget.period != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.period!.name;
      _periodNumberController.text = widget.period!.periodNumber.toString();
      _startTime = _parseTime(widget.period!.startTime);
      _endTime = _parseTime(widget.period!.endTime);
      _isBreak = widget.period!.isBreak;
    } else {
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 9, minute: 0);
      // Default to next period number logic could be added here, but simplest to let user or left generic
      _periodNumberController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _periodNumberController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes - startMinutes;
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final pickedKey = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedKey != null) {
      setState(() {
        if (isStart) {
          _startTime = pickedKey;
          // Auto-adjust end time if it becomes before start time
          if (_endTime.hour < _startTime.hour ||
              (_endTime.hour == _startTime.hour &&
                  _endTime.minute < _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: _startTime.hour + 1,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = pickedKey;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = _calculateDuration();
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier = ref.read(periodDefinitionOperationProvider.notifier);
    final periodNumber = int.parse(_periodNumberController.text);

    // Auto-assign display order if not editing (just append to end logic ideally, or use period number)
    final displayOrder = isEditing ? widget.period!.displayOrder : periodNumber;

    bool success;
    if (isEditing) {
      success = await notifier.updatePeriod(
        id: widget.period!.id,
        academicYear: widget.academicYear,
        name: _nameController.text,
        periodNumber: periodNumber,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        durationMinutes: duration,
        isBreak: _isBreak,
      );
    } else {
      success = await notifier.createPeriod(
        periodNumber: periodNumber,
        name: _nameController.text,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        durationMinutes: duration,
        displayOrder: displayOrder, // Simplified, ideally should find max+1
        academicYear: widget.academicYear,
        isBreak: _isBreak,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Edit Period' : 'Add Period',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _periodNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Period #',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 56, // Match text field height
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isBreak,
                              onChanged: (v) => setState(() => _isBreak = v!),
                            ),
                            const Text('Is Break?'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (e.g., Period 1, Lunch)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        'Start Time',
                        _startTime,
                        () => _selectTime(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        'End Time',
                        _endTime,
                        () => _selectTime(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${_calculateDuration()} minutes',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatTime(time), style: const TextStyle(fontSize: 16)),
            const Icon(LucideIcons.clock, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
