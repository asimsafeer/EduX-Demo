// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingAttendanceCountHash() =>
    r'0258666a443cb7ad0a837fbf3b4c02f4e981e91d';

/// Pending attendance count provider (for badges)
///
/// Copied from [pendingAttendanceCount].
@ProviderFor(pendingAttendanceCount)
final pendingAttendanceCountProvider = AutoDisposeFutureProvider<int>.internal(
  pendingAttendanceCount,
  name: r'pendingAttendanceCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingAttendanceCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingAttendanceCountRef = AutoDisposeFutureProviderRef<int>;
String _$classAttendanceSummaryHash() =>
    r'2569e12eb042077b602e618988a107708b0b3701';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Class attendance summary provider
///
/// Copied from [classAttendanceSummary].
@ProviderFor(classAttendanceSummary)
const classAttendanceSummaryProvider = ClassAttendanceSummaryFamily();

/// Class attendance summary provider
///
/// Copied from [classAttendanceSummary].
class ClassAttendanceSummaryFamily
    extends Family<AsyncValue<Map<String, dynamic>>> {
  /// Class attendance summary provider
  ///
  /// Copied from [classAttendanceSummary].
  const ClassAttendanceSummaryFamily();

  /// Class attendance summary provider
  ///
  /// Copied from [classAttendanceSummary].
  ClassAttendanceSummaryProvider call(
    int classId,
    int sectionId,
    DateTime date,
  ) {
    return ClassAttendanceSummaryProvider(
      classId,
      sectionId,
      date,
    );
  }

  @override
  ClassAttendanceSummaryProvider getProviderOverride(
    covariant ClassAttendanceSummaryProvider provider,
  ) {
    return call(
      provider.classId,
      provider.sectionId,
      provider.date,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'classAttendanceSummaryProvider';
}

/// Class attendance summary provider
///
/// Copied from [classAttendanceSummary].
class ClassAttendanceSummaryProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// Class attendance summary provider
  ///
  /// Copied from [classAttendanceSummary].
  ClassAttendanceSummaryProvider(
    int classId,
    int sectionId,
    DateTime date,
  ) : this._internal(
          (ref) => classAttendanceSummary(
            ref as ClassAttendanceSummaryRef,
            classId,
            sectionId,
            date,
          ),
          from: classAttendanceSummaryProvider,
          name: r'classAttendanceSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$classAttendanceSummaryHash,
          dependencies: ClassAttendanceSummaryFamily._dependencies,
          allTransitiveDependencies:
              ClassAttendanceSummaryFamily._allTransitiveDependencies,
          classId: classId,
          sectionId: sectionId,
          date: date,
        );

  ClassAttendanceSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
    required this.sectionId,
    required this.date,
  }) : super.internal();

  final int classId;
  final int sectionId;
  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(ClassAttendanceSummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassAttendanceSummaryProvider._internal(
        (ref) => create(ref as ClassAttendanceSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
        sectionId: sectionId,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _ClassAttendanceSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassAttendanceSummaryProvider &&
        other.classId == classId &&
        other.sectionId == sectionId &&
        other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);
    hash = _SystemHash.combine(hash, sectionId.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ClassAttendanceSummaryRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `classId` of this provider.
  int get classId;

  /// The parameter `sectionId` of this provider.
  int get sectionId;

  /// The parameter `date` of this provider.
  DateTime get date;
}

class _ClassAttendanceSummaryProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with ClassAttendanceSummaryRef {
  _ClassAttendanceSummaryProviderElement(super.provider);

  @override
  int get classId => (origin as ClassAttendanceSummaryProvider).classId;
  @override
  int get sectionId => (origin as ClassAttendanceSummaryProvider).sectionId;
  @override
  DateTime get date => (origin as ClassAttendanceSummaryProvider).date;
}

String _$attendanceHash() => r'e9fdb86e6cd4ca3d5d805c34dc58ba03e6818a70';

/// Attendance provider
///
/// Copied from [Attendance].
@ProviderFor(Attendance)
final attendanceProvider =
    NotifierProvider<Attendance, AttendanceState>.internal(
  Attendance.new,
  name: r'attendanceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$attendanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Attendance = Notifier<AttendanceState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
