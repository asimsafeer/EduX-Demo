// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classesHash() => r'3ff739139b0d777d4b502a21056cbc736186b411';

/// Classes provider
///
/// Copied from [Classes].
@ProviderFor(Classes)
final classesProvider = NotifierProvider<Classes, ClassesState>.internal(
  Classes.new,
  name: r'classesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$classesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Classes = Notifier<ClassesState>;
String _$selectedClassHash() => r'fcf4dc743b8c1ab72fa58ff09f82ddc8193f28a7';

/// Selected class provider (for navigation)
///
/// Copied from [SelectedClass].
@ProviderFor(SelectedClass)
final selectedClassProvider =
    NotifierProvider<SelectedClass, ClassSection?>.internal(
  SelectedClass.new,
  name: r'selectedClassProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedClassHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedClass = Notifier<ClassSection?>;
String _$selectedDateHash() => r'9506f773b8dd78e827795c9880cff42a7efa8537';

/// Selected date provider (for attendance)
///
/// Copied from [SelectedDate].
@ProviderFor(SelectedDate)
final selectedDateProvider = NotifierProvider<SelectedDate, DateTime>.internal(
  SelectedDate.new,
  name: r'selectedDateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDate = Notifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
