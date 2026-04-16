/// EduX School Management System
/// Backup Provider - Manages backup list state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../services/services.dart';

/// Backup service provider (singleton)
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService.instance();
});

/// Backup list provider
final backupListProvider = FutureProvider<List<Backup>>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getBackups();
});

/// Most recent backup provider
final mostRecentBackupProvider = FutureProvider<Backup?>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getMostRecentBackup();
});

/// Backup count provider
final backupCountProvider = FutureProvider<int>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getBackupCount();
});

/// Backup by ID provider
final backupByIdProvider = FutureProvider.family<Backup?, int>((ref, id) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getBackupById(id);
});
