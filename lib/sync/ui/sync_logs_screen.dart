/// EduX School Management System
/// Sync logs screen for viewing device sync history
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/core.dart';
import '../../database/database.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Screen to view sync logs for a device
class SyncLogsScreen extends StatefulWidget {
  final DeviceInfoModel device;

  const SyncLogsScreen({
    super.key,
    required this.device,
  });

  @override
  State<SyncLogsScreen> createState() => _SyncLogsScreenState();
}

class _SyncLogsScreenState extends State<SyncLogsScreen> {
  late Future<List<SyncLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    final service = SyncDeviceService.instance();
    _logsFuture = service.getDeviceLogs(widget.device.deviceId, limit: 100);
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.device.displayName} - Logs'),
            Text(
              widget.device.teacherName,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refreshLogs,
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<SyncLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Failed to load logs: ${snapshot.error}',
              onRetry: _refreshLogs,
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return AppEmptyState(
              icon: LucideIcons.fileText,
              title: 'No Sync Logs',
              description: 'No sync activity has been recorded for this device yet.',
              actionText: 'Refresh',
              onAction: _refreshLogs,
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshLogs,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogCard(log);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(SyncLog log) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case 'success':
        statusColor = AppColors.success;
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'partial':
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.alertCircle;
        break;
      case 'failed':
        statusColor = AppColors.error;
        statusIcon = LucideIcons.xCircle;
        break;
      default:
        statusColor = AppColors.textTertiary;
        statusIcon = LucideIcons.helpCircle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getSyncTypeDisplay(log.syncType),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                dateFormat.format(log.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: LucideIcons.fileText,
                label: '${log.recordsCount} records',
              ),
              const SizedBox(width: 8),
              _buildStatusChip(log.status),
            ],
          ),
          if (log.errorMessage != null && log.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'success':
        color = AppColors.success;
        label = 'Success';
        break;
      case 'partial':
        color = AppColors.warning;
        label = 'Partial';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'Failed';
        break;
      default:
        color = AppColors.textTertiary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getSyncTypeDisplay(String type) {
    switch (type) {
      case 'upload':
        return 'Attendance Upload';
      case 'download':
        return 'Data Download';
      case 'full':
        return 'Full Sync';
      default:
        return type;
    }
  }
}

/// All sync logs screen (for admin view)
class AllSyncLogsScreen extends StatefulWidget {
  const AllSyncLogsScreen({super.key});

  @override
  State<AllSyncLogsScreen> createState() => _AllSyncLogsScreenState();
}

class _AllSyncLogsScreenState extends State<AllSyncLogsScreen> {
  late Future<List<SyncLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    final service = SyncDeviceService.instance();
    _logsFuture = service.getAllLogs(limit: 200);
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sync Logs'),
        actions: [
          IconButton(
            onPressed: _refreshLogs,
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<SyncLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Failed to load logs: ${snapshot.error}',
              onRetry: _refreshLogs,
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const AppEmptyState(
              icon: LucideIcons.fileText,
              title: 'No Sync Logs',
              description: 'No sync activity has been recorded yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshLogs,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogListTile(log);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogListTile(SyncLog log) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case 'success':
        statusColor = AppColors.success;
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'partial':
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.alertCircle;
        break;
      case 'failed':
        statusColor = AppColors.error;
        statusIcon = LucideIcons.xCircle;
        break;
      default:
        statusColor = AppColors.textTertiary;
        statusIcon = LucideIcons.helpCircle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          '${log.syncType.toUpperCase()} - ${log.recordsCount} records',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          dateFormat.format(log.createdAt),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        trailing: _buildStatusChip(log.status),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'success':
        color = AppColors.success;
        label = 'Success';
        break;
      case 'partial':
        color = AppColors.warning;
        label = 'Partial';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'Failed';
        break;
      default:
        color = AppColors.textTertiary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
