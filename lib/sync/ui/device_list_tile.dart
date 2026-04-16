/// EduX School Management System
/// Device list tile widget for sync management
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/core.dart';
import '../models/models.dart';

/// List tile widget for displaying a sync device
class DeviceListTile extends StatelessWidget {
  final DeviceInfoModel device;
  final VoidCallback? onRevoke;
  final VoidCallback? onEnable;
  final VoidCallback? onDelete;
  final VoidCallback? onViewLogs;

  const DeviceListTile({
    super.key,
    required this.device,
    this.onRevoke,
    this.onEnable,
    this.onDelete,
    this.onViewLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildDeviceIcon(),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    device.displayName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Teacher: ${device.teacherName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last sync: ${device.formattedLastSync}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (device.lastIpAddress != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        LucideIcons.globe,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.lastIpAddress!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: LucideIcons.fileText,
                  label: 'View Logs',
                  onTap: onViewLogs,
                ),
                if (device.isActive)
                  _buildActionButton(
                    icon: LucideIcons.ban,
                    label: 'Revoke',
                    color: AppColors.error,
                    onTap: onRevoke,
                  )
                else ...[
                  _buildActionButton(
                    icon: LucideIcons.checkCircle,
                    label: 'Enable',
                    color: AppColors.success,
                    onTap: onEnable,
                  ),
                  _buildActionButton(
                    icon: LucideIcons.trash2,
                    label: 'Delete',
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: device.isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        LucideIcons.smartphone,
        color: device.isActive ? AppColors.success : AppColors.error,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: device.isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: device.isActive ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            device.isActive ? 'Active' : 'Revoked',
            style: AppTextStyles.bodySmall.copyWith(
              color: device.isActive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: color),
      ),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// Empty state widget for when no devices are registered
class EmptyDevicesState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const EmptyDevicesState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: LucideIcons.smartphone,
      title: 'No Connected Devices',
      description:
          'Teacher mobile devices will appear here when they connect to this server.',
      actionText: 'Refresh',
      onAction: onRefresh,
    );
  }
}

/// Server status card widget
class ServerStatusCard extends StatelessWidget {
  final bool isRunning;
  final int port;
  final String? localIp;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;

  const ServerStatusCard({
    super.key,
    required this.isRunning,
    required this.port,
    this.localIp,
    this.onStart,
    this.onStop,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRunning
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isRunning ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isRunning ? 'Server Running' : 'Server Stopped',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isRunning)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onRestart,
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      tooltip: 'Restart',
                      color: AppColors.textSecondary,
                    ),
                    IconButton(
                      onPressed: onStop,
                      icon: const Icon(LucideIcons.square, size: 18),
                      tooltip: 'Stop',
                      color: AppColors.error,
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(LucideIcons.play, size: 16),
                  label: const Text('Start Server'),
                ),
            ],
          ),
          if (isRunning) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: LucideIcons.network,
              label: 'Port',
              value: port.toString(),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: LucideIcons.globe,
              label: 'Local IP',
              value: localIp ?? 'Unknown',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: LucideIcons.wifi,
              label: 'Status',
              value: 'Accepting connections',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
