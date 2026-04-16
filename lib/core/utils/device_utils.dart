import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get a unique identifier for the device
  /// On Windows, this returns the `deviceId`.
  /// On other platforms, it returns a suitable identifier.
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Or androidInfo.fingerprint
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        return macOsInfo.systemGUID ?? 'unknown_macos_device';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.machineId ?? 'unknown_linux_device';
      }
      return 'unknown_device';
    } catch (e) {
      return 'unknown_device_error';
    }
  }
}
