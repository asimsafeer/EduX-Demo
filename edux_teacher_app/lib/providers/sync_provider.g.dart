// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$discoveryServiceHash() => r'cc7a0330a7ed7ae698a3c87dc3f691903d2a1a52';

/// Discovery service provider
///
/// Copied from [discoveryService].
@ProviderFor(discoveryService)
final discoveryServiceProvider = Provider<DiscoveryService>.internal(
  discoveryService,
  name: r'discoveryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$discoveryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiscoveryServiceRef = ProviderRef<DiscoveryService>;
String _$isOnlineHash() => r'6f3c4100412b65878348125e80f6b25fc84694e6';

/// Is online provider (network connectivity)
///
/// Copied from [isOnline].
@ProviderFor(isOnline)
final isOnlineProvider = AutoDisposeFutureProvider<bool>.internal(
  isOnline,
  name: r'isOnlineProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isOnlineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnlineRef = AutoDisposeFutureProviderRef<bool>;
String _$canSyncHash() => r'432ce579c9352f936d12386ca90755efd036bb5d';

/// Can sync provider (checks all conditions)
///
/// Copied from [canSync].
@ProviderFor(canSync)
final canSyncProvider = AutoDisposeFutureProvider<bool>.internal(
  canSync,
  name: r'canSyncProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$canSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanSyncRef = AutoDisposeFutureProviderRef<bool>;
String _$syncHash() => r'00ce5b08b96774863c354369e960fd7c75e5de83';

/// Sync provider
///
/// Copied from [Sync].
@ProviderFor(Sync)
final syncProvider = NotifierProvider<Sync, SyncState>.internal(
  Sync.new,
  name: r'syncProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Sync = Notifier<SyncState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
