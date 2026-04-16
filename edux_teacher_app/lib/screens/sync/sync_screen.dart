/// EduX Teacher App - Sync Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classes_provider.dart';
import '../../providers/sync_provider.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(syncProvider.notifier).refreshPendingCount(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncProvider.notifier).refreshPendingCount();
        },
        child: CustomScrollView(
          slivers: [
            // Connection Status
            SliverToBoxAdapter(
              child: _buildConnectionCard(context, ref, syncState),
            ),

            // Sync Status
            SliverToBoxAdapter(
              child: _buildSyncStatusCard(context, ref, syncState),
            ),

            // Data Integrity Section
            SliverToBoxAdapter(
              child: _buildDataIntegrityCard(context, ref),
            ),

            // Instructions
            SliverToBoxAdapter(
              child: _buildInstructionsCard(context),
            ),

            // Padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(
      BuildContext context, WidgetRef ref, dynamic syncState) {
    final isConnected = syncState.isConnected;
    final serverIp = syncState.currentServerIp;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isConnected
            ? AppTheme.success .withValues(alpha: 0.1)
            : AppTheme.error .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? AppTheme.success .withValues(alpha: 0.3)
              : AppTheme.error .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppTheme.success .withValues(alpha: 0.2)
                      : AppTheme.error .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? AppTheme.success : AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Connected' : 'Not Connected',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isConnected ? AppTheme.success : AppTheme.error,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? 'Server: $serverIp'
                          : 'Connect to school WiFi and ensure server is running',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isConnected) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReconnectDialog(context, ref),
                icon: const Icon(Icons.link),
                label: const Text('Reconnect'),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSyncStatusCard(
      BuildContext context, WidgetRef ref, dynamic syncState) {
    final pendingCount = syncState.pendingCount;
    final lastSync = syncState.lastSyncTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),

          // Pending Records
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? AppTheme.warning .withValues(alpha: 0.1)
                      : AppTheme.success .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$pendingCount',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: pendingCount > 0
                              ? AppTheme.warning
                              : AppTheme.success,
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
                      pendingCount > 0 ? 'Records Pending' : 'All Synced',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pendingCount > 0
                          ? '$pendingCount attendance records ready to sync'
                          : 'Your attendance is up to date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (lastSync != null) ...[
            const Divider(height: 32),
            Row(
              children: [
                const Icon(
                  Icons.history,
                  size: 20,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last synced: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastSync)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ],

          if (pendingCount > 0) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: syncState.isSyncing || !syncState.isConnected
                    ? null
                    : () => _syncNow(context, ref),
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  syncState.isSyncing
                      ? 'Syncing...'
                      : 'Sync Now ($pendingCount)',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Sync',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            context,
            '1',
            'Connect to School WiFi',
            'Make sure your phone is connected to the same network as the main system.',
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            context,
            '2',
            'Mark Attendance',
            'Mark attendance for all your classes throughout the day.',
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            context,
            '3',
            'Sync at End of Day',
            'Tap "Sync Now" to upload all attendance records to the main system.',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildInstructionStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(syncProvider.notifier).syncAttendance();

    if (context.mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDataIntegrityCard(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Integrity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Check if all your class data is complete and up-to-date.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _checkDataIntegrity(context, ref),
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Check Data'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _repairData(context, ref),
                  icon: const Icon(Icons.build),
                  label: const Text('Repair Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Future<void> _checkDataIntegrity(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final syncService = ref.read(syncServiceProvider);
      final report = await syncService.validateDataIntegrity();

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        if (report.hasIssues) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  const Text('Data Issues Found'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found ${report.missingCount} classes with missing student data:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ...report.missingStudents.map((classSection) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.class_, color: AppTheme.error),
                      title: Text(classSection.displayName),
                      subtitle: Text('Expected ${classSection.totalStudents} students'),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ignore'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _repairData(context, ref);
                  },
                  child: const Text('Fix Now'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data is complete and up-to-date!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking data: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _repairData(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Repairing data...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );

    try {
      final fixedCount = await ref.read(classesProvider.notifier).fixMissingStudents();

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fixed data for $fixedCount classes'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error repairing data: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showReconnectDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => _ReconnectDialog(ref: ref),
    );
  }
}

class _ReconnectDialog extends StatefulWidget {
  final WidgetRef ref;

  const _ReconnectDialog({required this.ref});

  @override
  State<_ReconnectDialog> createState() => _ReconnectDialogState();
}

class _ReconnectDialogState extends State<_ReconnectDialog> {
  late final TextEditingController ipController;
  late final TextEditingController portController;

  @override
  void initState() {
    super.initState();
    ipController = TextEditingController();
    portController = TextEditingController(text: '8181');
  }

  @override
  void dispose() {
    ipController.dispose();
    portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reconnect to Server'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ipController,
            decoration: const InputDecoration(
              labelText: 'Server IP',
              hintText: '192.168.1.100',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '8181',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final ip = ipController.text.trim();
            final port = int.tryParse(portController.text.trim()) ?? 8181;

            if (ip.isNotEmpty) {
              await widget.ref.read(syncProvider.notifier).setServer(ip, port);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server configuration updated'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
