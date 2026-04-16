/// EduX Teacher App - Discovery Service (mDNS)
library;

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../core/constants/app_constants.dart';
import '../models/sync_models.dart';

/// Service for discovering EduX servers on the local network
class DiscoveryService {
  static const String _serviceName = AppConstants.mdnsServiceName;
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();

  /// Check if connected to WiFi
  Future<bool> isOnWifi() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.wifi;
  }

  /// Get current WiFi IP address
  Future<String?> getWifiIP() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      return null;
    }
  }

  /// Discover EduX servers on the network via mDNS
  Future<List<DiscoveredServer>> discoverServers({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final servers = <DiscoveredServer>[];
    final MDnsClient client = MDnsClient();

    try {
      await client.start();

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceName),
      ).timeout(timeout, onTimeout: (sink) => sink.close())) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final IPAddressResourceRecord ip
              in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            // Try to get additional info from TXT records
            String? version;
            String? schoolName;

            try {
              await for (final TxtResourceRecord txt in client.lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(ptr.domainName),
              ).timeout(const Duration(milliseconds: 500))) {
                final text = String.fromCharCodes(txt.text is Iterable<int> ? txt.text as Iterable<int> : [txt.text as int]);
                if (text.startsWith('version=')) {
                  version = text.substring(8);
                } else if (text.startsWith('school=')) {
                  schoolName = text.substring(7);
                }
              }
            } catch (_) {
              // Ignore TXT lookup errors
            }

            servers.add(DiscoveredServer(
              name: ptr.domainName.split('.').first,
              ipAddress: ip.address.address,
              port: srv.port,
              version: version,
              schoolName: schoolName,
            ));
          }
        }
      }
    } catch (e) {
      // mDNS discovery failed
    } finally {
      client.stop();
    }

    // Remove duplicates based on IP
    final seen = <String>{};
    return servers.where((s) => seen.add(s.ipAddress)).toList();
  }

  /// Test connection to a server
  Future<ServerStatus?> testConnection(String ip, int port) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://$ip:$port',
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));

      final response = await dio.get('/health');

      if (response.statusCode == 200) {
        return ServerStatus.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      // Connection failed
    }
    return null;
  }

  /// Check if server is reachable
  Future<bool> isServerReachable(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Scan local network for servers (fallback when mDNS fails)
  Future<List<DiscoveredServer>> scanNetwork({
    String? subnet,
    int port = AppConstants.syncServerPort,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    final servers = <DiscoveredServer>[];

    // Get current IP to determine subnet
    final ip = await getWifiIP();
    if (ip == null) return servers;

    // Extract subnet (e.g., 192.168.1)
    final parts = ip.split('.');
    if (parts.length != 4) return servers;

    final baseSubnet = '${parts[0]}.${parts[1]}.${parts[2]}';
    final currentHost = int.tryParse(parts[3]) ?? 1;

    // Scan common IP ranges
    final futures = <Future<void>>[];

    // Scan 1-254, but prioritize nearby IPs first
    final scanOrder = _generateScanOrder(currentHost);

    for (final host in scanOrder.take(50)) {
      // Limit to 50 hosts for performance
      futures.add(_checkHost(baseSubnet, host, port, timeout, servers));
    }

    await Future.wait(futures);

    return servers;
  }

  List<int> _generateScanOrder(int currentHost) {
    final order = <int>[];

    // Add nearby hosts first
    for (int offset = 1; offset <= 10; offset++) {
      if (currentHost + offset <= 254) order.add(currentHost + offset);
      if (currentHost - offset >= 1) order.add(currentHost - offset);
    }

    // Add gateway
    if (!order.contains(1)) order.add(1);

    // Add common server IPs
    for (final host in [100, 50, 200, 2, 10, 150]) {
      if (!order.contains(host) && host != currentHost) {
        order.add(host);
      }
    }

    // Add remaining hosts
    for (int host = 1; host <= 254; host++) {
      if (!order.contains(host) && host != currentHost) {
        order.add(host);
      }
    }

    return order;
  }

  Future<void> _checkHost(
    String subnet,
    int host,
    int port,
    Duration timeout,
    List<DiscoveredServer> servers,
  ) async {
    final ip = '$subnet.$host';
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      await socket.close();

      // Verify it's an EduX server
      final status = await testConnection(ip, port);
      if (status != null) {
        servers.add(DiscoveredServer(
          name: status.serverName ?? 'EduX Server',
          ipAddress: ip,
          port: port,
          version: status.version,
        ));
      }
    } catch (_) {
      // Host not reachable or not an EduX server
    }
  }
}
