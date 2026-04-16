// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SyncRequest _$SyncRequestFromJson(Map<String, dynamic> json) {
  return _SyncRequest.fromJson(json);
}

/// @nodoc
mixin _$SyncRequest {
  String get deviceId => throw _privateConstructorUsedError;
  int get teacherId => throw _privateConstructorUsedError;
  DateTime get syncTimestamp => throw _privateConstructorUsedError;
  List<AttendanceRecord> get attendanceRecords =>
      throw _privateConstructorUsedError;
  String? get syncToken => throw _privateConstructorUsedError;

  /// Serializes this SyncRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncRequestCopyWith<SyncRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncRequestCopyWith<$Res> {
  factory $SyncRequestCopyWith(
          SyncRequest value, $Res Function(SyncRequest) then) =
      _$SyncRequestCopyWithImpl<$Res, SyncRequest>;
  @useResult
  $Res call(
      {String deviceId,
      int teacherId,
      DateTime syncTimestamp,
      List<AttendanceRecord> attendanceRecords,
      String? syncToken});
}

/// @nodoc
class _$SyncRequestCopyWithImpl<$Res, $Val extends SyncRequest>
    implements $SyncRequestCopyWith<$Res> {
  _$SyncRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? teacherId = null,
    Object? syncTimestamp = null,
    Object? attendanceRecords = null,
    Object? syncToken = freezed,
  }) {
    return _then(_value.copyWith(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherId: null == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as int,
      syncTimestamp: null == syncTimestamp
          ? _value.syncTimestamp
          : syncTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      attendanceRecords: null == attendanceRecords
          ? _value.attendanceRecords
          : attendanceRecords // ignore: cast_nullable_to_non_nullable
              as List<AttendanceRecord>,
      syncToken: freezed == syncToken
          ? _value.syncToken
          : syncToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncRequestImplCopyWith<$Res>
    implements $SyncRequestCopyWith<$Res> {
  factory _$$SyncRequestImplCopyWith(
          _$SyncRequestImpl value, $Res Function(_$SyncRequestImpl) then) =
      __$$SyncRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String deviceId,
      int teacherId,
      DateTime syncTimestamp,
      List<AttendanceRecord> attendanceRecords,
      String? syncToken});
}

/// @nodoc
class __$$SyncRequestImplCopyWithImpl<$Res>
    extends _$SyncRequestCopyWithImpl<$Res, _$SyncRequestImpl>
    implements _$$SyncRequestImplCopyWith<$Res> {
  __$$SyncRequestImplCopyWithImpl(
      _$SyncRequestImpl _value, $Res Function(_$SyncRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? teacherId = null,
    Object? syncTimestamp = null,
    Object? attendanceRecords = null,
    Object? syncToken = freezed,
  }) {
    return _then(_$SyncRequestImpl(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherId: null == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as int,
      syncTimestamp: null == syncTimestamp
          ? _value.syncTimestamp
          : syncTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      attendanceRecords: null == attendanceRecords
          ? _value._attendanceRecords
          : attendanceRecords // ignore: cast_nullable_to_non_nullable
              as List<AttendanceRecord>,
      syncToken: freezed == syncToken
          ? _value.syncToken
          : syncToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncRequestImpl implements _SyncRequest {
  const _$SyncRequestImpl(
      {required this.deviceId,
      required this.teacherId,
      required this.syncTimestamp,
      required final List<AttendanceRecord> attendanceRecords,
      this.syncToken})
      : _attendanceRecords = attendanceRecords;

  factory _$SyncRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncRequestImplFromJson(json);

  @override
  final String deviceId;
  @override
  final int teacherId;
  @override
  final DateTime syncTimestamp;
  final List<AttendanceRecord> _attendanceRecords;
  @override
  List<AttendanceRecord> get attendanceRecords {
    if (_attendanceRecords is EqualUnmodifiableListView)
      return _attendanceRecords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attendanceRecords);
  }

  @override
  final String? syncToken;

  @override
  String toString() {
    return 'SyncRequest(deviceId: $deviceId, teacherId: $teacherId, syncTimestamp: $syncTimestamp, attendanceRecords: $attendanceRecords, syncToken: $syncToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncRequestImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.syncTimestamp, syncTimestamp) ||
                other.syncTimestamp == syncTimestamp) &&
            const DeepCollectionEquality()
                .equals(other._attendanceRecords, _attendanceRecords) &&
            (identical(other.syncToken, syncToken) ||
                other.syncToken == syncToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      deviceId,
      teacherId,
      syncTimestamp,
      const DeepCollectionEquality().hash(_attendanceRecords),
      syncToken);

  /// Create a copy of SyncRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncRequestImplCopyWith<_$SyncRequestImpl> get copyWith =>
      __$$SyncRequestImplCopyWithImpl<_$SyncRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncRequestImplToJson(
      this,
    );
  }
}

abstract class _SyncRequest implements SyncRequest {
  const factory _SyncRequest(
      {required final String deviceId,
      required final int teacherId,
      required final DateTime syncTimestamp,
      required final List<AttendanceRecord> attendanceRecords,
      final String? syncToken}) = _$SyncRequestImpl;

  factory _SyncRequest.fromJson(Map<String, dynamic> json) =
      _$SyncRequestImpl.fromJson;

  @override
  String get deviceId;
  @override
  int get teacherId;
  @override
  DateTime get syncTimestamp;
  @override
  List<AttendanceRecord> get attendanceRecords;
  @override
  String? get syncToken;

  /// Create a copy of SyncRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncRequestImplCopyWith<_$SyncRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) {
  return _SyncResponse.fromJson(json);
}

/// @nodoc
mixin _$SyncResponse {
  bool get success => throw _privateConstructorUsedError;
  int get processed => throw _privateConstructorUsedError;
  int get created => throw _privateConstructorUsedError;
  int get updated => throw _privateConstructorUsedError;
  int get conflicts => throw _privateConstructorUsedError;
  List<String> get errors => throw _privateConstructorUsedError;
  DateTime? get serverTimestamp => throw _privateConstructorUsedError;
  String? get syncToken => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this SyncResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncResponseCopyWith<SyncResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncResponseCopyWith<$Res> {
  factory $SyncResponseCopyWith(
          SyncResponse value, $Res Function(SyncResponse) then) =
      _$SyncResponseCopyWithImpl<$Res, SyncResponse>;
  @useResult
  $Res call(
      {bool success,
      int processed,
      int created,
      int updated,
      int conflicts,
      List<String> errors,
      DateTime? serverTimestamp,
      String? syncToken,
      String? errorMessage});
}

/// @nodoc
class _$SyncResponseCopyWithImpl<$Res, $Val extends SyncResponse>
    implements $SyncResponseCopyWith<$Res> {
  _$SyncResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? processed = null,
    Object? created = null,
    Object? updated = null,
    Object? conflicts = null,
    Object? errors = null,
    Object? serverTimestamp = freezed,
    Object? syncToken = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      processed: null == processed
          ? _value.processed
          : processed // ignore: cast_nullable_to_non_nullable
              as int,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as int,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as int,
      conflicts: null == conflicts
          ? _value.conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      serverTimestamp: freezed == serverTimestamp
          ? _value.serverTimestamp
          : serverTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncToken: freezed == syncToken
          ? _value.syncToken
          : syncToken // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncResponseImplCopyWith<$Res>
    implements $SyncResponseCopyWith<$Res> {
  factory _$$SyncResponseImplCopyWith(
          _$SyncResponseImpl value, $Res Function(_$SyncResponseImpl) then) =
      __$$SyncResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      int processed,
      int created,
      int updated,
      int conflicts,
      List<String> errors,
      DateTime? serverTimestamp,
      String? syncToken,
      String? errorMessage});
}

/// @nodoc
class __$$SyncResponseImplCopyWithImpl<$Res>
    extends _$SyncResponseCopyWithImpl<$Res, _$SyncResponseImpl>
    implements _$$SyncResponseImplCopyWith<$Res> {
  __$$SyncResponseImplCopyWithImpl(
      _$SyncResponseImpl _value, $Res Function(_$SyncResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? processed = null,
    Object? created = null,
    Object? updated = null,
    Object? conflicts = null,
    Object? errors = null,
    Object? serverTimestamp = freezed,
    Object? syncToken = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$SyncResponseImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      processed: null == processed
          ? _value.processed
          : processed // ignore: cast_nullable_to_non_nullable
              as int,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as int,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as int,
      conflicts: null == conflicts
          ? _value.conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as int,
      errors: null == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      serverTimestamp: freezed == serverTimestamp
          ? _value.serverTimestamp
          : serverTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncToken: freezed == syncToken
          ? _value.syncToken
          : syncToken // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncResponseImpl implements _SyncResponse {
  const _$SyncResponseImpl(
      {required this.success,
      required this.processed,
      required this.created,
      required this.updated,
      required this.conflicts,
      final List<String> errors = const [],
      this.serverTimestamp,
      this.syncToken,
      this.errorMessage})
      : _errors = errors;

  factory _$SyncResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final int processed;
  @override
  final int created;
  @override
  final int updated;
  @override
  final int conflicts;
  final List<String> _errors;
  @override
  @JsonKey()
  List<String> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  @override
  final DateTime? serverTimestamp;
  @override
  final String? syncToken;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'SyncResponse(success: $success, processed: $processed, created: $created, updated: $updated, conflicts: $conflicts, errors: $errors, serverTimestamp: $serverTimestamp, syncToken: $syncToken, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.processed, processed) ||
                other.processed == processed) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.updated, updated) || other.updated == updated) &&
            (identical(other.conflicts, conflicts) ||
                other.conflicts == conflicts) &&
            const DeepCollectionEquality().equals(other._errors, _errors) &&
            (identical(other.serverTimestamp, serverTimestamp) ||
                other.serverTimestamp == serverTimestamp) &&
            (identical(other.syncToken, syncToken) ||
                other.syncToken == syncToken) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      success,
      processed,
      created,
      updated,
      conflicts,
      const DeepCollectionEquality().hash(_errors),
      serverTimestamp,
      syncToken,
      errorMessage);

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncResponseImplCopyWith<_$SyncResponseImpl> get copyWith =>
      __$$SyncResponseImplCopyWithImpl<_$SyncResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncResponseImplToJson(
      this,
    );
  }
}

abstract class _SyncResponse implements SyncResponse {
  const factory _SyncResponse(
      {required final bool success,
      required final int processed,
      required final int created,
      required final int updated,
      required final int conflicts,
      final List<String> errors,
      final DateTime? serverTimestamp,
      final String? syncToken,
      final String? errorMessage}) = _$SyncResponseImpl;

  factory _SyncResponse.fromJson(Map<String, dynamic> json) =
      _$SyncResponseImpl.fromJson;

  @override
  bool get success;
  @override
  int get processed;
  @override
  int get created;
  @override
  int get updated;
  @override
  int get conflicts;
  @override
  List<String> get errors;
  @override
  DateTime? get serverTimestamp;
  @override
  String? get syncToken;
  @override
  String? get errorMessage;

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncResponseImplCopyWith<_$SyncResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SyncResult {
  bool get success => throw _privateConstructorUsedError;
  int get processed => throw _privateConstructorUsedError;
  int get created => throw _privateConstructorUsedError;
  int get updated => throw _privateConstructorUsedError;
  int get conflicts => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime? get timestamp => throw _privateConstructorUsedError;

  /// Create a copy of SyncResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncResultCopyWith<SyncResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncResultCopyWith<$Res> {
  factory $SyncResultCopyWith(
          SyncResult value, $Res Function(SyncResult) then) =
      _$SyncResultCopyWithImpl<$Res, SyncResult>;
  @useResult
  $Res call(
      {bool success,
      int processed,
      int created,
      int updated,
      int conflicts,
      String message,
      DateTime? timestamp});
}

/// @nodoc
class _$SyncResultCopyWithImpl<$Res, $Val extends SyncResult>
    implements $SyncResultCopyWith<$Res> {
  _$SyncResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? processed = null,
    Object? created = null,
    Object? updated = null,
    Object? conflicts = null,
    Object? message = null,
    Object? timestamp = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      processed: null == processed
          ? _value.processed
          : processed // ignore: cast_nullable_to_non_nullable
              as int,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as int,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as int,
      conflicts: null == conflicts
          ? _value.conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as int,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncResultImplCopyWith<$Res>
    implements $SyncResultCopyWith<$Res> {
  factory _$$SyncResultImplCopyWith(
          _$SyncResultImpl value, $Res Function(_$SyncResultImpl) then) =
      __$$SyncResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      int processed,
      int created,
      int updated,
      int conflicts,
      String message,
      DateTime? timestamp});
}

/// @nodoc
class __$$SyncResultImplCopyWithImpl<$Res>
    extends _$SyncResultCopyWithImpl<$Res, _$SyncResultImpl>
    implements _$$SyncResultImplCopyWith<$Res> {
  __$$SyncResultImplCopyWithImpl(
      _$SyncResultImpl _value, $Res Function(_$SyncResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? processed = null,
    Object? created = null,
    Object? updated = null,
    Object? conflicts = null,
    Object? message = null,
    Object? timestamp = freezed,
  }) {
    return _then(_$SyncResultImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      processed: null == processed
          ? _value.processed
          : processed // ignore: cast_nullable_to_non_nullable
              as int,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as int,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as int,
      conflicts: null == conflicts
          ? _value.conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as int,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$SyncResultImpl implements _SyncResult {
  const _$SyncResultImpl(
      {required this.success,
      required this.processed,
      this.created = 0,
      this.updated = 0,
      this.conflicts = 0,
      required this.message,
      this.timestamp});

  @override
  final bool success;
  @override
  final int processed;
  @override
  @JsonKey()
  final int created;
  @override
  @JsonKey()
  final int updated;
  @override
  @JsonKey()
  final int conflicts;
  @override
  final String message;
  @override
  final DateTime? timestamp;

  @override
  String toString() {
    return 'SyncResult(success: $success, processed: $processed, created: $created, updated: $updated, conflicts: $conflicts, message: $message, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.processed, processed) ||
                other.processed == processed) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.updated, updated) || other.updated == updated) &&
            (identical(other.conflicts, conflicts) ||
                other.conflicts == conflicts) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, success, processed, created,
      updated, conflicts, message, timestamp);

  /// Create a copy of SyncResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncResultImplCopyWith<_$SyncResultImpl> get copyWith =>
      __$$SyncResultImplCopyWithImpl<_$SyncResultImpl>(this, _$identity);
}

abstract class _SyncResult implements SyncResult {
  const factory _SyncResult(
      {required final bool success,
      required final int processed,
      final int created,
      final int updated,
      final int conflicts,
      required final String message,
      final DateTime? timestamp}) = _$SyncResultImpl;

  @override
  bool get success;
  @override
  int get processed;
  @override
  int get created;
  @override
  int get updated;
  @override
  int get conflicts;
  @override
  String get message;
  @override
  DateTime? get timestamp;

  /// Create a copy of SyncResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncResultImplCopyWith<_$SyncResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiscoveredServer _$DiscoveredServerFromJson(Map<String, dynamic> json) {
  return _DiscoveredServer.fromJson(json);
}

/// @nodoc
mixin _$DiscoveredServer {
  String get name => throw _privateConstructorUsedError;
  String get ipAddress => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  String? get version => throw _privateConstructorUsedError;
  String? get schoolName => throw _privateConstructorUsedError;

  /// Serializes this DiscoveredServer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiscoveredServer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscoveredServerCopyWith<DiscoveredServer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscoveredServerCopyWith<$Res> {
  factory $DiscoveredServerCopyWith(
          DiscoveredServer value, $Res Function(DiscoveredServer) then) =
      _$DiscoveredServerCopyWithImpl<$Res, DiscoveredServer>;
  @useResult
  $Res call(
      {String name,
      String ipAddress,
      int port,
      String? version,
      String? schoolName});
}

/// @nodoc
class _$DiscoveredServerCopyWithImpl<$Res, $Val extends DiscoveredServer>
    implements $DiscoveredServerCopyWith<$Res> {
  _$DiscoveredServerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiscoveredServer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? ipAddress = null,
    Object? port = null,
    Object? version = freezed,
    Object? schoolName = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ipAddress: null == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      schoolName: freezed == schoolName
          ? _value.schoolName
          : schoolName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiscoveredServerImplCopyWith<$Res>
    implements $DiscoveredServerCopyWith<$Res> {
  factory _$$DiscoveredServerImplCopyWith(_$DiscoveredServerImpl value,
          $Res Function(_$DiscoveredServerImpl) then) =
      __$$DiscoveredServerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String ipAddress,
      int port,
      String? version,
      String? schoolName});
}

/// @nodoc
class __$$DiscoveredServerImplCopyWithImpl<$Res>
    extends _$DiscoveredServerCopyWithImpl<$Res, _$DiscoveredServerImpl>
    implements _$$DiscoveredServerImplCopyWith<$Res> {
  __$$DiscoveredServerImplCopyWithImpl(_$DiscoveredServerImpl _value,
      $Res Function(_$DiscoveredServerImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiscoveredServer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? ipAddress = null,
    Object? port = null,
    Object? version = freezed,
    Object? schoolName = freezed,
  }) {
    return _then(_$DiscoveredServerImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ipAddress: null == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      schoolName: freezed == schoolName
          ? _value.schoolName
          : schoolName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiscoveredServerImpl extends _DiscoveredServer {
  const _$DiscoveredServerImpl(
      {required this.name,
      required this.ipAddress,
      required this.port,
      this.version,
      this.schoolName})
      : super._();

  factory _$DiscoveredServerImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiscoveredServerImplFromJson(json);

  @override
  final String name;
  @override
  final String ipAddress;
  @override
  final int port;
  @override
  final String? version;
  @override
  final String? schoolName;

  @override
  String toString() {
    return 'DiscoveredServer(name: $name, ipAddress: $ipAddress, port: $port, version: $version, schoolName: $schoolName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscoveredServerImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.schoolName, schoolName) ||
                other.schoolName == schoolName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, ipAddress, port, version, schoolName);

  /// Create a copy of DiscoveredServer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscoveredServerImplCopyWith<_$DiscoveredServerImpl> get copyWith =>
      __$$DiscoveredServerImplCopyWithImpl<_$DiscoveredServerImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiscoveredServerImplToJson(
      this,
    );
  }
}

abstract class _DiscoveredServer extends DiscoveredServer {
  const factory _DiscoveredServer(
      {required final String name,
      required final String ipAddress,
      required final int port,
      final String? version,
      final String? schoolName}) = _$DiscoveredServerImpl;
  const _DiscoveredServer._() : super._();

  factory _DiscoveredServer.fromJson(Map<String, dynamic> json) =
      _$DiscoveredServerImpl.fromJson;

  @override
  String get name;
  @override
  String get ipAddress;
  @override
  int get port;
  @override
  String? get version;
  @override
  String? get schoolName;

  /// Create a copy of DiscoveredServer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscoveredServerImplCopyWith<_$DiscoveredServerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SyncStatus _$SyncStatusFromJson(Map<String, dynamic> json) {
  return _SyncStatus.fromJson(json);
}

/// @nodoc
mixin _$SyncStatus {
  bool get isOnline => throw _privateConstructorUsedError;
  bool get isSyncing => throw _privateConstructorUsedError;
  int get pendingCount => throw _privateConstructorUsedError;
  String? get serverAddress => throw _privateConstructorUsedError;
  DateTime? get lastSyncTime => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this SyncStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncStatusCopyWith<SyncStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncStatusCopyWith<$Res> {
  factory $SyncStatusCopyWith(
          SyncStatus value, $Res Function(SyncStatus) then) =
      _$SyncStatusCopyWithImpl<$Res, SyncStatus>;
  @useResult
  $Res call(
      {bool isOnline,
      bool isSyncing,
      int pendingCount,
      String? serverAddress,
      DateTime? lastSyncTime,
      String? error});
}

/// @nodoc
class _$SyncStatusCopyWithImpl<$Res, $Val extends SyncStatus>
    implements $SyncStatusCopyWith<$Res> {
  _$SyncStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOnline = null,
    Object? isSyncing = null,
    Object? pendingCount = null,
    Object? serverAddress = freezed,
    Object? lastSyncTime = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      isSyncing: null == isSyncing
          ? _value.isSyncing
          : isSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
      pendingCount: null == pendingCount
          ? _value.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
      serverAddress: freezed == serverAddress
          ? _value.serverAddress
          : serverAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncStatusImplCopyWith<$Res>
    implements $SyncStatusCopyWith<$Res> {
  factory _$$SyncStatusImplCopyWith(
          _$SyncStatusImpl value, $Res Function(_$SyncStatusImpl) then) =
      __$$SyncStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isOnline,
      bool isSyncing,
      int pendingCount,
      String? serverAddress,
      DateTime? lastSyncTime,
      String? error});
}

/// @nodoc
class __$$SyncStatusImplCopyWithImpl<$Res>
    extends _$SyncStatusCopyWithImpl<$Res, _$SyncStatusImpl>
    implements _$$SyncStatusImplCopyWith<$Res> {
  __$$SyncStatusImplCopyWithImpl(
      _$SyncStatusImpl _value, $Res Function(_$SyncStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOnline = null,
    Object? isSyncing = null,
    Object? pendingCount = null,
    Object? serverAddress = freezed,
    Object? lastSyncTime = freezed,
    Object? error = freezed,
  }) {
    return _then(_$SyncStatusImpl(
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      isSyncing: null == isSyncing
          ? _value.isSyncing
          : isSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
      pendingCount: null == pendingCount
          ? _value.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
      serverAddress: freezed == serverAddress
          ? _value.serverAddress
          : serverAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncStatusImpl implements _SyncStatus {
  const _$SyncStatusImpl(
      {this.isOnline = false,
      this.isSyncing = false,
      this.pendingCount = 0,
      this.serverAddress,
      this.lastSyncTime,
      this.error});

  factory _$SyncStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncStatusImplFromJson(json);

  @override
  @JsonKey()
  final bool isOnline;
  @override
  @JsonKey()
  final bool isSyncing;
  @override
  @JsonKey()
  final int pendingCount;
  @override
  final String? serverAddress;
  @override
  final DateTime? lastSyncTime;
  @override
  final String? error;

  @override
  String toString() {
    return 'SyncStatus(isOnline: $isOnline, isSyncing: $isSyncing, pendingCount: $pendingCount, serverAddress: $serverAddress, lastSyncTime: $lastSyncTime, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncStatusImpl &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.isSyncing, isSyncing) ||
                other.isSyncing == isSyncing) &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.serverAddress, serverAddress) ||
                other.serverAddress == serverAddress) &&
            (identical(other.lastSyncTime, lastSyncTime) ||
                other.lastSyncTime == lastSyncTime) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, isOnline, isSyncing,
      pendingCount, serverAddress, lastSyncTime, error);

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncStatusImplCopyWith<_$SyncStatusImpl> get copyWith =>
      __$$SyncStatusImplCopyWithImpl<_$SyncStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncStatusImplToJson(
      this,
    );
  }
}

abstract class _SyncStatus implements SyncStatus {
  const factory _SyncStatus(
      {final bool isOnline,
      final bool isSyncing,
      final int pendingCount,
      final String? serverAddress,
      final DateTime? lastSyncTime,
      final String? error}) = _$SyncStatusImpl;

  factory _SyncStatus.fromJson(Map<String, dynamic> json) =
      _$SyncStatusImpl.fromJson;

  @override
  bool get isOnline;
  @override
  bool get isSyncing;
  @override
  int get pendingCount;
  @override
  String? get serverAddress;
  @override
  DateTime? get lastSyncTime;
  @override
  String? get error;

  /// Create a copy of SyncStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncStatusImplCopyWith<_$SyncStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ServerStatus _$ServerStatusFromJson(Map<String, dynamic> json) {
  return _ServerStatus.fromJson(json);
}

/// @nodoc
mixin _$ServerStatus {
  String get status => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  String? get serverName => throw _privateConstructorUsedError;
  int? get port => throw _privateConstructorUsedError;

  /// Serializes this ServerStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServerStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServerStatusCopyWith<ServerStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServerStatusCopyWith<$Res> {
  factory $ServerStatusCopyWith(
          ServerStatus value, $Res Function(ServerStatus) then) =
      _$ServerStatusCopyWithImpl<$Res, ServerStatus>;
  @useResult
  $Res call(
      {String status,
      DateTime timestamp,
      String version,
      String? serverName,
      int? port});
}

/// @nodoc
class _$ServerStatusCopyWithImpl<$Res, $Val extends ServerStatus>
    implements $ServerStatusCopyWith<$Res> {
  _$ServerStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServerStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? timestamp = null,
    Object? version = null,
    Object? serverName = freezed,
    Object? port = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      serverName: freezed == serverName
          ? _value.serverName
          : serverName // ignore: cast_nullable_to_non_nullable
              as String?,
      port: freezed == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServerStatusImplCopyWith<$Res>
    implements $ServerStatusCopyWith<$Res> {
  factory _$$ServerStatusImplCopyWith(
          _$ServerStatusImpl value, $Res Function(_$ServerStatusImpl) then) =
      __$$ServerStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String status,
      DateTime timestamp,
      String version,
      String? serverName,
      int? port});
}

/// @nodoc
class __$$ServerStatusImplCopyWithImpl<$Res>
    extends _$ServerStatusCopyWithImpl<$Res, _$ServerStatusImpl>
    implements _$$ServerStatusImplCopyWith<$Res> {
  __$$ServerStatusImplCopyWithImpl(
      _$ServerStatusImpl _value, $Res Function(_$ServerStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? timestamp = null,
    Object? version = null,
    Object? serverName = freezed,
    Object? port = freezed,
  }) {
    return _then(_$ServerStatusImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      serverName: freezed == serverName
          ? _value.serverName
          : serverName // ignore: cast_nullable_to_non_nullable
              as String?,
      port: freezed == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServerStatusImpl implements _ServerStatus {
  const _$ServerStatusImpl(
      {required this.status,
      required this.timestamp,
      required this.version,
      this.serverName,
      this.port});

  factory _$ServerStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServerStatusImplFromJson(json);

  @override
  final String status;
  @override
  final DateTime timestamp;
  @override
  final String version;
  @override
  final String? serverName;
  @override
  final int? port;

  @override
  String toString() {
    return 'ServerStatus(status: $status, timestamp: $timestamp, version: $version, serverName: $serverName, port: $port)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerStatusImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.serverName, serverName) ||
                other.serverName == serverName) &&
            (identical(other.port, port) || other.port == port));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, status, timestamp, version, serverName, port);

  /// Create a copy of ServerStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerStatusImplCopyWith<_$ServerStatusImpl> get copyWith =>
      __$$ServerStatusImplCopyWithImpl<_$ServerStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServerStatusImplToJson(
      this,
    );
  }
}

abstract class _ServerStatus implements ServerStatus {
  const factory _ServerStatus(
      {required final String status,
      required final DateTime timestamp,
      required final String version,
      final String? serverName,
      final int? port}) = _$ServerStatusImpl;

  factory _ServerStatus.fromJson(Map<String, dynamic> json) =
      _$ServerStatusImpl.fromJson;

  @override
  String get status;
  @override
  DateTime get timestamp;
  @override
  String get version;
  @override
  String? get serverName;
  @override
  int? get port;

  /// Create a copy of ServerStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerStatusImplCopyWith<_$ServerStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SyncConflict _$SyncConflictFromJson(Map<String, dynamic> json) {
  return _SyncConflict.fromJson(json);
}

/// @nodoc
mixin _$SyncConflict {
  int get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get teacherStatus => throw _privateConstructorUsedError;
  String? get officeStatus => throw _privateConstructorUsedError;
  int? get existingRecordId => throw _privateConstructorUsedError;

  /// Serializes this SyncConflict to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncConflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncConflictCopyWith<SyncConflict> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncConflictCopyWith<$Res> {
  factory $SyncConflictCopyWith(
          SyncConflict value, $Res Function(SyncConflict) then) =
      _$SyncConflictCopyWithImpl<$Res, SyncConflict>;
  @useResult
  $Res call(
      {int studentId,
      String studentName,
      DateTime date,
      String teacherStatus,
      String? officeStatus,
      int? existingRecordId});
}

/// @nodoc
class _$SyncConflictCopyWithImpl<$Res, $Val extends SyncConflict>
    implements $SyncConflictCopyWith<$Res> {
  _$SyncConflictCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncConflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? date = null,
    Object? teacherStatus = null,
    Object? officeStatus = freezed,
    Object? existingRecordId = freezed,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      teacherStatus: null == teacherStatus
          ? _value.teacherStatus
          : teacherStatus // ignore: cast_nullable_to_non_nullable
              as String,
      officeStatus: freezed == officeStatus
          ? _value.officeStatus
          : officeStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      existingRecordId: freezed == existingRecordId
          ? _value.existingRecordId
          : existingRecordId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncConflictImplCopyWith<$Res>
    implements $SyncConflictCopyWith<$Res> {
  factory _$$SyncConflictImplCopyWith(
          _$SyncConflictImpl value, $Res Function(_$SyncConflictImpl) then) =
      __$$SyncConflictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int studentId,
      String studentName,
      DateTime date,
      String teacherStatus,
      String? officeStatus,
      int? existingRecordId});
}

/// @nodoc
class __$$SyncConflictImplCopyWithImpl<$Res>
    extends _$SyncConflictCopyWithImpl<$Res, _$SyncConflictImpl>
    implements _$$SyncConflictImplCopyWith<$Res> {
  __$$SyncConflictImplCopyWithImpl(
      _$SyncConflictImpl _value, $Res Function(_$SyncConflictImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncConflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? date = null,
    Object? teacherStatus = null,
    Object? officeStatus = freezed,
    Object? existingRecordId = freezed,
  }) {
    return _then(_$SyncConflictImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      teacherStatus: null == teacherStatus
          ? _value.teacherStatus
          : teacherStatus // ignore: cast_nullable_to_non_nullable
              as String,
      officeStatus: freezed == officeStatus
          ? _value.officeStatus
          : officeStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      existingRecordId: freezed == existingRecordId
          ? _value.existingRecordId
          : existingRecordId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncConflictImpl implements _SyncConflict {
  const _$SyncConflictImpl(
      {required this.studentId,
      required this.studentName,
      required this.date,
      required this.teacherStatus,
      this.officeStatus,
      this.existingRecordId});

  factory _$SyncConflictImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncConflictImplFromJson(json);

  @override
  final int studentId;
  @override
  final String studentName;
  @override
  final DateTime date;
  @override
  final String teacherStatus;
  @override
  final String? officeStatus;
  @override
  final int? existingRecordId;

  @override
  String toString() {
    return 'SyncConflict(studentId: $studentId, studentName: $studentName, date: $date, teacherStatus: $teacherStatus, officeStatus: $officeStatus, existingRecordId: $existingRecordId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncConflictImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.teacherStatus, teacherStatus) ||
                other.teacherStatus == teacherStatus) &&
            (identical(other.officeStatus, officeStatus) ||
                other.officeStatus == officeStatus) &&
            (identical(other.existingRecordId, existingRecordId) ||
                other.existingRecordId == existingRecordId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, studentId, studentName, date,
      teacherStatus, officeStatus, existingRecordId);

  /// Create a copy of SyncConflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncConflictImplCopyWith<_$SyncConflictImpl> get copyWith =>
      __$$SyncConflictImplCopyWithImpl<_$SyncConflictImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncConflictImplToJson(
      this,
    );
  }
}

abstract class _SyncConflict implements SyncConflict {
  const factory _SyncConflict(
      {required final int studentId,
      required final String studentName,
      required final DateTime date,
      required final String teacherStatus,
      final String? officeStatus,
      final int? existingRecordId}) = _$SyncConflictImpl;

  factory _SyncConflict.fromJson(Map<String, dynamic> json) =
      _$SyncConflictImpl.fromJson;

  @override
  int get studentId;
  @override
  String get studentName;
  @override
  DateTime get date;
  @override
  String get teacherStatus;
  @override
  String? get officeStatus;
  @override
  int? get existingRecordId;

  /// Create a copy of SyncConflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncConflictImplCopyWith<_$SyncConflictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FullSyncResult {
  List<ClassSection> get classes => throw _privateConstructorUsedError;
  Map<ClassSection, List<Student>> get studentsByClass =>
      throw _privateConstructorUsedError;
  Map<ClassSection, String> get errors => throw _privateConstructorUsedError;
  bool get success => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Create a copy of FullSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FullSyncResultCopyWith<FullSyncResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FullSyncResultCopyWith<$Res> {
  factory $FullSyncResultCopyWith(
          FullSyncResult value, $Res Function(FullSyncResult) then) =
      _$FullSyncResultCopyWithImpl<$Res, FullSyncResult>;
  @useResult
  $Res call(
      {List<ClassSection> classes,
      Map<ClassSection, List<Student>> studentsByClass,
      Map<ClassSection, String> errors,
      bool success,
      String message});
}

/// @nodoc
class _$FullSyncResultCopyWithImpl<$Res, $Val extends FullSyncResult>
    implements $FullSyncResultCopyWith<$Res> {
  _$FullSyncResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FullSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classes = null,
    Object? studentsByClass = null,
    Object? errors = null,
    Object? success = null,
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      classes: null == classes
          ? _value.classes
          : classes // ignore: cast_nullable_to_non_nullable
              as List<ClassSection>,
      studentsByClass: null == studentsByClass
          ? _value.studentsByClass
          : studentsByClass // ignore: cast_nullable_to_non_nullable
              as Map<ClassSection, List<Student>>,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as Map<ClassSection, String>,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FullSyncResultImplCopyWith<$Res>
    implements $FullSyncResultCopyWith<$Res> {
  factory _$$FullSyncResultImplCopyWith(_$FullSyncResultImpl value,
          $Res Function(_$FullSyncResultImpl) then) =
      __$$FullSyncResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ClassSection> classes,
      Map<ClassSection, List<Student>> studentsByClass,
      Map<ClassSection, String> errors,
      bool success,
      String message});
}

/// @nodoc
class __$$FullSyncResultImplCopyWithImpl<$Res>
    extends _$FullSyncResultCopyWithImpl<$Res, _$FullSyncResultImpl>
    implements _$$FullSyncResultImplCopyWith<$Res> {
  __$$FullSyncResultImplCopyWithImpl(
      _$FullSyncResultImpl _value, $Res Function(_$FullSyncResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of FullSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classes = null,
    Object? studentsByClass = null,
    Object? errors = null,
    Object? success = null,
    Object? message = null,
  }) {
    return _then(_$FullSyncResultImpl(
      classes: null == classes
          ? _value._classes
          : classes // ignore: cast_nullable_to_non_nullable
              as List<ClassSection>,
      studentsByClass: null == studentsByClass
          ? _value._studentsByClass
          : studentsByClass // ignore: cast_nullable_to_non_nullable
              as Map<ClassSection, List<Student>>,
      errors: null == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as Map<ClassSection, String>,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$FullSyncResultImpl extends _FullSyncResult {
  const _$FullSyncResultImpl(
      {required final List<ClassSection> classes,
      required final Map<ClassSection, List<Student>> studentsByClass,
      required final Map<ClassSection, String> errors,
      required this.success,
      required this.message})
      : _classes = classes,
        _studentsByClass = studentsByClass,
        _errors = errors,
        super._();

  final List<ClassSection> _classes;
  @override
  List<ClassSection> get classes {
    if (_classes is EqualUnmodifiableListView) return _classes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_classes);
  }

  final Map<ClassSection, List<Student>> _studentsByClass;
  @override
  Map<ClassSection, List<Student>> get studentsByClass {
    if (_studentsByClass is EqualUnmodifiableMapView) return _studentsByClass;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_studentsByClass);
  }

  final Map<ClassSection, String> _errors;
  @override
  Map<ClassSection, String> get errors {
    if (_errors is EqualUnmodifiableMapView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_errors);
  }

  @override
  final bool success;
  @override
  final String message;

  @override
  String toString() {
    return 'FullSyncResult(classes: $classes, studentsByClass: $studentsByClass, errors: $errors, success: $success, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FullSyncResultImpl &&
            const DeepCollectionEquality().equals(other._classes, _classes) &&
            const DeepCollectionEquality()
                .equals(other._studentsByClass, _studentsByClass) &&
            const DeepCollectionEquality().equals(other._errors, _errors) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_classes),
      const DeepCollectionEquality().hash(_studentsByClass),
      const DeepCollectionEquality().hash(_errors),
      success,
      message);

  /// Create a copy of FullSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FullSyncResultImplCopyWith<_$FullSyncResultImpl> get copyWith =>
      __$$FullSyncResultImplCopyWithImpl<_$FullSyncResultImpl>(
          this, _$identity);
}

abstract class _FullSyncResult extends FullSyncResult {
  const factory _FullSyncResult(
      {required final List<ClassSection> classes,
      required final Map<ClassSection, List<Student>> studentsByClass,
      required final Map<ClassSection, String> errors,
      required final bool success,
      required final String message}) = _$FullSyncResultImpl;
  const _FullSyncResult._() : super._();

  @override
  List<ClassSection> get classes;
  @override
  Map<ClassSection, List<Student>> get studentsByClass;
  @override
  Map<ClassSection, String> get errors;
  @override
  bool get success;
  @override
  String get message;

  /// Create a copy of FullSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FullSyncResultImplCopyWith<_$FullSyncResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ClassIntegrityMismatch {
  ClassSection get classSection => throw _privateConstructorUsedError;
  int get expected => throw _privateConstructorUsedError;
  int get actual => throw _privateConstructorUsedError;

  /// Create a copy of ClassIntegrityMismatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassIntegrityMismatchCopyWith<ClassIntegrityMismatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassIntegrityMismatchCopyWith<$Res> {
  factory $ClassIntegrityMismatchCopyWith(ClassIntegrityMismatch value,
          $Res Function(ClassIntegrityMismatch) then) =
      _$ClassIntegrityMismatchCopyWithImpl<$Res, ClassIntegrityMismatch>;
  @useResult
  $Res call({ClassSection classSection, int expected, int actual});

  $ClassSectionCopyWith<$Res> get classSection;
}

/// @nodoc
class _$ClassIntegrityMismatchCopyWithImpl<$Res,
        $Val extends ClassIntegrityMismatch>
    implements $ClassIntegrityMismatchCopyWith<$Res> {
  _$ClassIntegrityMismatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassIntegrityMismatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classSection = null,
    Object? expected = null,
    Object? actual = null,
  }) {
    return _then(_value.copyWith(
      classSection: null == classSection
          ? _value.classSection
          : classSection // ignore: cast_nullable_to_non_nullable
              as ClassSection,
      expected: null == expected
          ? _value.expected
          : expected // ignore: cast_nullable_to_non_nullable
              as int,
      actual: null == actual
          ? _value.actual
          : actual // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of ClassIntegrityMismatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClassSectionCopyWith<$Res> get classSection {
    return $ClassSectionCopyWith<$Res>(_value.classSection, (value) {
      return _then(_value.copyWith(classSection: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClassIntegrityMismatchImplCopyWith<$Res>
    implements $ClassIntegrityMismatchCopyWith<$Res> {
  factory _$$ClassIntegrityMismatchImplCopyWith(
          _$ClassIntegrityMismatchImpl value,
          $Res Function(_$ClassIntegrityMismatchImpl) then) =
      __$$ClassIntegrityMismatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ClassSection classSection, int expected, int actual});

  @override
  $ClassSectionCopyWith<$Res> get classSection;
}

/// @nodoc
class __$$ClassIntegrityMismatchImplCopyWithImpl<$Res>
    extends _$ClassIntegrityMismatchCopyWithImpl<$Res,
        _$ClassIntegrityMismatchImpl>
    implements _$$ClassIntegrityMismatchImplCopyWith<$Res> {
  __$$ClassIntegrityMismatchImplCopyWithImpl(
      _$ClassIntegrityMismatchImpl _value,
      $Res Function(_$ClassIntegrityMismatchImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClassIntegrityMismatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classSection = null,
    Object? expected = null,
    Object? actual = null,
  }) {
    return _then(_$ClassIntegrityMismatchImpl(
      classSection: null == classSection
          ? _value.classSection
          : classSection // ignore: cast_nullable_to_non_nullable
              as ClassSection,
      expected: null == expected
          ? _value.expected
          : expected // ignore: cast_nullable_to_non_nullable
              as int,
      actual: null == actual
          ? _value.actual
          : actual // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$ClassIntegrityMismatchImpl extends _ClassIntegrityMismatch {
  const _$ClassIntegrityMismatchImpl(
      {required this.classSection,
      required this.expected,
      required this.actual})
      : super._();

  @override
  final ClassSection classSection;
  @override
  final int expected;
  @override
  final int actual;

  @override
  String toString() {
    return 'ClassIntegrityMismatch(classSection: $classSection, expected: $expected, actual: $actual)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassIntegrityMismatchImpl &&
            (identical(other.classSection, classSection) ||
                other.classSection == classSection) &&
            (identical(other.expected, expected) ||
                other.expected == expected) &&
            (identical(other.actual, actual) || other.actual == actual));
  }

  @override
  int get hashCode => Object.hash(runtimeType, classSection, expected, actual);

  /// Create a copy of ClassIntegrityMismatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassIntegrityMismatchImplCopyWith<_$ClassIntegrityMismatchImpl>
      get copyWith => __$$ClassIntegrityMismatchImplCopyWithImpl<
          _$ClassIntegrityMismatchImpl>(this, _$identity);
}

abstract class _ClassIntegrityMismatch extends ClassIntegrityMismatch {
  const factory _ClassIntegrityMismatch(
      {required final ClassSection classSection,
      required final int expected,
      required final int actual}) = _$ClassIntegrityMismatchImpl;
  const _ClassIntegrityMismatch._() : super._();

  @override
  ClassSection get classSection;
  @override
  int get expected;
  @override
  int get actual;

  /// Create a copy of ClassIntegrityMismatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassIntegrityMismatchImplCopyWith<_$ClassIntegrityMismatchImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DataIntegrityReport {
  List<ClassIntegrityMismatch> get mismatches =>
      throw _privateConstructorUsedError;
  List<ClassSection> get missingStudents => throw _privateConstructorUsedError;
  int get totalClasses => throw _privateConstructorUsedError;
  DateTime? get checkedAt => throw _privateConstructorUsedError;

  /// Create a copy of DataIntegrityReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataIntegrityReportCopyWith<DataIntegrityReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataIntegrityReportCopyWith<$Res> {
  factory $DataIntegrityReportCopyWith(
          DataIntegrityReport value, $Res Function(DataIntegrityReport) then) =
      _$DataIntegrityReportCopyWithImpl<$Res, DataIntegrityReport>;
  @useResult
  $Res call(
      {List<ClassIntegrityMismatch> mismatches,
      List<ClassSection> missingStudents,
      int totalClasses,
      DateTime? checkedAt});
}

/// @nodoc
class _$DataIntegrityReportCopyWithImpl<$Res, $Val extends DataIntegrityReport>
    implements $DataIntegrityReportCopyWith<$Res> {
  _$DataIntegrityReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DataIntegrityReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mismatches = null,
    Object? missingStudents = null,
    Object? totalClasses = null,
    Object? checkedAt = freezed,
  }) {
    return _then(_value.copyWith(
      mismatches: null == mismatches
          ? _value.mismatches
          : mismatches // ignore: cast_nullable_to_non_nullable
              as List<ClassIntegrityMismatch>,
      missingStudents: null == missingStudents
          ? _value.missingStudents
          : missingStudents // ignore: cast_nullable_to_non_nullable
              as List<ClassSection>,
      totalClasses: null == totalClasses
          ? _value.totalClasses
          : totalClasses // ignore: cast_nullable_to_non_nullable
              as int,
      checkedAt: freezed == checkedAt
          ? _value.checkedAt
          : checkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataIntegrityReportImplCopyWith<$Res>
    implements $DataIntegrityReportCopyWith<$Res> {
  factory _$$DataIntegrityReportImplCopyWith(_$DataIntegrityReportImpl value,
          $Res Function(_$DataIntegrityReportImpl) then) =
      __$$DataIntegrityReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ClassIntegrityMismatch> mismatches,
      List<ClassSection> missingStudents,
      int totalClasses,
      DateTime? checkedAt});
}

/// @nodoc
class __$$DataIntegrityReportImplCopyWithImpl<$Res>
    extends _$DataIntegrityReportCopyWithImpl<$Res, _$DataIntegrityReportImpl>
    implements _$$DataIntegrityReportImplCopyWith<$Res> {
  __$$DataIntegrityReportImplCopyWithImpl(_$DataIntegrityReportImpl _value,
      $Res Function(_$DataIntegrityReportImpl) _then)
      : super(_value, _then);

  /// Create a copy of DataIntegrityReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mismatches = null,
    Object? missingStudents = null,
    Object? totalClasses = null,
    Object? checkedAt = freezed,
  }) {
    return _then(_$DataIntegrityReportImpl(
      mismatches: null == mismatches
          ? _value._mismatches
          : mismatches // ignore: cast_nullable_to_non_nullable
              as List<ClassIntegrityMismatch>,
      missingStudents: null == missingStudents
          ? _value._missingStudents
          : missingStudents // ignore: cast_nullable_to_non_nullable
              as List<ClassSection>,
      totalClasses: null == totalClasses
          ? _value.totalClasses
          : totalClasses // ignore: cast_nullable_to_non_nullable
              as int,
      checkedAt: freezed == checkedAt
          ? _value.checkedAt
          : checkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$DataIntegrityReportImpl extends _DataIntegrityReport {
  const _$DataIntegrityReportImpl(
      {final List<ClassIntegrityMismatch> mismatches = const [],
      final List<ClassSection> missingStudents = const [],
      this.totalClasses = 0,
      this.checkedAt})
      : _mismatches = mismatches,
        _missingStudents = missingStudents,
        super._();

  final List<ClassIntegrityMismatch> _mismatches;
  @override
  @JsonKey()
  List<ClassIntegrityMismatch> get mismatches {
    if (_mismatches is EqualUnmodifiableListView) return _mismatches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mismatches);
  }

  final List<ClassSection> _missingStudents;
  @override
  @JsonKey()
  List<ClassSection> get missingStudents {
    if (_missingStudents is EqualUnmodifiableListView) return _missingStudents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missingStudents);
  }

  @override
  @JsonKey()
  final int totalClasses;
  @override
  final DateTime? checkedAt;

  @override
  String toString() {
    return 'DataIntegrityReport(mismatches: $mismatches, missingStudents: $missingStudents, totalClasses: $totalClasses, checkedAt: $checkedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataIntegrityReportImpl &&
            const DeepCollectionEquality()
                .equals(other._mismatches, _mismatches) &&
            const DeepCollectionEquality()
                .equals(other._missingStudents, _missingStudents) &&
            (identical(other.totalClasses, totalClasses) ||
                other.totalClasses == totalClasses) &&
            (identical(other.checkedAt, checkedAt) ||
                other.checkedAt == checkedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_mismatches),
      const DeepCollectionEquality().hash(_missingStudents),
      totalClasses,
      checkedAt);

  /// Create a copy of DataIntegrityReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataIntegrityReportImplCopyWith<_$DataIntegrityReportImpl> get copyWith =>
      __$$DataIntegrityReportImplCopyWithImpl<_$DataIntegrityReportImpl>(
          this, _$identity);
}

abstract class _DataIntegrityReport extends DataIntegrityReport {
  const factory _DataIntegrityReport(
      {final List<ClassIntegrityMismatch> mismatches,
      final List<ClassSection> missingStudents,
      final int totalClasses,
      final DateTime? checkedAt}) = _$DataIntegrityReportImpl;
  const _DataIntegrityReport._() : super._();

  @override
  List<ClassIntegrityMismatch> get mismatches;
  @override
  List<ClassSection> get missingStudents;
  @override
  int get totalClasses;
  @override
  DateTime? get checkedAt;

  /// Create a copy of DataIntegrityReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataIntegrityReportImplCopyWith<_$DataIntegrityReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
