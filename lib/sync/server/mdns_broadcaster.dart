/// EduX School Management System
/// mDNS service broadcaster for teacher app discovery
library;

import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

import '../models/models.dart';
import 'sync_server.dart';

/// mDNS service broadcaster for teacher app auto-discovery
///
/// Note: mDNS implementation is platform-dependent.
/// This is a simplified implementation that provides network info.
class MdnsBroadcaster {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  String? _localIp;
  String? get localIp => _localIp;

  // ============================================
  // LIFECYCLE
  // ============================================

  /// Start broadcasting mDNS service
  Future<void> start({int port = SyncServer.defaultPort}) async {
    if (_isRunning) {
      throw StateError('mDNS broadcaster is already running');
    }

    try {
      // Get local IP address
      _localIp = await _getLocalIpAddress();
      _isRunning = true;

      // Note: Full mDNS implementation requires platform-specific code
      // For now, we just store the network info for display
      // The teacher app can use the local IP for manual connection
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }

  /// Stop broadcasting
  Future<void> stop() async {
    _isRunning = false;
    _localIp = null;
  }

  /// Restart broadcaster
  Future<void> restart({int port = SyncServer.defaultPort}) async {
    await stop();
    await start(port: port);
  }

  // ============================================
  // NETWORK UTILITIES
  // ============================================

  /// Get local IP address
  Future<String?> _getLocalIpAddress() async {
    try {
      final networkInfo = NetworkInfo();
      String? ip = await networkInfo.getWifiIP();

      // Fallback: Try to get any local IP
      if (ip == null || ip.isEmpty || ip.startsWith('127.')) {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );

        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              return addr.address;
            }
          }
        }
      }

      return ip;
    } catch (e) {
      return null;
    }
  }

  /// Get network information for display
  Future<Map<String, dynamic>> getNetworkInfo() async {
    final info = <String, dynamic>{
      'isRunning': isRunning,
      'localIp': _localIp,
      'hostname': Platform.localHostname,
    };

    try {
      final networkInfo = NetworkInfo();
      info['wifiName'] = await networkInfo.getWifiName();
      info['wifiIP'] = await networkInfo.getWifiIP();
      info['wifiBSSID'] = await networkInfo.getWifiBSSID();
    } catch (e) {
      // Ignore errors
    }

    return info;
  }
}

/// Combined server manager that handles both HTTP server and mDNS
class SyncServerManager {
  static final SyncServerManager _instance = SyncServerManager._internal();
  factory SyncServerManager() => _instance;
  SyncServerManager._internal();

  final SyncServer _server = SyncServer.instance();
  final MdnsBroadcaster _mdns = MdnsBroadcaster();

  bool get isServerRunning => _server.isRunning;
  bool get isMdnsRunning => _mdns.isRunning;
  int get port => _server.port;
  String? get localIp => _mdns.localIp;
  Stream<SyncResponse> get onSyncEvent => _server.onSyncEvent;

  /// Start both server and mDNS broadcaster
  Future<void> start({int port = SyncServer.defaultPort}) async {
    // Start HTTP server first
    if (!_server.isRunning) {
      await _server.start(port: port);
    }

    // Then start mDNS broadcaster
    if (!_mdns.isRunning) {
      await _mdns.start(port: _server.port);
    }
  }

  /// Stop both server and mDNS broadcaster
  Future<void> stop() async {
    await _mdns.stop();
    await _server.stop();
  }

  /// Restart both services
  Future<void> restart({int port = SyncServer.defaultPort}) async {
    await stop();
    await start(port: port);
  }

  /// Get server status
  Map<String, dynamic> getStatus() {
    return {
      'serverRunning': _server.isRunning,
      'mdnsRunning': _mdns.isRunning,
      'port': _server.port,
      'localIp': _mdns.localIp,
    };
  }
}
