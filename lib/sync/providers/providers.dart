/// EduX School Management System
/// Sync providers for Riverpod
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../server/server.dart';
import '../services/services.dart';

/// Provider for sync device service
final syncDeviceServiceProvider = Provider<SyncDeviceService>((ref) {
  return SyncDeviceService.instance();
});

/// Provider for sync processor
final syncProcessorProvider = Provider<SyncProcessor>((ref) {
  return SyncProcessor.instance();
});

/// Provider for sync server manager
final syncServerManagerProvider = Provider<SyncServerManager>((ref) {
  return SyncServerManager();
});

/// Provider for sync server status
final syncServerStatusProvider = StreamProvider<Map<String, dynamic>>((
  ref,
) async* {
  final manager = ref.watch(syncServerManagerProvider);

  while (true) {
    yield manager.getStatus();
    await Future.delayed(const Duration(seconds: 2));
  }
});

/// Provider for sync events from the server
final syncEventsProvider = StreamProvider<SyncResponse>((ref) {
  final manager = ref.watch(syncServerManagerProvider);
  return manager.onSyncEvent;
});

/// Provider for sync devices list
final syncDevicesProvider = FutureProvider<List<DeviceInfoModel>>((ref) async {
  final service = ref.watch(syncDeviceServiceProvider);
  final devices = await service.getAllDevices();

  // Convert to DeviceInfoModel
  final result = <DeviceInfoModel>[];
  for (final device in devices) {
    // Get the actual device record for additional fields
    final deviceRecord = await service.getDeviceById(device.id);
    if (deviceRecord != null) {
      result.add(
        DeviceInfoModel.fromDeviceAndTeacher(deviceRecord, device.teacherName),
      );
    }
  }

  return result;
});

/// Provider for device count
final deviceCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(syncDeviceServiceProvider);
  return await service.getDeviceCount();
});

/// Provider for active device count
final activeDeviceCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(syncDeviceServiceProvider);
  return await service.getActiveDeviceCount();
});

/// Provider for a specific device's logs
final deviceLogsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  deviceId,
) async {
  final service = ref.watch(syncDeviceServiceProvider);
  return await service.getDeviceLogs(deviceId);
});

/// Provider to check if sync server is running
final isSyncServerRunningProvider = Provider<bool>((ref) {
  final manager = ref.watch(syncServerManagerProvider);
  return manager.isServerRunning;
});

/// Provider for server address
final syncServerAddressProvider = Provider<String?>((ref) {
  final manager = ref.watch(syncServerManagerProvider);
  if (!manager.isServerRunning) return null;
  final ip = manager.localIp ?? 'localhost';
  return 'http://$ip:${manager.port}';
});
