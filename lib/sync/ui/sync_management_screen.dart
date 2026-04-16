/// EduX School Management System
/// Sync management screen for managing connected teacher devices
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/core.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../server/server.dart';
import 'device_list_tile.dart';
import 'sync_logs_screen.dart';

/// Sync management screen for managing connected devices
class SyncManagementScreen extends ConsumerStatefulWidget {
  const SyncManagementScreen({super.key});

  @override
  ConsumerState<SyncManagementScreen> createState() =>
      _SyncManagementScreenState();
}

class _SyncManagementScreenState extends ConsumerState<SyncManagementScreen> {
  final SyncServerManager _serverManager = SyncServerManager();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshDevices());
  }

  Future<void> _refreshDevices() async {
    ref.invalidate(syncDevicesProvider);
  }

  Future<void> _startServer() async {
    setState(() => _isLoading = true);
    try {
      await _serverManager.start();
      if (mounted) {
        AppToast.success(context, 'Server started successfully');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to start server: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _stopServer() async {
    setState(() => _isLoading = true);
    try {
      await _serverManager.stop();
      if (mounted) {
        AppToast.success(context, 'Server stopped');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to stop server: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restartServer() async {
    setState(() => _isLoading = true);
    try {
      await _serverManager.restart();
      if (mounted) {
        AppToast.success(context, 'Server restarted successfully');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to restart server: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _revokeDevice(DeviceInfoModel device) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revoke Device Access',
      message:
          'Are you sure you want to revoke access for "${device.displayName}"? '
          'The teacher will no longer be able to sync from this device.',
      confirmLabel: 'Revoke',
      isDestructive: true,
      icon: LucideIcons.ban,
    );

    if (confirmed) {
      try {
        final service = ref.read(syncDeviceServiceProvider);
        final success = await service.revokeDevice(device.id);

        if (success && mounted) {
          AppToast.success(context, 'Device access revoked');
          _refreshDevices();
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Failed to revoke device: $e');
        }
      }
    }
  }

  Future<void> _enableDevice(DeviceInfoModel device) async {
    try {
      final service = ref.read(syncDeviceServiceProvider);
      final success = await service.enableDevice(device.id);

      if (success && mounted) {
        AppToast.success(context, 'Device access enabled');
        _refreshDevices();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to enable device: $e');
      }
    }
  }

  Future<void> _deleteDevice(DeviceInfoModel device) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Device',
      message:
          'Are you sure you want to permanently delete "${device.displayName}"? '
          'This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: LucideIcons.trash2,
    );

    if (confirmed) {
      try {
        final service = ref.read(syncDeviceServiceProvider);
        final success = await service.deleteDevice(device.id);

        if (success && mounted) {
          AppToast.success(context, 'Device deleted');
          _refreshDevices();
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Failed to delete device: $e');
        }
      }
    }
  }

  void _viewDeviceLogs(DeviceInfoModel device) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SyncLogsScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(syncDevicesProvider);
    final serverStatus = _serverManager.getStatus();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            ServerStatusCard(
              isRunning: serverStatus['serverRunning'] as bool,
              port: serverStatus['port'] as int,
              localIp: serverStatus['localIp'] as String?,
              onStart: _isLoading ? null : _startServer,
              onStop: _isLoading ? null : _stopServer,
              onRestart: _isLoading ? null : _restartServer,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Connected Devices'),
            const SizedBox(height: 12),
            Expanded(
              child: devicesAsync.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return EmptyDevicesState(onRefresh: _refreshDevices);
                  }
                  return RefreshIndicator(
                    onRefresh: _refreshDevices,
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return DeviceListTile(
                          device: device,
                          onRevoke: () => _revokeDevice(device),
                          onEnable: () => _enableDevice(device),
                          onDelete: () => _deleteDevice(device),
                          onViewLogs: () => _viewDeviceLogs(device),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: AppLoadingIndicator()),
                error: (error, _) => AppErrorState(
                  message: 'Failed to load devices: $error',
                  onRetry: _refreshDevices,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected Devices',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage teacher mobile app connections',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _refreshDevices,
          icon: const Icon(LucideIcons.refreshCw),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
