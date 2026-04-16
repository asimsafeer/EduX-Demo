// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teacher.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Teacher _$TeacherFromJson(Map<String, dynamic> json) {
  return _Teacher.fromJson(json);
}

/// @nodoc
mixin _$Teacher {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get token => throw _privateConstructorUsedError;
  DateTime? get tokenExpiry => throw _privateConstructorUsedError;
  List<String> get permissions => throw _privateConstructorUsedError;

  /// Serializes this Teacher to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeacherCopyWith<Teacher> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeacherCopyWith<$Res> {
  factory $TeacherCopyWith(Teacher value, $Res Function(Teacher) then) =
      _$TeacherCopyWithImpl<$Res, Teacher>;
  @useResult
  $Res call(
      {int id,
      String name,
      String email,
      String? photoUrl,
      String? token,
      DateTime? tokenExpiry,
      List<String> permissions});
}

/// @nodoc
class _$TeacherCopyWithImpl<$Res, $Val extends Teacher>
    implements $TeacherCopyWith<$Res> {
  _$TeacherCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? photoUrl = freezed,
    Object? token = freezed,
    Object? tokenExpiry = freezed,
    Object? permissions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenExpiry: freezed == tokenExpiry
          ? _value.tokenExpiry
          : tokenExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      permissions: null == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeacherImplCopyWith<$Res> implements $TeacherCopyWith<$Res> {
  factory _$$TeacherImplCopyWith(
          _$TeacherImpl value, $Res Function(_$TeacherImpl) then) =
      __$$TeacherImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String email,
      String? photoUrl,
      String? token,
      DateTime? tokenExpiry,
      List<String> permissions});
}

/// @nodoc
class __$$TeacherImplCopyWithImpl<$Res>
    extends _$TeacherCopyWithImpl<$Res, _$TeacherImpl>
    implements _$$TeacherImplCopyWith<$Res> {
  __$$TeacherImplCopyWithImpl(
      _$TeacherImpl _value, $Res Function(_$TeacherImpl) _then)
      : super(_value, _then);

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? photoUrl = freezed,
    Object? token = freezed,
    Object? tokenExpiry = freezed,
    Object? permissions = null,
  }) {
    return _then(_$TeacherImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenExpiry: freezed == tokenExpiry
          ? _value.tokenExpiry
          : tokenExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      permissions: null == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeacherImpl implements _Teacher {
  const _$TeacherImpl(
      {required this.id,
      required this.name,
      required this.email,
      this.photoUrl,
      this.token,
      this.tokenExpiry,
      final List<String> permissions = const []})
      : _permissions = permissions;

  factory _$TeacherImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeacherImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String email;
  @override
  final String? photoUrl;
  @override
  final String? token;
  @override
  final DateTime? tokenExpiry;
  final List<String> _permissions;
  @override
  @JsonKey()
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  String toString() {
    return 'Teacher(id: $id, name: $name, email: $email, photoUrl: $photoUrl, token: $token, tokenExpiry: $tokenExpiry, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeacherImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.tokenExpiry, tokenExpiry) ||
                other.tokenExpiry == tokenExpiry) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, email, photoUrl, token,
      tokenExpiry, const DeepCollectionEquality().hash(_permissions));

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeacherImplCopyWith<_$TeacherImpl> get copyWith =>
      __$$TeacherImplCopyWithImpl<_$TeacherImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeacherImplToJson(
      this,
    );
  }
}

abstract class _Teacher implements Teacher {
  const factory _Teacher(
      {required final int id,
      required final String name,
      required final String email,
      final String? photoUrl,
      final String? token,
      final DateTime? tokenExpiry,
      final List<String> permissions}) = _$TeacherImpl;

  factory _Teacher.fromJson(Map<String, dynamic> json) = _$TeacherImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get email;
  @override
  String? get photoUrl;
  @override
  String? get token;
  @override
  DateTime? get tokenExpiry;
  @override
  List<String> get permissions;

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeacherImplCopyWith<_$TeacherImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeacherLoginRequest _$TeacherLoginRequestFromJson(Map<String, dynamic> json) {
  return _TeacherLoginRequest.fromJson(json);
}

/// @nodoc
mixin _$TeacherLoginRequest {
  String get username => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;
  String get deviceName => throw _privateConstructorUsedError;
  String? get appVersion => throw _privateConstructorUsedError;

  /// Serializes this TeacherLoginRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeacherLoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeacherLoginRequestCopyWith<TeacherLoginRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeacherLoginRequestCopyWith<$Res> {
  factory $TeacherLoginRequestCopyWith(
          TeacherLoginRequest value, $Res Function(TeacherLoginRequest) then) =
      _$TeacherLoginRequestCopyWithImpl<$Res, TeacherLoginRequest>;
  @useResult
  $Res call(
      {String username,
      String password,
      String deviceId,
      String deviceName,
      String? appVersion});
}

/// @nodoc
class _$TeacherLoginRequestCopyWithImpl<$Res, $Val extends TeacherLoginRequest>
    implements $TeacherLoginRequestCopyWith<$Res> {
  _$TeacherLoginRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeacherLoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
    Object? deviceId = null,
    Object? deviceName = null,
    Object? appVersion = freezed,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      deviceName: null == deviceName
          ? _value.deviceName
          : deviceName // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: freezed == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeacherLoginRequestImplCopyWith<$Res>
    implements $TeacherLoginRequestCopyWith<$Res> {
  factory _$$TeacherLoginRequestImplCopyWith(_$TeacherLoginRequestImpl value,
          $Res Function(_$TeacherLoginRequestImpl) then) =
      __$$TeacherLoginRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String username,
      String password,
      String deviceId,
      String deviceName,
      String? appVersion});
}

/// @nodoc
class __$$TeacherLoginRequestImplCopyWithImpl<$Res>
    extends _$TeacherLoginRequestCopyWithImpl<$Res, _$TeacherLoginRequestImpl>
    implements _$$TeacherLoginRequestImplCopyWith<$Res> {
  __$$TeacherLoginRequestImplCopyWithImpl(_$TeacherLoginRequestImpl _value,
      $Res Function(_$TeacherLoginRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeacherLoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
    Object? deviceId = null,
    Object? deviceName = null,
    Object? appVersion = freezed,
  }) {
    return _then(_$TeacherLoginRequestImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      deviceName: null == deviceName
          ? _value.deviceName
          : deviceName // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: freezed == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeacherLoginRequestImpl implements _TeacherLoginRequest {
  const _$TeacherLoginRequestImpl(
      {required this.username,
      required this.password,
      required this.deviceId,
      required this.deviceName,
      this.appVersion});

  factory _$TeacherLoginRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeacherLoginRequestImplFromJson(json);

  @override
  final String username;
  @override
  final String password;
  @override
  final String deviceId;
  @override
  final String deviceName;
  @override
  final String? appVersion;

  @override
  String toString() {
    return 'TeacherLoginRequest(username: $username, password: $password, deviceId: $deviceId, deviceName: $deviceName, appVersion: $appVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeacherLoginRequestImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, username, password, deviceId, deviceName, appVersion);

  /// Create a copy of TeacherLoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeacherLoginRequestImplCopyWith<_$TeacherLoginRequestImpl> get copyWith =>
      __$$TeacherLoginRequestImplCopyWithImpl<_$TeacherLoginRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeacherLoginRequestImplToJson(
      this,
    );
  }
}

abstract class _TeacherLoginRequest implements TeacherLoginRequest {
  const factory _TeacherLoginRequest(
      {required final String username,
      required final String password,
      required final String deviceId,
      required final String deviceName,
      final String? appVersion}) = _$TeacherLoginRequestImpl;

  factory _TeacherLoginRequest.fromJson(Map<String, dynamic> json) =
      _$TeacherLoginRequestImpl.fromJson;

  @override
  String get username;
  @override
  String get password;
  @override
  String get deviceId;
  @override
  String get deviceName;
  @override
  String? get appVersion;

  /// Create a copy of TeacherLoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeacherLoginRequestImplCopyWith<_$TeacherLoginRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeacherLoginResponse _$TeacherLoginResponseFromJson(Map<String, dynamic> json) {
  return _TeacherLoginResponse.fromJson(json);
}

/// @nodoc
mixin _$TeacherLoginResponse {
  bool get success => throw _privateConstructorUsedError;
  String? get token => throw _privateConstructorUsedError;
  int? get teacherId => throw _privateConstructorUsedError;
  String? get teacherName => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  DateTime? get tokenExpiry => throw _privateConstructorUsedError;
  List<String> get permissions => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get errorCode => throw _privateConstructorUsedError;

  /// Serializes this TeacherLoginResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeacherLoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeacherLoginResponseCopyWith<TeacherLoginResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeacherLoginResponseCopyWith<$Res> {
  factory $TeacherLoginResponseCopyWith(TeacherLoginResponse value,
          $Res Function(TeacherLoginResponse) then) =
      _$TeacherLoginResponseCopyWithImpl<$Res, TeacherLoginResponse>;
  @useResult
  $Res call(
      {bool success,
      String? token,
      int? teacherId,
      String? teacherName,
      String? email,
      String? photoUrl,
      DateTime? tokenExpiry,
      List<String> permissions,
      String? error,
      String? errorCode});
}

/// @nodoc
class _$TeacherLoginResponseCopyWithImpl<$Res,
        $Val extends TeacherLoginResponse>
    implements $TeacherLoginResponseCopyWith<$Res> {
  _$TeacherLoginResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeacherLoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? token = freezed,
    Object? teacherId = freezed,
    Object? teacherName = freezed,
    Object? email = freezed,
    Object? photoUrl = freezed,
    Object? tokenExpiry = freezed,
    Object? permissions = null,
    Object? error = freezed,
    Object? errorCode = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherId: freezed == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as int?,
      teacherName: freezed == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenExpiry: freezed == tokenExpiry
          ? _value.tokenExpiry
          : tokenExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      permissions: null == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeacherLoginResponseImplCopyWith<$Res>
    implements $TeacherLoginResponseCopyWith<$Res> {
  factory _$$TeacherLoginResponseImplCopyWith(_$TeacherLoginResponseImpl value,
          $Res Function(_$TeacherLoginResponseImpl) then) =
      __$$TeacherLoginResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String? token,
      int? teacherId,
      String? teacherName,
      String? email,
      String? photoUrl,
      DateTime? tokenExpiry,
      List<String> permissions,
      String? error,
      String? errorCode});
}

/// @nodoc
class __$$TeacherLoginResponseImplCopyWithImpl<$Res>
    extends _$TeacherLoginResponseCopyWithImpl<$Res, _$TeacherLoginResponseImpl>
    implements _$$TeacherLoginResponseImplCopyWith<$Res> {
  __$$TeacherLoginResponseImplCopyWithImpl(_$TeacherLoginResponseImpl _value,
      $Res Function(_$TeacherLoginResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeacherLoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? token = freezed,
    Object? teacherId = freezed,
    Object? teacherName = freezed,
    Object? email = freezed,
    Object? photoUrl = freezed,
    Object? tokenExpiry = freezed,
    Object? permissions = null,
    Object? error = freezed,
    Object? errorCode = freezed,
  }) {
    return _then(_$TeacherLoginResponseImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherId: freezed == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as int?,
      teacherName: freezed == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenExpiry: freezed == tokenExpiry
          ? _value.tokenExpiry
          : tokenExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      permissions: null == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeacherLoginResponseImpl implements _TeacherLoginResponse {
  const _$TeacherLoginResponseImpl(
      {required this.success,
      this.token,
      this.teacherId,
      this.teacherName,
      this.email,
      this.photoUrl,
      this.tokenExpiry,
      final List<String> permissions = const [],
      this.error,
      this.errorCode})
      : _permissions = permissions;

  factory _$TeacherLoginResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeacherLoginResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final String? token;
  @override
  final int? teacherId;
  @override
  final String? teacherName;
  @override
  final String? email;
  @override
  final String? photoUrl;
  @override
  final DateTime? tokenExpiry;
  final List<String> _permissions;
  @override
  @JsonKey()
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  final String? error;
  @override
  final String? errorCode;

  @override
  String toString() {
    return 'TeacherLoginResponse(success: $success, token: $token, teacherId: $teacherId, teacherName: $teacherName, email: $email, photoUrl: $photoUrl, tokenExpiry: $tokenExpiry, permissions: $permissions, error: $error, errorCode: $errorCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeacherLoginResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.tokenExpiry, tokenExpiry) ||
                other.tokenExpiry == tokenExpiry) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      success,
      token,
      teacherId,
      teacherName,
      email,
      photoUrl,
      tokenExpiry,
      const DeepCollectionEquality().hash(_permissions),
      error,
      errorCode);

  /// Create a copy of TeacherLoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeacherLoginResponseImplCopyWith<_$TeacherLoginResponseImpl>
      get copyWith =>
          __$$TeacherLoginResponseImplCopyWithImpl<_$TeacherLoginResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeacherLoginResponseImplToJson(
      this,
    );
  }
}

abstract class _TeacherLoginResponse implements TeacherLoginResponse {
  const factory _TeacherLoginResponse(
      {required final bool success,
      final String? token,
      final int? teacherId,
      final String? teacherName,
      final String? email,
      final String? photoUrl,
      final DateTime? tokenExpiry,
      final List<String> permissions,
      final String? error,
      final String? errorCode}) = _$TeacherLoginResponseImpl;

  factory _TeacherLoginResponse.fromJson(Map<String, dynamic> json) =
      _$TeacherLoginResponseImpl.fromJson;

  @override
  bool get success;
  @override
  String? get token;
  @override
  int? get teacherId;
  @override
  String? get teacherName;
  @override
  String? get email;
  @override
  String? get photoUrl;
  @override
  DateTime? get tokenExpiry;
  @override
  List<String> get permissions;
  @override
  String? get error;
  @override
  String? get errorCode;

  /// Create a copy of TeacherLoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeacherLoginResponseImplCopyWith<_$TeacherLoginResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
