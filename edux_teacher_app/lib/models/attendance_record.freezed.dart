// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AttendanceRecord _$AttendanceRecordFromJson(Map<String, dynamic> json) {
  return _AttendanceRecord.fromJson(json);
}

/// @nodoc
mixin _$AttendanceRecord {
  int get studentId => throw _privateConstructorUsedError;
  int get classId => throw _privateConstructorUsedError;
  int get sectionId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  DateTime? get markedAt => throw _privateConstructorUsedError;
  String? get academicYear => throw _privateConstructorUsedError;

  /// Serializes this AttendanceRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttendanceRecordCopyWith<AttendanceRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceRecordCopyWith<$Res> {
  factory $AttendanceRecordCopyWith(
          AttendanceRecord value, $Res Function(AttendanceRecord) then) =
      _$AttendanceRecordCopyWithImpl<$Res, AttendanceRecord>;
  @useResult
  $Res call(
      {int studentId,
      int classId,
      int sectionId,
      DateTime date,
      String status,
      String? remarks,
      DateTime? markedAt,
      String? academicYear});
}

/// @nodoc
class _$AttendanceRecordCopyWithImpl<$Res, $Val extends AttendanceRecord>
    implements $AttendanceRecordCopyWith<$Res> {
  _$AttendanceRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? classId = null,
    Object? sectionId = null,
    Object? date = null,
    Object? status = null,
    Object? remarks = freezed,
    Object? markedAt = freezed,
    Object? academicYear = freezed,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      markedAt: freezed == markedAt
          ? _value.markedAt
          : markedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      academicYear: freezed == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceRecordImplCopyWith<$Res>
    implements $AttendanceRecordCopyWith<$Res> {
  factory _$$AttendanceRecordImplCopyWith(_$AttendanceRecordImpl value,
          $Res Function(_$AttendanceRecordImpl) then) =
      __$$AttendanceRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int studentId,
      int classId,
      int sectionId,
      DateTime date,
      String status,
      String? remarks,
      DateTime? markedAt,
      String? academicYear});
}

/// @nodoc
class __$$AttendanceRecordImplCopyWithImpl<$Res>
    extends _$AttendanceRecordCopyWithImpl<$Res, _$AttendanceRecordImpl>
    implements _$$AttendanceRecordImplCopyWith<$Res> {
  __$$AttendanceRecordImplCopyWithImpl(_$AttendanceRecordImpl _value,
      $Res Function(_$AttendanceRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? classId = null,
    Object? sectionId = null,
    Object? date = null,
    Object? status = null,
    Object? remarks = freezed,
    Object? markedAt = freezed,
    Object? academicYear = freezed,
  }) {
    return _then(_$AttendanceRecordImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      markedAt: freezed == markedAt
          ? _value.markedAt
          : markedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      academicYear: freezed == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceRecordImpl extends _AttendanceRecord {
  const _$AttendanceRecordImpl(
      {required this.studentId,
      required this.classId,
      required this.sectionId,
      required this.date,
      required this.status,
      this.remarks,
      this.markedAt,
      this.academicYear})
      : super._();

  factory _$AttendanceRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceRecordImplFromJson(json);

  @override
  final int studentId;
  @override
  final int classId;
  @override
  final int sectionId;
  @override
  final DateTime date;
  @override
  final String status;
  @override
  final String? remarks;
  @override
  final DateTime? markedAt;
  @override
  final String? academicYear;

  @override
  String toString() {
    return 'AttendanceRecord(studentId: $studentId, classId: $classId, sectionId: $sectionId, date: $date, status: $status, remarks: $remarks, markedAt: $markedAt, academicYear: $academicYear)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceRecordImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.markedAt, markedAt) ||
                other.markedAt == markedAt) &&
            (identical(other.academicYear, academicYear) ||
                other.academicYear == academicYear));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, studentId, classId, sectionId,
      date, status, remarks, markedAt, academicYear);

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceRecordImplCopyWith<_$AttendanceRecordImpl> get copyWith =>
      __$$AttendanceRecordImplCopyWithImpl<_$AttendanceRecordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceRecordImplToJson(
      this,
    );
  }
}

abstract class _AttendanceRecord extends AttendanceRecord {
  const factory _AttendanceRecord(
      {required final int studentId,
      required final int classId,
      required final int sectionId,
      required final DateTime date,
      required final String status,
      final String? remarks,
      final DateTime? markedAt,
      final String? academicYear}) = _$AttendanceRecordImpl;
  const _AttendanceRecord._() : super._();

  factory _AttendanceRecord.fromJson(Map<String, dynamic> json) =
      _$AttendanceRecordImpl.fromJson;

  @override
  int get studentId;
  @override
  int get classId;
  @override
  int get sectionId;
  @override
  DateTime get date;
  @override
  String get status;
  @override
  String? get remarks;
  @override
  DateTime? get markedAt;
  @override
  String? get academicYear;

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttendanceRecordImplCopyWith<_$AttendanceRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AttendanceStats _$AttendanceStatsFromJson(Map<String, dynamic> json) {
  return _AttendanceStats.fromJson(json);
}

/// @nodoc
mixin _$AttendanceStats {
  int get present => throw _privateConstructorUsedError;
  int get absent => throw _privateConstructorUsedError;
  int get late => throw _privateConstructorUsedError;
  int get leave => throw _privateConstructorUsedError;
  int get halfDay => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;

  /// Serializes this AttendanceStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AttendanceStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttendanceStatsCopyWith<AttendanceStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceStatsCopyWith<$Res> {
  factory $AttendanceStatsCopyWith(
          AttendanceStats value, $Res Function(AttendanceStats) then) =
      _$AttendanceStatsCopyWithImpl<$Res, AttendanceStats>;
  @useResult
  $Res call(
      {int present, int absent, int late, int leave, int halfDay, int total});
}

/// @nodoc
class _$AttendanceStatsCopyWithImpl<$Res, $Val extends AttendanceStats>
    implements $AttendanceStatsCopyWith<$Res> {
  _$AttendanceStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttendanceStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? present = null,
    Object? absent = null,
    Object? late = null,
    Object? leave = null,
    Object? halfDay = null,
    Object? total = null,
  }) {
    return _then(_value.copyWith(
      present: null == present
          ? _value.present
          : present // ignore: cast_nullable_to_non_nullable
              as int,
      absent: null == absent
          ? _value.absent
          : absent // ignore: cast_nullable_to_non_nullable
              as int,
      late: null == late
          ? _value.late
          : late // ignore: cast_nullable_to_non_nullable
              as int,
      leave: null == leave
          ? _value.leave
          : leave // ignore: cast_nullable_to_non_nullable
              as int,
      halfDay: null == halfDay
          ? _value.halfDay
          : halfDay // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceStatsImplCopyWith<$Res>
    implements $AttendanceStatsCopyWith<$Res> {
  factory _$$AttendanceStatsImplCopyWith(_$AttendanceStatsImpl value,
          $Res Function(_$AttendanceStatsImpl) then) =
      __$$AttendanceStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int present, int absent, int late, int leave, int halfDay, int total});
}

/// @nodoc
class __$$AttendanceStatsImplCopyWithImpl<$Res>
    extends _$AttendanceStatsCopyWithImpl<$Res, _$AttendanceStatsImpl>
    implements _$$AttendanceStatsImplCopyWith<$Res> {
  __$$AttendanceStatsImplCopyWithImpl(
      _$AttendanceStatsImpl _value, $Res Function(_$AttendanceStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttendanceStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? present = null,
    Object? absent = null,
    Object? late = null,
    Object? leave = null,
    Object? halfDay = null,
    Object? total = null,
  }) {
    return _then(_$AttendanceStatsImpl(
      present: null == present
          ? _value.present
          : present // ignore: cast_nullable_to_non_nullable
              as int,
      absent: null == absent
          ? _value.absent
          : absent // ignore: cast_nullable_to_non_nullable
              as int,
      late: null == late
          ? _value.late
          : late // ignore: cast_nullable_to_non_nullable
              as int,
      leave: null == leave
          ? _value.leave
          : leave // ignore: cast_nullable_to_non_nullable
              as int,
      halfDay: null == halfDay
          ? _value.halfDay
          : halfDay // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceStatsImpl extends _AttendanceStats {
  const _$AttendanceStatsImpl(
      {this.present = 0,
      this.absent = 0,
      this.late = 0,
      this.leave = 0,
      this.halfDay = 0,
      this.total = 0})
      : super._();

  factory _$AttendanceStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceStatsImplFromJson(json);

  @override
  @JsonKey()
  final int present;
  @override
  @JsonKey()
  final int absent;
  @override
  @JsonKey()
  final int late;
  @override
  @JsonKey()
  final int leave;
  @override
  @JsonKey()
  final int halfDay;
  @override
  @JsonKey()
  final int total;

  @override
  String toString() {
    return 'AttendanceStats(present: $present, absent: $absent, late: $late, leave: $leave, halfDay: $halfDay, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceStatsImpl &&
            (identical(other.present, present) || other.present == present) &&
            (identical(other.absent, absent) || other.absent == absent) &&
            (identical(other.late, late) || other.late == late) &&
            (identical(other.leave, leave) || other.leave == leave) &&
            (identical(other.halfDay, halfDay) || other.halfDay == halfDay) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, present, absent, late, leave, halfDay, total);

  /// Create a copy of AttendanceStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceStatsImplCopyWith<_$AttendanceStatsImpl> get copyWith =>
      __$$AttendanceStatsImplCopyWithImpl<_$AttendanceStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceStatsImplToJson(
      this,
    );
  }
}

abstract class _AttendanceStats extends AttendanceStats {
  const factory _AttendanceStats(
      {final int present,
      final int absent,
      final int late,
      final int leave,
      final int halfDay,
      final int total}) = _$AttendanceStatsImpl;
  const _AttendanceStats._() : super._();

  factory _AttendanceStats.fromJson(Map<String, dynamic> json) =
      _$AttendanceStatsImpl.fromJson;

  @override
  int get present;
  @override
  int get absent;
  @override
  int get late;
  @override
  int get leave;
  @override
  int get halfDay;
  @override
  int get total;

  /// Create a copy of AttendanceStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttendanceStatsImplCopyWith<_$AttendanceStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
