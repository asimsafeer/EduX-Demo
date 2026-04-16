// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Student _$StudentFromJson(Map<String, dynamic> json) {
  return _Student.fromJson(json);
}

/// @nodoc
mixin _$Student {
  int get studentId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get rollNumber => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  int get classId => throw _privateConstructorUsedError;
  int get sectionId => throw _privateConstructorUsedError;

  /// Serializes this Student to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Student
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudentCopyWith<Student> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentCopyWith<$Res> {
  factory $StudentCopyWith(Student value, $Res Function(Student) then) =
      _$StudentCopyWithImpl<$Res, Student>;
  @useResult
  $Res call(
      {int studentId,
      String name,
      String? rollNumber,
      String? gender,
      String? photoUrl,
      int classId,
      int sectionId});
}

/// @nodoc
class _$StudentCopyWithImpl<$Res, $Val extends Student>
    implements $StudentCopyWith<$Res> {
  _$StudentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Student
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? name = null,
    Object? rollNumber = freezed,
    Object? gender = freezed,
    Object? photoUrl = freezed,
    Object? classId = null,
    Object? sectionId = null,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rollNumber: freezed == rollNumber
          ? _value.rollNumber
          : rollNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentImplCopyWith<$Res> implements $StudentCopyWith<$Res> {
  factory _$$StudentImplCopyWith(
          _$StudentImpl value, $Res Function(_$StudentImpl) then) =
      __$$StudentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int studentId,
      String name,
      String? rollNumber,
      String? gender,
      String? photoUrl,
      int classId,
      int sectionId});
}

/// @nodoc
class __$$StudentImplCopyWithImpl<$Res>
    extends _$StudentCopyWithImpl<$Res, _$StudentImpl>
    implements _$$StudentImplCopyWith<$Res> {
  __$$StudentImplCopyWithImpl(
      _$StudentImpl _value, $Res Function(_$StudentImpl) _then)
      : super(_value, _then);

  /// Create a copy of Student
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? name = null,
    Object? rollNumber = freezed,
    Object? gender = freezed,
    Object? photoUrl = freezed,
    Object? classId = null,
    Object? sectionId = null,
  }) {
    return _then(_$StudentImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rollNumber: freezed == rollNumber
          ? _value.rollNumber
          : rollNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentImpl extends _Student {
  const _$StudentImpl(
      {required this.studentId,
      required this.name,
      this.rollNumber,
      this.gender,
      this.photoUrl,
      required this.classId,
      required this.sectionId})
      : super._();

  factory _$StudentImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentImplFromJson(json);

  @override
  final int studentId;
  @override
  final String name;
  @override
  final String? rollNumber;
  @override
  final String? gender;
  @override
  final String? photoUrl;
  @override
  final int classId;
  @override
  final int sectionId;

  @override
  String toString() {
    return 'Student(studentId: $studentId, name: $name, rollNumber: $rollNumber, gender: $gender, photoUrl: $photoUrl, classId: $classId, sectionId: $sectionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rollNumber, rollNumber) ||
                other.rollNumber == rollNumber) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, studentId, name, rollNumber,
      gender, photoUrl, classId, sectionId);

  /// Create a copy of Student
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentImplCopyWith<_$StudentImpl> get copyWith =>
      __$$StudentImplCopyWithImpl<_$StudentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentImplToJson(
      this,
    );
  }
}

abstract class _Student extends Student {
  const factory _Student(
      {required final int studentId,
      required final String name,
      final String? rollNumber,
      final String? gender,
      final String? photoUrl,
      required final int classId,
      required final int sectionId}) = _$StudentImpl;
  const _Student._() : super._();

  factory _Student.fromJson(Map<String, dynamic> json) = _$StudentImpl.fromJson;

  @override
  int get studentId;
  @override
  String get name;
  @override
  String? get rollNumber;
  @override
  String? get gender;
  @override
  String? get photoUrl;
  @override
  int get classId;
  @override
  int get sectionId;

  /// Create a copy of Student
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudentImplCopyWith<_$StudentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StudentAttendance _$StudentAttendanceFromJson(Map<String, dynamic> json) {
  return _StudentAttendance.fromJson(json);
}

/// @nodoc
mixin _$StudentAttendance {
  Student get student => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  DateTime? get markedAt => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;

  /// Serializes this StudentAttendance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudentAttendance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudentAttendanceCopyWith<StudentAttendance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentAttendanceCopyWith<$Res> {
  factory $StudentAttendanceCopyWith(
          StudentAttendance value, $Res Function(StudentAttendance) then) =
      _$StudentAttendanceCopyWithImpl<$Res, StudentAttendance>;
  @useResult
  $Res call(
      {Student student,
      String? status,
      String? remarks,
      DateTime? markedAt,
      bool isSynced});

  $StudentCopyWith<$Res> get student;
}

/// @nodoc
class _$StudentAttendanceCopyWithImpl<$Res, $Val extends StudentAttendance>
    implements $StudentAttendanceCopyWith<$Res> {
  _$StudentAttendanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudentAttendance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? student = null,
    Object? status = freezed,
    Object? remarks = freezed,
    Object? markedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_value.copyWith(
      student: null == student
          ? _value.student
          : student // ignore: cast_nullable_to_non_nullable
              as Student,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      markedAt: freezed == markedAt
          ? _value.markedAt
          : markedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of StudentAttendance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StudentCopyWith<$Res> get student {
    return $StudentCopyWith<$Res>(_value.student, (value) {
      return _then(_value.copyWith(student: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StudentAttendanceImplCopyWith<$Res>
    implements $StudentAttendanceCopyWith<$Res> {
  factory _$$StudentAttendanceImplCopyWith(_$StudentAttendanceImpl value,
          $Res Function(_$StudentAttendanceImpl) then) =
      __$$StudentAttendanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Student student,
      String? status,
      String? remarks,
      DateTime? markedAt,
      bool isSynced});

  @override
  $StudentCopyWith<$Res> get student;
}

/// @nodoc
class __$$StudentAttendanceImplCopyWithImpl<$Res>
    extends _$StudentAttendanceCopyWithImpl<$Res, _$StudentAttendanceImpl>
    implements _$$StudentAttendanceImplCopyWith<$Res> {
  __$$StudentAttendanceImplCopyWithImpl(_$StudentAttendanceImpl _value,
      $Res Function(_$StudentAttendanceImpl) _then)
      : super(_value, _then);

  /// Create a copy of StudentAttendance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? student = null,
    Object? status = freezed,
    Object? remarks = freezed,
    Object? markedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_$StudentAttendanceImpl(
      student: null == student
          ? _value.student
          : student // ignore: cast_nullable_to_non_nullable
              as Student,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      markedAt: freezed == markedAt
          ? _value.markedAt
          : markedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentAttendanceImpl implements _StudentAttendance {
  const _$StudentAttendanceImpl(
      {required this.student,
      this.status,
      this.remarks,
      this.markedAt,
      this.isSynced = false});

  factory _$StudentAttendanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentAttendanceImplFromJson(json);

  @override
  final Student student;
  @override
  final String? status;
  @override
  final String? remarks;
  @override
  final DateTime? markedAt;
  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'StudentAttendance(student: $student, status: $status, remarks: $remarks, markedAt: $markedAt, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentAttendanceImpl &&
            (identical(other.student, student) || other.student == student) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.markedAt, markedAt) ||
                other.markedAt == markedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, student, status, remarks, markedAt, isSynced);

  /// Create a copy of StudentAttendance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentAttendanceImplCopyWith<_$StudentAttendanceImpl> get copyWith =>
      __$$StudentAttendanceImplCopyWithImpl<_$StudentAttendanceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentAttendanceImplToJson(
      this,
    );
  }
}

abstract class _StudentAttendance implements StudentAttendance {
  const factory _StudentAttendance(
      {required final Student student,
      final String? status,
      final String? remarks,
      final DateTime? markedAt,
      final bool isSynced}) = _$StudentAttendanceImpl;

  factory _StudentAttendance.fromJson(Map<String, dynamic> json) =
      _$StudentAttendanceImpl.fromJson;

  @override
  Student get student;
  @override
  String? get status;
  @override
  String? get remarks;
  @override
  DateTime? get markedAt;
  @override
  bool get isSynced;

  /// Create a copy of StudentAttendance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudentAttendanceImplCopyWith<_$StudentAttendanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
