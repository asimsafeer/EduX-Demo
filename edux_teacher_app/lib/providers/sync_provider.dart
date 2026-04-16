/// EduX Teacher App - Sync Provider
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/sync_models.dart';
import '../services/discovery_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

part 'sync_provider.g.dart';

/// Sync state
class SyncState {
  final bool isDiscovering;
  final bool isSyncing;
  final List<DiscoveredServer> discoveredServers;
  final String? currentServerIp;
  final int? currentServerPort;
  final bool isConnected;
  final DateTime? lastSyncTime;
  final int pendingCount;
  final String? error;

  const SyncState({
    this.isDiscovering = false,
    this.isSyncing = false,
    this.discoveredServers = const [],
    this.currentServerIp,
    this.currentServerPort,
    this.isConnected = false,
    this.lastSyncTime,
    this.pendingCount = 0,
    this.error,
  });

  SyncState copyWith({
    bool? isDiscovering,
    bool? isSyncing,
    List<DiscoveredServer>? discoveredServers,
    String? currentServerIp,
    int? currentServerPort,
    bool? isConnected,
    DateTime? lastSyncTime,
    int? pendingCount,
    String? error,
  }) {
    return SyncState(
      isDiscovering: isDiscovering ?? this.isDiscovering,
      isSyncing: isSyncing ?? this.isSyncing,
      discoveredServers: discoveredServers ?? this.discoveredServers,
      currentServerIp: currentServerIp ?? this.currentServerIp,
      currentServerPort: currentServerPort ?? this.currentServerPort,
      isConnected: isConnected ?? this.isConnected,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingCount: pendingCount ?? this.pendingCount,
      error: error,
    );
  }
}

/// Sync provider
@Riverpod(keepAlive: true)
class Sync extends _$Sync {
  late AppDatabase _db;
  late DiscoveryService _discoveryService;

  @override
  SyncState build() {
    _db = ref.read(databaseProvider);
    _discoveryService = DiscoveryService();

    // Load saved server config and pending count
    _loadSavedConfig();

    return const SyncState();
  }

  /// Load saved server configuration
  Future<void> _loadSavedConfig() async {
    final serverIp = await _db.getConfig(ConfigKeys.serverIp);
    final serverPort = await _db.getConfig(ConfigKeys.serverPort);
    final lastSync = await _db.getConfig(ConfigKeys.lastSync);
    final pendingCount = await _db.getPendingCount();

    state = SyncState(
      currentServerIp: serverIp,
      currentServerPort: serverPort != null ? int.tryParse(serverPort) : null,
      lastSyncTime: lastSync != null ? DateTime.tryParse(lastSync) : null,
      pendingCount: pendingCount,
    );

    // Check if server is reachable
    if (serverIp != null && serverPort != null) {
      _checkConnection(serverIp, int.tryParse(serverPort) ?? 8181);
    }
  }

  /// Check if server is reachable
  Future<void> _checkConnection(String ip, int port) async {
    final isReachable = await _discoveryService.isServerReachable(ip, port);
    state = state.copyWith(isConnected: isReachable);
  }

  /// Discover servers on the network
  Future<void> discoverServers() async {
    state = state.copyWith(isDiscovering: true, error: null);

    try {
      // First try mDNS discovery
      var servers = await _discoveryService.discoverServers(
        timeout: const Duration(seconds: 5),
      );

      // If mDNS fails, try network scan as fallback
      if (servers.isEmpty) {
        servers = await _discoveryService.scanNetwork(
          timeout: const Duration(milliseconds: 300),
        );
      }

      state = state.copyWith(
        isDiscovering: false,
        discoveredServers: servers,
      );
    } catch (e) {
      state = state.copyWith(
        isDiscovering: false,
        error: 'Discovery failed: $e',
      );
    }
  }

  /// Test connection to a specific server
  Future<bool> testConnection(String ip, int port) async {
    final status = await _discoveryService.testConnection(ip, port);
    return status != null;
  }

  /// Set server manually
  Future<void> setServer(String ip, int port) async {
    await _db.setConfig(ConfigKeys.serverIp, ip);
    await _db.setConfig(ConfigKeys.serverPort, port.toString());

    state = state.copyWith(
      currentServerIp: ip,
      currentServerPort: port,
    );

    // Test connection
    await _checkConnection(ip, port);

    // Reinitialize sync service
    final syncService = ref.read(syncServiceProvider);
    await syncService.initialize(ip, port);
  }

  /// Sync attendance to server
  Future<SyncResult> syncAttendance() async {
    state = state.copyWith(isSyncing: true, error: null);

    try {
      final syncService = ref.read(syncServiceProvider);

      // Reinitialize if needed
      if (!syncService.isInitialized) {
        final success = await syncService.reinitialize();
        if (!success) {
          state = state.copyWith(
            isSyncing: false,
            error: 'Server not configured. Please log in again.',
          );
          return const SyncResult(
            success: false,
            processed: 0,
            message: 'Server not configured',
          );
        }
      }

      final result = await syncService.syncAttendance();

      // Refresh pending count
      final pendingCount = await _db.getPendingCount();

      // Update last sync time if successful
      DateTime? lastSyncTime;
      if (result.success) {
        lastSyncTime = DateTime.now();
        await _db.setConfig(
            ConfigKeys.lastSync, lastSyncTime.toIso8601String());
      }

      state = state.copyWith(
        isSyncing: false,
        pendingCount: pendingCount,
        lastSyncTime: lastSyncTime,
        error: result.success ? null : result.message,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
      return SyncResult(
        success: false,
        processed: 0,
        message: e.toString(),
      );
    }
  }

  /// Refresh pending count
  Future<void> refreshPendingCount() async {
    final pendingCount = await _db.getPendingCount();
    state = state.copyWith(pendingCount: pendingCount);
  }

  /// Clear discovered servers
  void clearDiscoveredServers() {
    state = state.copyWith(discoveredServers: []);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// FIXED: Check data integrity and handle academic year mismatches
  Future<DataIntegrityReport> checkDataIntegrity() async {
    try {
      final syncService = ref.read(syncServiceProvider);
      
      if (!syncService.isInitialized) {
        return const DataIntegrityReport(
          mismatches: [],
          missingStudents: [],
          totalClasses: 0,
        );
      }
      
      final report = await syncService.validateDataIntegrity();
      
      // If academic year mismatch detected, clear cache and trigger re-sync
      if (report.shouldClearCache) {
        debugPrint('[Sync] Academic year mismatch detected. Clearing cache...');
        await syncService.clearAllCache();
        
        // Update state to show re-login needed
        state = state.copyWith(
          error: 'Academic year changed. Please log in again to refresh data.',
          isConnected: false,
        );
      }
      
      return report;
    } catch (e) {
      debugPrint('[Sync] Error checking data integrity: $e');
      return const DataIntegrityReport(
        mismatches: [],
        missingStudents: [],
        totalClasses: 0,
      );
    }
  }
}

/// Discovery service provider
@Riverpod(keepAlive: true)
DiscoveryService discoveryService(Ref ref) {
  return DiscoveryService();
}

/// Is online provider (network connectivity)
@riverpod
Future<bool> isOnline(Ref ref) async {
  final discoveryService = ref.watch(discoveryServiceProvider);
  return await discoveryService.isOnWifi();
}

/// Can sync provider (checks all conditions)
@riverpod
Future<bool> canSync(Ref ref) async {
  final syncState = ref.watch(syncProvider);
  final isOnline = await ref.watch(isOnlineProvider.future);

  return isOnline &&
      syncState.isConnected &&
      syncState.pendingCount > 0 &&
      !syncState.isSyncing;
}
