// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ClassSection _$ClassSectionFromJson(Map<String, dynamic> json) {
  return _ClassSection.fromJson(json);
}

/// @nodoc
mixin _$ClassSection {
  int get classId => throw _privateConstructorUsedError;
  int get sectionId => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String? get subjectName => throw _privateConstructorUsedError;
  int get totalStudents => throw _privateConstructorUsedError;
  bool get isClassTeacher => throw _privateConstructorUsedError;

  /// Serializes this ClassSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClassSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassSectionCopyWith<ClassSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassSectionCopyWith<$Res> {
  factory $ClassSectionCopyWith(
          ClassSection value, $Res Function(ClassSection) then) =
      _$ClassSectionCopyWithImpl<$Res, ClassSection>;
  @useResult
  $Res call(
      {int classId,
      int sectionId,
      String className,
      String sectionName,
      String? subjectName,
      int totalStudents,
      bool isClassTeacher});
}

/// @nodoc
class _$ClassSectionCopyWithImpl<$Res, $Val extends ClassSection>
    implements $ClassSectionCopyWith<$Res> {
  _$ClassSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classId = null,
    Object? sectionId = null,
    Object? className = null,
    Object? sectionName = null,
    Object? subjectName = freezed,
    Object? totalStudents = null,
    Object? isClassTeacher = null,
  }) {
    return _then(_value.copyWith(
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      isClassTeacher: null == isClassTeacher
          ? _value.isClassTeacher
          : isClassTeacher // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClassSectionImplCopyWith<$Res>
    implements $ClassSectionCopyWith<$Res> {
  factory _$$ClassSectionImplCopyWith(
          _$ClassSectionImpl value, $Res Function(_$ClassSectionImpl) then) =
      __$$ClassSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int classId,
      int sectionId,
      String className,
      String sectionName,
      String? subjectName,
      int totalStudents,
      bool isClassTeacher});
}

/// @nodoc
class __$$ClassSectionImplCopyWithImpl<$Res>
    extends _$ClassSectionCopyWithImpl<$Res, _$ClassSectionImpl>
    implements _$$ClassSectionImplCopyWith<$Res> {
  __$$ClassSectionImplCopyWithImpl(
      _$ClassSectionImpl _value, $Res Function(_$ClassSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClassSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classId = null,
    Object? sectionId = null,
    Object? className = null,
    Object? sectionName = null,
    Object? subjectName = freezed,
    Object? totalStudents = null,
    Object? isClassTeacher = null,
  }) {
    return _then(_$ClassSectionImpl(
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      isClassTeacher: null == isClassTeacher
          ? _value.isClassTeacher
          : isClassTeacher // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClassSectionImpl extends _ClassSection {
  const _$ClassSectionImpl(
      {required this.classId,
      required this.sectionId,
      required this.className,
      required this.sectionName,
      this.subjectName,
      this.totalStudents = 0,
      this.isClassTeacher = false})
      : super._();

  factory _$ClassSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClassSectionImplFromJson(json);

  @override
  final int classId;
  @override
  final int sectionId;
  @override
  final String className;
  @override
  final String sectionName;
  @override
  final String? subjectName;
  @override
  @JsonKey()
  final int totalStudents;
  @override
  @JsonKey()
  final bool isClassTeacher;

  @override
  String toString() {
    return 'ClassSection(classId: $classId, sectionId: $sectionId, className: $className, sectionName: $sectionName, subjectName: $subjectName, totalStudents: $totalStudents, isClassTeacher: $isClassTeacher)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassSectionImpl &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.isClassTeacher, isClassTeacher) ||
                other.isClassTeacher == isClassTeacher));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, classId, sectionId, className,
      sectionName, subjectName, totalStudents, isClassTeacher);

  /// Create a copy of ClassSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassSectionImplCopyWith<_$ClassSectionImpl> get copyWith =>
      __$$ClassSectionImplCopyWithImpl<_$ClassSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClassSectionImplToJson(
      this,
    );
  }
}

abstract class _ClassSection extends ClassSection {
  const factory _ClassSection(
      {required final int classId,
      required final int sectionId,
      required final String className,
      required final String sectionName,
      final String? subjectName,
      final int totalStudents,
      final bool isClassTeacher}) = _$ClassSectionImpl;
  const _ClassSection._() : super._();

  factory _ClassSection.fromJson(Map<String, dynamic> json) =
      _$ClassSectionImpl.fromJson;

  @override
  int get classId;
  @override
  int get sectionId;
  @override
  String get className;
  @override
  String get sectionName;
  @override
  String? get subjectName;
  @override
  int get totalStudents;
  @override
  bool get isClassTeacher;

  /// Create a copy of ClassSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassSectionImplCopyWith<_$ClassSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClassSummary _$ClassSummaryFromJson(Map<String, dynamic> json) {
  return _ClassSummary.fromJson(json);
}

/// @nodoc
mixin _$ClassSummary {
  int get classId => throw _privateConstructorUsedError;
  int get sectionId => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  int get totalStudents => throw _privateConstructorUsedError;
  int get markedCount => throw _privateConstructorUsedError;
  DateTime? get lastMarkedAt => throw _privateConstructorUsedError;

  /// Serializes this ClassSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClassSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassSummaryCopyWith<ClassSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassSummaryCopyWith<$Res> {
  factory $ClassSummaryCopyWith(
          ClassSummary value, $Res Function(ClassSummary) then) =
      _$ClassSummaryCopyWithImpl<$Res, ClassSummary>;
  @useResult
  $Res call(
      {int classId,
      int sectionId,
      String className,
      String sectionName,
      int totalStudents,
      int markedCount,
      DateTime? lastMarkedAt});
}

/// @nodoc
class _$ClassSummaryCopyWithImpl<$Res, $Val extends ClassSummary>
    implements $ClassSummaryCopyWith<$Res> {
  _$ClassSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classId = null,
    Object? sectionId = null,
    Object? className = null,
    Object? sectionName = null,
    Object? totalStudents = null,
    Object? markedCount = null,
    Object? lastMarkedAt = freezed,
  }) {
    return _then(_value.copyWith(
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      markedCount: null == markedCount
          ? _value.markedCount
          : markedCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastMarkedAt: freezed == lastMarkedAt
          ? _value.lastMarkedAt
          : lastMarkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClassSummaryImplCopyWith<$Res>
    implements $ClassSummaryCopyWith<$Res> {
  factory _$$ClassSummaryImplCopyWith(
          _$ClassSummaryImpl value, $Res Function(_$ClassSummaryImpl) then) =
      __$$ClassSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int classId,
      int sectionId,
      String className,
      String sectionName,
      int totalStudents,
      int markedCount,
      DateTime? lastMarkedAt});
}

/// @nodoc
class __$$ClassSummaryImplCopyWithImpl<$Res>
    extends _$ClassSummaryCopyWithImpl<$Res, _$ClassSummaryImpl>
    implements _$$ClassSummaryImplCopyWith<$Res> {
  __$$ClassSummaryImplCopyWithImpl(
      _$ClassSummaryImpl _value, $Res Function(_$ClassSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClassSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classId = null,
    Object? sectionId = null,
    Object? className = null,
    Object? sectionName = null,
    Object? totalStudents = null,
    Object? markedCount = null,
    Object? lastMarkedAt = freezed,
  }) {
    return _then(_$ClassSummaryImpl(
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as int,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as int,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      markedCount: null == markedCount
          ? _value.markedCount
          : markedCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastMarkedAt: freezed == lastMarkedAt
          ? _value.lastMarkedAt
          : lastMarkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClassSummaryImpl extends _ClassSummary {
  const _$ClassSummaryImpl(
      {required this.classId,
      required this.sectionId,
      required this.className,
      required this.sectionName,
      required this.totalStudents,
      required this.markedCount,
      this.lastMarkedAt})
      : super._();

  factory _$ClassSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClassSummaryImplFromJson(json);

  @override
  final int classId;
  @override
  final int sectionId;
  @override
  final String className;
  @override
  final String sectionName;
  @override
  final int totalStudents;
  @override
  final int markedCount;
  @override
  final DateTime? lastMarkedAt;

  @override
  String toString() {
    return 'ClassSummary(classId: $classId, sectionId: $sectionId, className: $className, sectionName: $sectionName, totalStudents: $totalStudents, markedCount: $markedCount, lastMarkedAt: $lastMarkedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassSummaryImpl &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.markedCount, markedCount) ||
                other.markedCount == markedCount) &&
            (identical(other.lastMarkedAt, lastMarkedAt) ||
                other.lastMarkedAt == lastMarkedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, classId, sectionId, className,
      sectionName, totalStudents, markedCount, lastMarkedAt);

  /// Create a copy of ClassSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassSummaryImplCopyWith<_$ClassSummaryImpl> get copyWith =>
      __$$ClassSummaryImplCopyWithImpl<_$ClassSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClassSummaryImplToJson(
      this,
    );
  }
}

abstract class _ClassSummary extends ClassSummary {
  const factory _ClassSummary(
      {required final int classId,
      required final int sectionId,
      required final String className,
      required final String sectionName,
      required final int totalStudents,
      required final int markedCount,
      final DateTime? lastMarkedAt}) = _$ClassSummaryImpl;
  const _ClassSummary._() : super._();

  factory _ClassSummary.fromJson(Map<String, dynamic> json) =
      _$ClassSummaryImpl.fromJson;

  @override
  int get classId;
  @override
  int get sectionId;
  @override
  String get className;
  @override
  String get sectionName;
  @override
  int get totalStudents;
  @override
  int get markedCount;
  @override
  DateTime? get lastMarkedAt;

  /// Create a copy of ClassSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassSummaryImplCopyWith<_$ClassSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
