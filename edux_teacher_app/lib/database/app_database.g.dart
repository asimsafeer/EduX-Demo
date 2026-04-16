// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedClassesTable extends CachedClasses
    with TableInfo<$CachedClassesTable, CachedClass> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
      'class_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<int> sectionId = GeneratedColumn<int>(
      'section_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _classNameMeta =
      const VerificationMeta('className');
  @override
  late final GeneratedColumn<String> className = GeneratedColumn<String>(
      'class_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionNameMeta =
      const VerificationMeta('sectionName');
  @override
  late final GeneratedColumn<String> sectionName = GeneratedColumn<String>(
      'section_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectNameMeta =
      const VerificationMeta('subjectName');
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
      'subject_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalStudentsMeta =
      const VerificationMeta('totalStudents');
  @override
  late final GeneratedColumn<int> totalStudents = GeneratedColumn<int>(
      'total_students', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isClassTeacherMeta =
      const VerificationMeta('isClassTeacher');
  @override
  late final GeneratedColumn<bool> isClassTeacher = GeneratedColumn<bool>(
      'is_class_teacher', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_class_teacher" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        classId,
        sectionId,
        className,
        sectionName,
        subjectName,
        totalStudents,
        isClassTeacher,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_classes';
  @override
  VerificationContext validateIntegrity(Insertable<CachedClass> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('class_name')) {
      context.handle(_classNameMeta,
          className.isAcceptableOrUnknown(data['class_name']!, _classNameMeta));
    } else if (isInserting) {
      context.missing(_classNameMeta);
    }
    if (data.containsKey('section_name')) {
      context.handle(
          _sectionNameMeta,
          sectionName.isAcceptableOrUnknown(
              data['section_name']!, _sectionNameMeta));
    } else if (isInserting) {
      context.missing(_sectionNameMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
          _subjectNameMeta,
          subjectName.isAcceptableOrUnknown(
              data['subject_name']!, _subjectNameMeta));
    }
    if (data.containsKey('total_students')) {
      context.handle(
          _totalStudentsMeta,
          totalStudents.isAcceptableOrUnknown(
              data['total_students']!, _totalStudentsMeta));
    }
    if (data.containsKey('is_class_teacher')) {
      context.handle(
          _isClassTeacherMeta,
          isClassTeacher.isAcceptableOrUnknown(
              data['is_class_teacher']!, _isClassTeacherMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedClass map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedClass(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}class_id'])!,
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}section_id'])!,
      className: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_name'])!,
      sectionName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_name'])!,
      subjectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_name']),
      totalStudents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_students'])!,
      isClassTeacher: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_class_teacher'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedClassesTable createAlias(String alias) {
    return $CachedClassesTable(attachedDatabase, alias);
  }
}

class CachedClass extends DataClass implements Insertable<CachedClass> {
  final int id;
  final int classId;
  final int sectionId;
  final String className;
  final String sectionName;
  final String? subjectName;
  final int totalStudents;
  final bool isClassTeacher;
  final DateTime cachedAt;
  const CachedClass(
      {required this.id,
      required this.classId,
      required this.sectionId,
      required this.className,
      required this.sectionName,
      this.subjectName,
      required this.totalStudents,
      required this.isClassTeacher,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['class_id'] = Variable<int>(classId);
    map['section_id'] = Variable<int>(sectionId);
    map['class_name'] = Variable<String>(className);
    map['section_name'] = Variable<String>(sectionName);
    if (!nullToAbsent || subjectName != null) {
      map['subject_name'] = Variable<String>(subjectName);
    }
    map['total_students'] = Variable<int>(totalStudents);
    map['is_class_teacher'] = Variable<bool>(isClassTeacher);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedClassesCompanion toCompanion(bool nullToAbsent) {
    return CachedClassesCompanion(
      id: Value(id),
      classId: Value(classId),
      sectionId: Value(sectionId),
      className: Value(className),
      sectionName: Value(sectionName),
      subjectName: subjectName == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectName),
      totalStudents: Value(totalStudents),
      isClassTeacher: Value(isClassTeacher),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedClass.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedClass(
      id: serializer.fromJson<int>(json['id']),
      classId: serializer.fromJson<int>(json['classId']),
      sectionId: serializer.fromJson<int>(json['sectionId']),
      className: serializer.fromJson<String>(json['className']),
      sectionName: serializer.fromJson<String>(json['sectionName']),
      subjectName: serializer.fromJson<String?>(json['subjectName']),
      totalStudents: serializer.fromJson<int>(json['totalStudents']),
      isClassTeacher: serializer.fromJson<bool>(json['isClassTeacher']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'classId': serializer.toJson<int>(classId),
      'sectionId': serializer.toJson<int>(sectionId),
      'className': serializer.toJson<String>(className),
      'sectionName': serializer.toJson<String>(sectionName),
      'subjectName': serializer.toJson<String?>(subjectName),
      'totalStudents': serializer.toJson<int>(totalStudents),
      'isClassTeacher': serializer.toJson<bool>(isClassTeacher),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedClass copyWith(
          {int? id,
          int? classId,
          int? sectionId,
          String? className,
          String? sectionName,
          Value<String?> subjectName = const Value.absent(),
          int? totalStudents,
          bool? isClassTeacher,
          DateTime? cachedAt}) =>
      CachedClass(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        sectionId: sectionId ?? this.sectionId,
        className: className ?? this.className,
        sectionName: sectionName ?? this.sectionName,
        subjectName: subjectName.present ? subjectName.value : this.subjectName,
        totalStudents: totalStudents ?? this.totalStudents,
        isClassTeacher: isClassTeacher ?? this.isClassTeacher,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedClass copyWithCompanion(CachedClassesCompanion data) {
    return CachedClass(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      className: data.className.present ? data.className.value : this.className,
      sectionName:
          data.sectionName.present ? data.sectionName.value : this.sectionName,
      subjectName:
          data.subjectName.present ? data.subjectName.value : this.subjectName,
      totalStudents: data.totalStudents.present
          ? data.totalStudents.value
          : this.totalStudents,
      isClassTeacher: data.isClassTeacher.present
          ? data.isClassTeacher.value
          : this.isClassTeacher,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedClass(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('sectionId: $sectionId, ')
          ..write('className: $className, ')
          ..write('sectionName: $sectionName, ')
          ..write('subjectName: $subjectName, ')
          ..write('totalStudents: $totalStudents, ')
          ..write('isClassTeacher: $isClassTeacher, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, classId, sectionId, className,
      sectionName, subjectName, totalStudents, isClassTeacher, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedClass &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.sectionId == this.sectionId &&
          other.className == this.className &&
          other.sectionName == this.sectionName &&
          other.subjectName == this.subjectName &&
          other.totalStudents == this.totalStudents &&
          other.isClassTeacher == this.isClassTeacher &&
          other.cachedAt == this.cachedAt);
}

class CachedClassesCompanion extends UpdateCompanion<CachedClass> {
  final Value<int> id;
  final Value<int> classId;
  final Value<int> sectionId;
  final Value<String> className;
  final Value<String> sectionName;
  final Value<String?> subjectName;
  final Value<int> totalStudents;
  final Value<bool> isClassTeacher;
  final Value<DateTime> cachedAt;
  const CachedClassesCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.className = const Value.absent(),
    this.sectionName = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.totalStudents = const Value.absent(),
    this.isClassTeacher = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedClassesCompanion.insert({
    this.id = const Value.absent(),
    required int classId,
    required int sectionId,
    required String className,
    required String sectionName,
    this.subjectName = const Value.absent(),
    this.totalStudents = const Value.absent(),
    this.isClassTeacher = const Value.absent(),
    this.cachedAt = const Value.absent(),
  })  : classId = Value(classId),
        sectionId = Value(sectionId),
        className = Value(className),
        sectionName = Value(sectionName);
  static Insertable<CachedClass> custom({
    Expression<int>? id,
    Expression<int>? classId,
    Expression<int>? sectionId,
    Expression<String>? className,
    Expression<String>? sectionName,
    Expression<String>? subjectName,
    Expression<int>? totalStudents,
    Expression<bool>? isClassTeacher,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      if (className != null) 'class_name': className,
      if (sectionName != null) 'section_name': sectionName,
      if (subjectName != null) 'subject_name': subjectName,
      if (totalStudents != null) 'total_students': totalStudents,
      if (isClassTeacher != null) 'is_class_teacher': isClassTeacher,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedClassesCompanion copyWith(
      {Value<int>? id,
      Value<int>? classId,
      Value<int>? sectionId,
      Value<String>? className,
      Value<String>? sectionName,
      Value<String?>? subjectName,
      Value<int>? totalStudents,
      Value<bool>? isClassTeacher,
      Value<DateTime>? cachedAt}) {
    return CachedClassesCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      className: className ?? this.className,
      sectionName: sectionName ?? this.sectionName,
      subjectName: subjectName ?? this.subjectName,
      totalStudents: totalStudents ?? this.totalStudents,
      isClassTeacher: isClassTeacher ?? this.isClassTeacher,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<int>(sectionId.value);
    }
    if (className.present) {
      map['class_name'] = Variable<String>(className.value);
    }
    if (sectionName.present) {
      map['section_name'] = Variable<String>(sectionName.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (totalStudents.present) {
      map['total_students'] = Variable<int>(totalStudents.value);
    }
    if (isClassTeacher.present) {
      map['is_class_teacher'] = Variable<bool>(isClassTeacher.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedClassesCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('sectionId: $sectionId, ')
          ..write('className: $className, ')
          ..write('sectionName: $sectionName, ')
          ..write('subjectName: $subjectName, ')
          ..write('totalStudents: $totalStudents, ')
          ..write('isClassTeacher: $isClassTeacher, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedStudentsTable extends CachedStudents
    with TableInfo<$CachedStudentsTable, CachedStudent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
      'student_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
      'class_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<int> sectionId = GeneratedColumn<int>(
      'section_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rollNumberMeta =
      const VerificationMeta('rollNumber');
  @override
  late final GeneratedColumn<String> rollNumber = GeneratedColumn<String>(
      'roll_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        studentId,
        classId,
        sectionId,
        name,
        rollNumber,
        gender,
        photoUrl,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_students';
  @override
  VerificationContext validateIntegrity(Insertable<CachedStudent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('roll_number')) {
      context.handle(
          _rollNumberMeta,
          rollNumber.isAcceptableOrUnknown(
              data['roll_number']!, _rollNumberMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedStudent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStudent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}student_id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}class_id'])!,
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}section_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      rollNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}roll_number']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedStudentsTable createAlias(String alias) {
    return $CachedStudentsTable(attachedDatabase, alias);
  }
}

class CachedStudent extends DataClass implements Insertable<CachedStudent> {
  final int id;
  final int studentId;
  final int classId;
  final int sectionId;
  final String name;
  final String? rollNumber;
  final String gender;
  final String? photoUrl;
  final DateTime cachedAt;
  const CachedStudent(
      {required this.id,
      required this.studentId,
      required this.classId,
      required this.sectionId,
      required this.name,
      this.rollNumber,
      required this.gender,
      this.photoUrl,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['class_id'] = Variable<int>(classId);
    map['section_id'] = Variable<int>(sectionId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || rollNumber != null) {
      map['roll_number'] = Variable<String>(rollNumber);
    }
    map['gender'] = Variable<String>(gender);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedStudentsCompanion toCompanion(bool nullToAbsent) {
    return CachedStudentsCompanion(
      id: Value(id),
      studentId: Value(studentId),
      classId: Value(classId),
      sectionId: Value(sectionId),
      name: Value(name),
      rollNumber: rollNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(rollNumber),
      gender: Value(gender),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedStudent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStudent(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<int>(json['studentId']),
      classId: serializer.fromJson<int>(json['classId']),
      sectionId: serializer.fromJson<int>(json['sectionId']),
      name: serializer.fromJson<String>(json['name']),
      rollNumber: serializer.fromJson<String?>(json['rollNumber']),
      gender: serializer.fromJson<String>(json['gender']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'classId': serializer.toJson<int>(classId),
      'sectionId': serializer.toJson<int>(sectionId),
      'name': serializer.toJson<String>(name),
      'rollNumber': serializer.toJson<String?>(rollNumber),
      'gender': serializer.toJson<String>(gender),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedStudent copyWith(
          {int? id,
          int? studentId,
          int? classId,
          int? sectionId,
          String? name,
          Value<String?> rollNumber = const Value.absent(),
          String? gender,
          Value<String?> photoUrl = const Value.absent(),
          DateTime? cachedAt}) =>
      CachedStudent(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        classId: classId ?? this.classId,
        sectionId: sectionId ?? this.sectionId,
        name: name ?? this.name,
        rollNumber: rollNumber.present ? rollNumber.value : this.rollNumber,
        gender: gender ?? this.gender,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedStudent copyWithCompanion(CachedStudentsCompanion data) {
    return CachedStudent(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      classId: data.classId.present ? data.classId.value : this.classId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      name: data.name.present ? data.name.value : this.name,
      rollNumber:
          data.rollNumber.present ? data.rollNumber.value : this.rollNumber,
      gender: data.gender.present ? data.gender.value : this.gender,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStudent(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('classId: $classId, ')
          ..write('sectionId: $sectionId, ')
          ..write('name: $name, ')
          ..write('rollNumber: $rollNumber, ')
          ..write('gender: $gender, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentId, classId, sectionId, name,
      rollNumber, gender, photoUrl, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStudent &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.classId == this.classId &&
          other.sectionId == this.sectionId &&
          other.name == this.name &&
          other.rollNumber == this.rollNumber &&
          other.gender == this.gender &&
          other.photoUrl == this.photoUrl &&
          other.cachedAt == this.cachedAt);
}

class CachedStudentsCompanion extends UpdateCompanion<CachedStudent> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<int> classId;
  final Value<int> sectionId;
  final Value<String> name;
  final Value<String?> rollNumber;
  final Value<String> gender;
  final Value<String?> photoUrl;
  final Value<DateTime> cachedAt;
  const CachedStudentsCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.classId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.name = const Value.absent(),
    this.rollNumber = const Value.absent(),
    this.gender = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedStudentsCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required int classId,
    required int sectionId,
    required String name,
    this.rollNumber = const Value.absent(),
    required String gender,
    this.photoUrl = const Value.absent(),
    this.cachedAt = const Value.absent(),
  })  : studentId = Value(studentId),
        classId = Value(classId),
        sectionId = Value(sectionId),
        name = Value(name),
        gender = Value(gender);
  static Insertable<CachedStudent> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<int>? classId,
    Expression<int>? sectionId,
    Expression<String>? name,
    Expression<String>? rollNumber,
    Expression<String>? gender,
    Expression<String>? photoUrl,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (classId != null) 'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      if (name != null) 'name': name,
      if (rollNumber != null) 'roll_number': rollNumber,
      if (gender != null) 'gender': gender,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedStudentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? studentId,
      Value<int>? classId,
      Value<int>? sectionId,
      Value<String>? name,
      Value<String?>? rollNumber,
      Value<String>? gender,
      Value<String?>? photoUrl,
      Value<DateTime>? cachedAt}) {
    return CachedStudentsCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<int>(sectionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rollNumber.present) {
      map['roll_number'] = Variable<String>(rollNumber.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStudentsCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('classId: $classId, ')
          ..write('sectionId: $sectionId, ')
          ..write('name: $name, ')
          ..write('rollNumber: $rollNumber, ')
          ..write('gender: $gender, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingAttendancesTable extends PendingAttendances
    with TableInfo<$PendingAttendancesTable, PendingAttendance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingAttendancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
      'student_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<int> classId = GeneratedColumn<int>(
      'class_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<int> sectionId = GeneratedColumn<int>(
      'section_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remarksMeta =
      const VerificationMeta('remarks');
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
      'remarks', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _markedAtMeta =
      const VerificationMeta('markedAt');
  @override
  late final GeneratedColumn<DateTime> markedAt = GeneratedColumn<DateTime>(
      'marked_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncAttemptsMeta =
      const VerificationMeta('syncAttempts');
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
      'sync_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _syncErrorMeta =
      const VerificationMeta('syncError');
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
      'sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        studentId,
        classId,
        sectionId,
        date,
        status,
        remarks,
        markedAt,
        isSynced,
        syncAttempts,
        syncError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_attendances';
  @override
  VerificationContext validateIntegrity(Insertable<PendingAttendance> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('remarks')) {
      context.handle(_remarksMeta,
          remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta));
    }
    if (data.containsKey('marked_at')) {
      context.handle(_markedAtMeta,
          markedAt.isAcceptableOrUnknown(data['marked_at']!, _markedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
          _syncAttemptsMeta,
          syncAttempts.isAcceptableOrUnknown(
              data['sync_attempts']!, _syncAttemptsMeta));
    }
    if (data.containsKey('sync_error')) {
      context.handle(_syncErrorMeta,
          syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingAttendance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingAttendance(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}student_id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}class_id'])!,
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}section_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      remarks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remarks']),
      markedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}marked_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_attempts'])!,
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
    );
  }

  @override
  $PendingAttendancesTable createAlias(String alias) {
    return $PendingAttendancesTable(attachedDatabase, alias);
  }
}

class PendingAttendance extends DataClass
    implements Insertable<PendingAttendance> {
  final int id;
  final int studentId;
  final int classId;
  final int sectionId;
  final DateTime date;
  final String status;
  final String? remarks;
  final DateTime markedAt;
  final bool isSynced;
  final int syncAttempts;
  final String? syncError;
  const PendingAttendance(
      {required this.id,
      required this.studentId,
      required this.classId,
      required this.sectionId,
      required this.date,
      required this.status,
      this.remarks,
      required this.markedAt,
      required this.isSynced,
      required this.syncAttempts,
      this.syncError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['class_id'] = Variable<int>(classId);
    map['section_id'] = Variable<int>(sectionId);
    map['date'] = Variable<DateTime>(date);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    map['marked_at'] = Variable<DateTime>(markedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  PendingAttendancesCompanion toCompanion(bool nullToAbsent) {
    return PendingAttendancesCompanion(
      id: Value(id),
      studentId: Value(studentId),
      classId: Value(classId),
      sectionId: Value(sectionId),
      date: Value(date),
      status: Value(status),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      markedAt: Value(markedAt),
      isSynced: Value(isSynced),
      syncAttempts: Value(syncAttempts),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory PendingAttendance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingAttendance(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<int>(json['studentId']),
      classId: serializer.fromJson<int>(json['classId']),
      sectionId: serializer.fromJson<int>(json['sectionId']),
      date: serializer.fromJson<DateTime>(json['date']),
      status: serializer.fromJson<String>(json['status']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      markedAt: serializer.fromJson<DateTime>(json['markedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'classId': serializer.toJson<int>(classId),
      'sectionId': serializer.toJson<int>(sectionId),
      'date': serializer.toJson<DateTime>(date),
      'status': serializer.toJson<String>(status),
      'remarks': serializer.toJson<String?>(remarks),
      'markedAt': serializer.toJson<DateTime>(markedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  PendingAttendance copyWith(
          {int? id,
          int? studentId,
          int? classId,
          int? sectionId,
          DateTime? date,
          String? status,
          Value<String?> remarks = const Value.absent(),
          DateTime? markedAt,
          bool? isSynced,
          int? syncAttempts,
          Value<String?> syncError = const Value.absent()}) =>
      PendingAttendance(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        classId: classId ?? this.classId,
        sectionId: sectionId ?? this.sectionId,
        date: date ?? this.date,
        status: status ?? this.status,
        remarks: remarks.present ? remarks.value : this.remarks,
        markedAt: markedAt ?? this.markedAt,
        isSynced: isSynced ?? this.isSynced,
        syncAttempts: syncAttempts ?? this.syncAttempts,
        syncError: syncError.present ? syncError.value : this.syncError,
      );
  PendingAttendance copyWithCompanion(PendingAttendancesCompanion data) {
    return PendingAttendance(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      classId: data.classId.present ? data.classId.value : this.classId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      markedAt: data.markedAt.present ? data.markedAt.value : this.markedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingAttendance(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('classId: $classId, ')
          ..write('sectionId: $sectionId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('remarks: $remarks, ')
          ..write('markedAt: $markedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentId, classId, sectionId, date,
      status, remarks, markedAt, isSynced, syncAttempts, syncError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingAttendance &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.classId == this.classId &&
          other.sectionId == this.sectionId &&
          other.date == this.date &&
          other.status == this.status &&
          other.remarks == this.remarks &&
          other.markedAt == this.markedAt &&
          other.isSynced == this.isSynced &&
          other.syncAttempts == this.syncAttempts &&
          other.syncError == this.syncError);
}

class PendingAttendancesCompanion extends UpdateCompanion<PendingAttendance> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<int> classId;
  final Value<int> sectionId;
  final Value<DateTime> date;
  final Value<String> status;
  final Value<String?> remarks;
  final Value<DateTime> markedAt;
  final Value<bool> isSynced;
  final Value<int> syncAttempts;
  final Value<String?> syncError;
  const PendingAttendancesCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.classId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.remarks = const Value.absent(),
    this.markedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.syncError = const Value.absent(),
  });
  PendingAttendancesCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required int classId,
    required int sectionId,
    required DateTime date,
    required String status,
    this.remarks = const Value.absent(),
    this.markedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.syncError = const Value.absent(),
  })  : studentId = Value(studentId),
        classId = Value(classId),
        sectionId = Value(sectionId),
        date = Value(date),
        status = Value(status);
  static Insertable<PendingAttendance> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<int>? classId,
    Expression<int>? sectionId,
    Expression<DateTime>? date,
    Expression<String>? status,
    Expression<String>? remarks,
    Expression<DateTime>? markedAt,
    Expression<bool>? isSynced,
    Expression<int>? syncAttempts,
    Expression<String>? syncError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (classId != null) 'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (remarks != null) 'remarks': remarks,
      if (markedAt != null) 'marked_at': markedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (syncError != null) 'sync_error': syncError,
    });
  }

  PendingAttendancesCompanion copyWith(
      {Value<int>? id,
      Value<int>? studentId,
      Value<int>? classId,
      Value<int>? sectionId,
      Value<DateTime>? date,
      Value<String>? status,
      Value<String?>? remarks,
      Value<DateTime>? markedAt,
      Value<bool>? isSynced,
      Value<int>? syncAttempts,
      Value<String?>? syncError}) {
    return PendingAttendancesCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      markedAt: markedAt ?? this.markedAt,
      isSynced: isSynced ?? this.isSynced,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      syncError: syncError ?? this.syncError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<int>(classId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<int>(sectionId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (markedAt.present) {
      map['marked_at'] = Variable<DateTime>(markedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingAttendancesCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('classId: $classId, ')
          ..write('sectionId: $sectionId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('remarks: $remarks, ')
          ..write('markedAt: $markedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }
}

class $SyncConfigTable extends SyncConfig
    with TableInfo<$SyncConfigTable, SyncConfigEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_config';
  @override
  VerificationContext validateIntegrity(Insertable<SyncConfigEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncConfigEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConfigEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncConfigTable createAlias(String alias) {
    return $SyncConfigTable(attachedDatabase, alias);
  }
}

class SyncConfigEntry extends DataClass implements Insertable<SyncConfigEntry> {
  final String key;
  final String? value;
  final DateTime updatedAt;
  const SyncConfigEntry(
      {required this.key, this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncConfigCompanion toCompanion(bool nullToAbsent) {
    return SyncConfigCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncConfigEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConfigEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncConfigEntry copyWith(
          {String? key,
          Value<String?> value = const Value.absent(),
          DateTime? updatedAt}) =>
      SyncConfigEntry(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncConfigEntry copyWithCompanion(SyncConfigCompanion data) {
    return SyncConfigEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConfigEntry(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConfigEntry &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncConfigCompanion extends UpdateCompanion<SyncConfigEntry> {
  final Value<String> key;
  final Value<String?> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncConfigCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConfigCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SyncConfigEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConfigCompanion copyWith(
      {Value<String>? key,
      Value<String?>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SyncConfigCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConfigCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedClassesTable cachedClasses = $CachedClassesTable(this);
  late final $CachedStudentsTable cachedStudents = $CachedStudentsTable(this);
  late final $PendingAttendancesTable pendingAttendances =
      $PendingAttendancesTable(this);
  late final $SyncConfigTable syncConfig = $SyncConfigTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedClasses, cachedStudents, pendingAttendances, syncConfig];
}

typedef $$CachedClassesTableCreateCompanionBuilder = CachedClassesCompanion
    Function({
  Value<int> id,
  required int classId,
  required int sectionId,
  required String className,
  required String sectionName,
  Value<String?> subjectName,
  Value<int> totalStudents,
  Value<bool> isClassTeacher,
  Value<DateTime> cachedAt,
});
typedef $$CachedClassesTableUpdateCompanionBuilder = CachedClassesCompanion
    Function({
  Value<int> id,
  Value<int> classId,
  Value<int> sectionId,
  Value<String> className,
  Value<String> sectionName,
  Value<String?> subjectName,
  Value<int> totalStudents,
  Value<bool> isClassTeacher,
  Value<DateTime> cachedAt,
});

class $$CachedClassesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedClassesTable> {
  $$CachedClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get className => $composableBuilder(
      column: $table.className, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionName => $composableBuilder(
      column: $table.sectionName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalStudents => $composableBuilder(
      column: $table.totalStudents, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isClassTeacher => $composableBuilder(
      column: $table.isClassTeacher,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedClassesTable> {
  $$CachedClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get className => $composableBuilder(
      column: $table.className, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionName => $composableBuilder(
      column: $table.sectionName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalStudents => $composableBuilder(
      column: $table.totalStudents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isClassTeacher => $composableBuilder(
      column: $table.isClassTeacher,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedClassesTable> {
  $$CachedClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<int> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<String> get className =>
      $composableBuilder(column: $table.className, builder: (column) => column);

  GeneratedColumn<String> get sectionName => $composableBuilder(
      column: $table.sectionName, builder: (column) => column);

  GeneratedColumn<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => column);

  GeneratedColumn<int> get totalStudents => $composableBuilder(
      column: $table.totalStudents, builder: (column) => column);

  GeneratedColumn<bool> get isClassTeacher => $composableBuilder(
      column: $table.isClassTeacher, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedClassesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedClassesTable,
    CachedClass,
    $$CachedClassesTableFilterComposer,
    $$CachedClassesTableOrderingComposer,
    $$CachedClassesTableAnnotationComposer,
    $$CachedClassesTableCreateCompanionBuilder,
    $$CachedClassesTableUpdateCompanionBuilder,
    (
      CachedClass,
      BaseReferences<_$AppDatabase, $CachedClassesTable, CachedClass>
    ),
    CachedClass,
    PrefetchHooks Function()> {
  $$CachedClassesTableTableManager(_$AppDatabase db, $CachedClassesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> classId = const Value.absent(),
            Value<int> sectionId = const Value.absent(),
            Value<String> className = const Value.absent(),
            Value<String> sectionName = const Value.absent(),
            Value<String?> subjectName = const Value.absent(),
            Value<int> totalStudents = const Value.absent(),
            Value<bool> isClassTeacher = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedClassesCompanion(
            id: id,
            classId: classId,
            sectionId: sectionId,
            className: className,
            sectionName: sectionName,
            subjectName: subjectName,
            totalStudents: totalStudents,
            isClassTeacher: isClassTeacher,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int classId,
            required int sectionId,
            required String className,
            required String sectionName,
            Value<String?> subjectName = const Value.absent(),
            Value<int> totalStudents = const Value.absent(),
            Value<bool> isClassTeacher = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedClassesCompanion.insert(
            id: id,
            classId: classId,
            sectionId: sectionId,
            className: className,
            sectionName: sectionName,
            subjectName: subjectName,
            totalStudents: totalStudents,
            isClassTeacher: isClassTeacher,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedClassesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedClassesTable,
    CachedClass,
    $$CachedClassesTableFilterComposer,
    $$CachedClassesTableOrderingComposer,
    $$CachedClassesTableAnnotationComposer,
    $$CachedClassesTableCreateCompanionBuilder,
    $$CachedClassesTableUpdateCompanionBuilder,
    (
      CachedClass,
      BaseReferences<_$AppDatabase, $CachedClassesTable, CachedClass>
    ),
    CachedClass,
    PrefetchHooks Function()>;
typedef $$CachedStudentsTableCreateCompanionBuilder = CachedStudentsCompanion
    Function({
  Value<int> id,
  required int studentId,
  required int classId,
  required int sectionId,
  required String name,
  Value<String?> rollNumber,
  required String gender,
  Value<String?> photoUrl,
  Value<DateTime> cachedAt,
});
typedef $$CachedStudentsTableUpdateCompanionBuilder = CachedStudentsCompanion
    Function({
  Value<int> id,
  Value<int> studentId,
  Value<int> classId,
  Value<int> sectionId,
  Value<String> name,
  Value<String?> rollNumber,
  Value<String> gender,
  Value<String?> photoUrl,
  Value<DateTime> cachedAt,
});

class $$CachedStudentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStudentsTable> {
  $$CachedStudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rollNumber => $composableBuilder(
      column: $table.rollNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedStudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStudentsTable> {
  $$CachedStudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rollNumber => $composableBuilder(
      column: $table.rollNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedStudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStudentsTable> {
  $$CachedStudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<int> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<int> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rollNumber => $composableBuilder(
      column: $table.rollNumber, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedStudentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedStudentsTable,
    CachedStudent,
    $$CachedStudentsTableFilterComposer,
    $$CachedStudentsTableOrderingComposer,
    $$CachedStudentsTableAnnotationComposer,
    $$CachedStudentsTableCreateCompanionBuilder,
    $$CachedStudentsTableUpdateCompanionBuilder,
    (
      CachedStudent,
      BaseReferences<_$AppDatabase, $CachedStudentsTable, CachedStudent>
    ),
    CachedStudent,
    PrefetchHooks Function()> {
  $$CachedStudentsTableTableManager(
      _$AppDatabase db, $CachedStudentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> studentId = const Value.absent(),
            Value<int> classId = const Value.absent(),
            Value<int> sectionId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> rollNumber = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedStudentsCompanion(
            id: id,
            studentId: studentId,
            classId: classId,
            sectionId: sectionId,
            name: name,
            rollNumber: rollNumber,
            gender: gender,
            photoUrl: photoUrl,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int studentId,
            required int classId,
            required int sectionId,
            required String name,
            Value<String?> rollNumber = const Value.absent(),
            required String gender,
            Value<String?> photoUrl = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedStudentsCompanion.insert(
            id: id,
            studentId: studentId,
            classId: classId,
            sectionId: sectionId,
            name: name,
            rollNumber: rollNumber,
            gender: gender,
            photoUrl: photoUrl,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedStudentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedStudentsTable,
    CachedStudent,
    $$CachedStudentsTableFilterComposer,
    $$CachedStudentsTableOrderingComposer,
    $$CachedStudentsTableAnnotationComposer,
    $$CachedStudentsTableCreateCompanionBuilder,
    $$CachedStudentsTableUpdateCompanionBuilder,
    (
      CachedStudent,
      BaseReferences<_$AppDatabase, $CachedStudentsTable, CachedStudent>
    ),
    CachedStudent,
    PrefetchHooks Function()>;
typedef $$PendingAttendancesTableCreateCompanionBuilder
    = PendingAttendancesCompanion Function({
  Value<int> id,
  required int studentId,
  required int classId,
  required int sectionId,
  required DateTime date,
  required String status,
  Value<String?> remarks,
  Value<DateTime> markedAt,
  Value<bool> isSynced,
  Value<int> syncAttempts,
  Value<String?> syncError,
});
typedef $$PendingAttendancesTableUpdateCompanionBuilder
    = PendingAttendancesCompanion Function({
  Value<int> id,
  Value<int> studentId,
  Value<int> classId,
  Value<int> sectionId,
  Value<DateTime> date,
  Value<String> status,
  Value<String?> remarks,
  Value<DateTime> markedAt,
  Value<bool> isSynced,
  Value<int> syncAttempts,
  Value<String?> syncError,
});

class $$PendingAttendancesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingAttendancesTable> {
  $$PendingAttendancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get markedAt => $composableBuilder(
      column: $table.markedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncAttempts => $composableBuilder(
      column: $table.syncAttempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));
}

class $$PendingAttendancesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingAttendancesTable> {
  $$PendingAttendancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get markedAt => $composableBuilder(
      column: $table.markedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
      column: $table.syncAttempts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));
}

class $$PendingAttendancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingAttendancesTable> {
  $$PendingAttendancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<int> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<int> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<DateTime> get markedAt =>
      $composableBuilder(column: $table.markedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
      column: $table.syncAttempts, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$PendingAttendancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingAttendancesTable,
    PendingAttendance,
    $$PendingAttendancesTableFilterComposer,
    $$PendingAttendancesTableOrderingComposer,
    $$PendingAttendancesTableAnnotationComposer,
    $$PendingAttendancesTableCreateCompanionBuilder,
    $$PendingAttendancesTableUpdateCompanionBuilder,
    (
      PendingAttendance,
      BaseReferences<_$AppDatabase, $PendingAttendancesTable, PendingAttendance>
    ),
    PendingAttendance,
    PrefetchHooks Function()> {
  $$PendingAttendancesTableTableManager(
      _$AppDatabase db, $PendingAttendancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingAttendancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingAttendancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingAttendancesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> studentId = const Value.absent(),
            Value<int> classId = const Value.absent(),
            Value<int> sectionId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> remarks = const Value.absent(),
            Value<DateTime> markedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> syncAttempts = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
          }) =>
              PendingAttendancesCompanion(
            id: id,
            studentId: studentId,
            classId: classId,
            sectionId: sectionId,
            date: date,
            status: status,
            remarks: remarks,
            markedAt: markedAt,
            isSynced: isSynced,
            syncAttempts: syncAttempts,
            syncError: syncError,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int studentId,
            required int classId,
            required int sectionId,
            required DateTime date,
            required String status,
            Value<String?> remarks = const Value.absent(),
            Value<DateTime> markedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> syncAttempts = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
          }) =>
              PendingAttendancesCompanion.insert(
            id: id,
            studentId: studentId,
            classId: classId,
            sectionId: sectionId,
            date: date,
            status: status,
            remarks: remarks,
            markedAt: markedAt,
            isSynced: isSynced,
            syncAttempts: syncAttempts,
            syncError: syncError,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingAttendancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingAttendancesTable,
    PendingAttendance,
    $$PendingAttendancesTableFilterComposer,
    $$PendingAttendancesTableOrderingComposer,
    $$PendingAttendancesTableAnnotationComposer,
    $$PendingAttendancesTableCreateCompanionBuilder,
    $$PendingAttendancesTableUpdateCompanionBuilder,
    (
      PendingAttendance,
      BaseReferences<_$AppDatabase, $PendingAttendancesTable, PendingAttendance>
    ),
    PendingAttendance,
    PrefetchHooks Function()>;
typedef $$SyncConfigTableCreateCompanionBuilder = SyncConfigCompanion Function({
  required String key,
  Value<String?> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$SyncConfigTableUpdateCompanionBuilder = SyncConfigCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SyncConfigTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConfigTable> {
  $$SyncConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConfigTable> {
  $$SyncConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConfigTable> {
  $$SyncConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncConfigTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncConfigTable,
    SyncConfigEntry,
    $$SyncConfigTableFilterComposer,
    $$SyncConfigTableOrderingComposer,
    $$SyncConfigTableAnnotationComposer,
    $$SyncConfigTableCreateCompanionBuilder,
    $$SyncConfigTableUpdateCompanionBuilder,
    (
      SyncConfigEntry,
      BaseReferences<_$AppDatabase, $SyncConfigTable, SyncConfigEntry>
    ),
    SyncConfigEntry,
    PrefetchHooks Function()> {
  $$SyncConfigTableTableManager(_$AppDatabase db, $SyncConfigTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConfigCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConfigCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncConfigTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncConfigTable,
    SyncConfigEntry,
    $$SyncConfigTableFilterComposer,
    $$SyncConfigTableOrderingComposer,
    $$SyncConfigTableAnnotationComposer,
    $$SyncConfigTableCreateCompanionBuilder,
    $$SyncConfigTableUpdateCompanionBuilder,
    (
      SyncConfigEntry,
      BaseReferences<_$AppDatabase, $SyncConfigTable, SyncConfigEntry>
    ),
    SyncConfigEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedClassesTableTableManager get cachedClasses =>
      $$CachedClassesTableTableManager(_db, _db.cachedClasses);
  $$CachedStudentsTableTableManager get cachedStudents =>
      $$CachedStudentsTableTableManager(_db, _db.cachedStudents);
  $$PendingAttendancesTableTableManager get pendingAttendances =>
      $$PendingAttendancesTableTableManager(_db, _db.pendingAttendances);
  $$SyncConfigTableTableManager get syncConfig =>
      $$SyncConfigTableTableManager(_db, _db.syncConfig);
}
