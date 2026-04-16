// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deviceServiceHash() => r'd46eac5edbee9f50770b99d928930917d538d3c1';

/// Device service provider
///
/// Copied from [deviceService].
@ProviderFor(deviceService)
final deviceServiceProvider = Provider<DeviceService>.internal(
  deviceService,
  name: r'deviceServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceServiceRef = ProviderRef<DeviceService>;
String _$syncServiceHash() => r'253ffc25f333b1f805f94f4dc674d7d9b23f02ac';

/// Sync service provider
///
/// Copied from [syncService].
@ProviderFor(syncService)
final syncServiceProvider = Provider<SyncService>.internal(
  syncService,
  name: r'syncServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncServiceRef = ProviderRef<SyncService>;
String _$currentTeacherHash() => r'58c661787833fb189bd6f552f43d4e0721aaef6b';

/// Current teacher provider (convenience)
///
/// Copied from [currentTeacher].
@ProviderFor(currentTeacher)
final currentTeacherProvider = Provider<Teacher?>.internal(
  currentTeacher,
  name: r'currentTeacherProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTeacherHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentTeacherRef = ProviderRef<Teacher?>;
String _$isAuthenticatedHash() => r'490c1a4a0dabf6e516a6afd065c1ddaca6dda7ee';

/// Is authenticated provider (convenience)
///
/// Copied from [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = Provider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthenticatedRef = ProviderRef<bool>;
String _$authHash() => r'6d5aa6869583b3dab1fa92c9fe9a7a199b78f372';

/// Auth provider
///
/// Copied from [Auth].
@ProviderFor(Auth)
final authProvider = NotifierProvider<Auth, AuthState>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = Notifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
