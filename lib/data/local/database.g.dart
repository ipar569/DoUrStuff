// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class ProfileMetadata extends Table
    with TableInfo<ProfileMetadata, ProfileMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ProfileMetadata(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (singleton = 1)',
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lineageIdMeta = const VerificationMeta(
    'lineageId',
  );
  late final GeneratedColumn<String> lineageId = GeneratedColumn<String>(
    'lineage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deviceEpochMeta = const VerificationMeta(
    'deviceEpoch',
  );
  late final GeneratedColumn<String> deviceEpoch = GeneratedColumn<String>(
    'device_epoch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nextSequenceMeta = const VerificationMeta(
    'nextSequence',
  );
  late final GeneratedColumn<int> nextSequence = GeneratedColumn<int>(
    'next_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (next_sequence > 0)',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    singleton,
    profileId,
    lineageId,
    deviceEpoch,
    nextSequence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('lineage_id')) {
      context.handle(
        _lineageIdMeta,
        lineageId.isAcceptableOrUnknown(data['lineage_id']!, _lineageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineageIdMeta);
    }
    if (data.containsKey('device_epoch')) {
      context.handle(
        _deviceEpochMeta,
        deviceEpoch.isAcceptableOrUnknown(
          data['device_epoch']!,
          _deviceEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceEpochMeta);
    }
    if (data.containsKey('next_sequence')) {
      context.handle(
        _nextSequenceMeta,
        nextSequence.isAcceptableOrUnknown(
          data['next_sequence']!,
          _nextSequenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singleton};
  @override
  ProfileMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileMetadataData(
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      lineageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lineage_id'],
      )!,
      deviceEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_epoch'],
      )!,
      nextSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_sequence'],
      )!,
    );
  }

  @override
  ProfileMetadata createAlias(String alias) {
    return ProfileMetadata(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ProfileMetadataData extends DataClass
    implements Insertable<ProfileMetadataData> {
  final int singleton;
  final String profileId;
  final String lineageId;
  final String deviceEpoch;
  final int nextSequence;
  const ProfileMetadataData({
    required this.singleton,
    required this.profileId,
    required this.lineageId,
    required this.deviceEpoch,
    required this.nextSequence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton'] = Variable<int>(singleton);
    map['profile_id'] = Variable<String>(profileId);
    map['lineage_id'] = Variable<String>(lineageId);
    map['device_epoch'] = Variable<String>(deviceEpoch);
    map['next_sequence'] = Variable<int>(nextSequence);
    return map;
  }

  ProfileMetadataCompanion toCompanion(bool nullToAbsent) {
    return ProfileMetadataCompanion(
      singleton: Value(singleton),
      profileId: Value(profileId),
      lineageId: Value(lineageId),
      deviceEpoch: Value(deviceEpoch),
      nextSequence: Value(nextSequence),
    );
  }

  factory ProfileMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileMetadataData(
      singleton: serializer.fromJson<int>(json['singleton']),
      profileId: serializer.fromJson<String>(json['profile_id']),
      lineageId: serializer.fromJson<String>(json['lineage_id']),
      deviceEpoch: serializer.fromJson<String>(json['device_epoch']),
      nextSequence: serializer.fromJson<int>(json['next_sequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singleton': serializer.toJson<int>(singleton),
      'profile_id': serializer.toJson<String>(profileId),
      'lineage_id': serializer.toJson<String>(lineageId),
      'device_epoch': serializer.toJson<String>(deviceEpoch),
      'next_sequence': serializer.toJson<int>(nextSequence),
    };
  }

  ProfileMetadataData copyWith({
    int? singleton,
    String? profileId,
    String? lineageId,
    String? deviceEpoch,
    int? nextSequence,
  }) => ProfileMetadataData(
    singleton: singleton ?? this.singleton,
    profileId: profileId ?? this.profileId,
    lineageId: lineageId ?? this.lineageId,
    deviceEpoch: deviceEpoch ?? this.deviceEpoch,
    nextSequence: nextSequence ?? this.nextSequence,
  );
  ProfileMetadataData copyWithCompanion(ProfileMetadataCompanion data) {
    return ProfileMetadataData(
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      lineageId: data.lineageId.present ? data.lineageId.value : this.lineageId,
      deviceEpoch: data.deviceEpoch.present
          ? data.deviceEpoch.value
          : this.deviceEpoch,
      nextSequence: data.nextSequence.present
          ? data.nextSequence.value
          : this.nextSequence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileMetadataData(')
          ..write('singleton: $singleton, ')
          ..write('profileId: $profileId, ')
          ..write('lineageId: $lineageId, ')
          ..write('deviceEpoch: $deviceEpoch, ')
          ..write('nextSequence: $nextSequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(singleton, profileId, lineageId, deviceEpoch, nextSequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileMetadataData &&
          other.singleton == this.singleton &&
          other.profileId == this.profileId &&
          other.lineageId == this.lineageId &&
          other.deviceEpoch == this.deviceEpoch &&
          other.nextSequence == this.nextSequence);
}

class ProfileMetadataCompanion extends UpdateCompanion<ProfileMetadataData> {
  final Value<int> singleton;
  final Value<String> profileId;
  final Value<String> lineageId;
  final Value<String> deviceEpoch;
  final Value<int> nextSequence;
  const ProfileMetadataCompanion({
    this.singleton = const Value.absent(),
    this.profileId = const Value.absent(),
    this.lineageId = const Value.absent(),
    this.deviceEpoch = const Value.absent(),
    this.nextSequence = const Value.absent(),
  });
  ProfileMetadataCompanion.insert({
    this.singleton = const Value.absent(),
    required String profileId,
    required String lineageId,
    required String deviceEpoch,
    this.nextSequence = const Value.absent(),
  }) : profileId = Value(profileId),
       lineageId = Value(lineageId),
       deviceEpoch = Value(deviceEpoch);
  static Insertable<ProfileMetadataData> custom({
    Expression<int>? singleton,
    Expression<String>? profileId,
    Expression<String>? lineageId,
    Expression<String>? deviceEpoch,
    Expression<int>? nextSequence,
  }) {
    return RawValuesInsertable({
      if (singleton != null) 'singleton': singleton,
      if (profileId != null) 'profile_id': profileId,
      if (lineageId != null) 'lineage_id': lineageId,
      if (deviceEpoch != null) 'device_epoch': deviceEpoch,
      if (nextSequence != null) 'next_sequence': nextSequence,
    });
  }

  ProfileMetadataCompanion copyWith({
    Value<int>? singleton,
    Value<String>? profileId,
    Value<String>? lineageId,
    Value<String>? deviceEpoch,
    Value<int>? nextSequence,
  }) {
    return ProfileMetadataCompanion(
      singleton: singleton ?? this.singleton,
      profileId: profileId ?? this.profileId,
      lineageId: lineageId ?? this.lineageId,
      deviceEpoch: deviceEpoch ?? this.deviceEpoch,
      nextSequence: nextSequence ?? this.nextSequence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (lineageId.present) {
      map['lineage_id'] = Variable<String>(lineageId.value);
    }
    if (deviceEpoch.present) {
      map['device_epoch'] = Variable<String>(deviceEpoch.value);
    }
    if (nextSequence.present) {
      map['next_sequence'] = Variable<int>(nextSequence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileMetadataCompanion(')
          ..write('singleton: $singleton, ')
          ..write('profileId: $profileId, ')
          ..write('lineageId: $lineageId, ')
          ..write('deviceEpoch: $deviceEpoch, ')
          ..write('nextSequence: $nextSequence')
          ..write(')'))
        .toString();
  }
}

class Tasks extends Table with TableInfo<Tasks, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tasks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 500)',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'todo\' CHECK (status IN (\'todo\', \'in_progress\', \'completed\', \'cancelled\'))',
    defaultValue: const CustomExpression('\'todo\''),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (priority BETWEEN 0 AND 3)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _dueKindMeta = const VerificationMeta(
    'dueKind',
  );
  late final GeneratedColumn<String> dueKind = GeneratedColumn<String>(
    'due_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'none\' CHECK (due_kind IN (\'none\', \'date\', \'timed\'))',
    defaultValue: const CustomExpression('\'none\''),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _dueInstantMeta = const VerificationMeta(
    'dueInstant',
  );
  late final GeneratedColumn<int> dueInstant = GeneratedColumn<int>(
    'due_instant',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _dueZoneMeta = const VerificationMeta(
    'dueZone',
  );
  late final GeneratedColumn<String> dueZone = GeneratedColumn<String>(
    'due_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _dueWallTimeMeta = const VerificationMeta(
    'dueWallTime',
  );
  late final GeneratedColumn<String> dueWallTime = GeneratedColumn<String>(
    'due_wall_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _estimateMinutesMeta = const VerificationMeta(
    'estimateMinutes',
  );
  late final GeneratedColumn<int> estimateMinutes = GeneratedColumn<int>(
    'estimate_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (estimate_minutes > 0)',
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'UNIQUE',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    status,
    priority,
    dueKind,
    dueDate,
    dueInstant,
    dueZone,
    dueWallTime,
    estimateMinutes,
    occurrenceId,
    createdAt,
    updatedAt,
    completedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('due_kind')) {
      context.handle(
        _dueKindMeta,
        dueKind.isAcceptableOrUnknown(data['due_kind']!, _dueKindMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('due_instant')) {
      context.handle(
        _dueInstantMeta,
        dueInstant.isAcceptableOrUnknown(data['due_instant']!, _dueInstantMeta),
      );
    }
    if (data.containsKey('due_zone')) {
      context.handle(
        _dueZoneMeta,
        dueZone.isAcceptableOrUnknown(data['due_zone']!, _dueZoneMeta),
      );
    }
    if (data.containsKey('due_wall_time')) {
      context.handle(
        _dueWallTimeMeta,
        dueWallTime.isAcceptableOrUnknown(
          data['due_wall_time']!,
          _dueWallTimeMeta,
        ),
      );
    }
    if (data.containsKey('estimate_minutes')) {
      context.handle(
        _estimateMinutesMeta,
        estimateMinutes.isAcceptableOrUnknown(
          data['estimate_minutes']!,
          _estimateMinutesMeta,
        ),
      );
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      dueKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_kind'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      dueInstant: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_instant'],
      ),
      dueZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_zone'],
      ),
      dueWallTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_wall_time'],
      ),
      estimateMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_minutes'],
      ),
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Tasks createAlias(String alias) {
    return Tasks(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((status = \'completed\')=(completed_at IS NOT NULL))',
    'CHECK((due_kind = \'none\' AND due_date IS NULL AND due_instant IS NULL AND due_zone IS NULL AND due_wall_time IS NULL)OR(due_kind = \'date\' AND due_date IS NOT NULL AND length(due_date) = 10 AND due_instant IS NULL AND due_zone IS NULL AND due_wall_time IS NULL)OR(due_kind = \'timed\' AND due_date IS NULL AND due_instant IS NOT NULL AND due_zone IS NOT NULL AND due_wall_time IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String description;
  final String status;
  final int priority;
  final String dueKind;
  final String? dueDate;
  final int? dueInstant;
  final String? dueZone;
  final String? dueWallTime;
  final int? estimateMinutes;
  final String? occurrenceId;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;
  final int? deletedAt;
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueKind,
    this.dueDate,
    this.dueInstant,
    this.dueZone,
    this.dueWallTime,
    this.estimateMinutes,
    this.occurrenceId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    map['due_kind'] = Variable<String>(dueKind);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || dueInstant != null) {
      map['due_instant'] = Variable<int>(dueInstant);
    }
    if (!nullToAbsent || dueZone != null) {
      map['due_zone'] = Variable<String>(dueZone);
    }
    if (!nullToAbsent || dueWallTime != null) {
      map['due_wall_time'] = Variable<String>(dueWallTime);
    }
    if (!nullToAbsent || estimateMinutes != null) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes);
    }
    if (!nullToAbsent || occurrenceId != null) {
      map['occurrence_id'] = Variable<String>(occurrenceId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      status: Value(status),
      priority: Value(priority),
      dueKind: Value(dueKind),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueInstant: dueInstant == null && nullToAbsent
          ? const Value.absent()
          : Value(dueInstant),
      dueZone: dueZone == null && nullToAbsent
          ? const Value.absent()
          : Value(dueZone),
      dueWallTime: dueWallTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueWallTime),
      estimateMinutes: estimateMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateMinutes),
      occurrenceId: occurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      dueKind: serializer.fromJson<String>(json['due_kind']),
      dueDate: serializer.fromJson<String?>(json['due_date']),
      dueInstant: serializer.fromJson<int?>(json['due_instant']),
      dueZone: serializer.fromJson<String?>(json['due_zone']),
      dueWallTime: serializer.fromJson<String?>(json['due_wall_time']),
      estimateMinutes: serializer.fromJson<int?>(json['estimate_minutes']),
      occurrenceId: serializer.fromJson<String?>(json['occurrence_id']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      completedAt: serializer.fromJson<int?>(json['completed_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
      'due_kind': serializer.toJson<String>(dueKind),
      'due_date': serializer.toJson<String?>(dueDate),
      'due_instant': serializer.toJson<int?>(dueInstant),
      'due_zone': serializer.toJson<String?>(dueZone),
      'due_wall_time': serializer.toJson<String?>(dueWallTime),
      'estimate_minutes': serializer.toJson<int?>(estimateMinutes),
      'occurrence_id': serializer.toJson<String?>(occurrenceId),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'completed_at': serializer.toJson<int?>(completedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    int? priority,
    String? dueKind,
    Value<String?> dueDate = const Value.absent(),
    Value<int?> dueInstant = const Value.absent(),
    Value<String?> dueZone = const Value.absent(),
    Value<String?> dueWallTime = const Value.absent(),
    Value<int?> estimateMinutes = const Value.absent(),
    Value<String?> occurrenceId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> completedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueKind: dueKind ?? this.dueKind,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueInstant: dueInstant.present ? dueInstant.value : this.dueInstant,
    dueZone: dueZone.present ? dueZone.value : this.dueZone,
    dueWallTime: dueWallTime.present ? dueWallTime.value : this.dueWallTime,
    estimateMinutes: estimateMinutes.present
        ? estimateMinutes.value
        : this.estimateMinutes,
    occurrenceId: occurrenceId.present ? occurrenceId.value : this.occurrenceId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueKind: data.dueKind.present ? data.dueKind.value : this.dueKind,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueInstant: data.dueInstant.present
          ? data.dueInstant.value
          : this.dueInstant,
      dueZone: data.dueZone.present ? data.dueZone.value : this.dueZone,
      dueWallTime: data.dueWallTime.present
          ? data.dueWallTime.value
          : this.dueWallTime,
      estimateMinutes: data.estimateMinutes.present
          ? data.estimateMinutes.value
          : this.estimateMinutes,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueKind: $dueKind, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueInstant: $dueInstant, ')
          ..write('dueZone: $dueZone, ')
          ..write('dueWallTime: $dueWallTime, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    status,
    priority,
    dueKind,
    dueDate,
    dueInstant,
    dueZone,
    dueWallTime,
    estimateMinutes,
    occurrenceId,
    createdAt,
    updatedAt,
    completedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.dueKind == this.dueKind &&
          other.dueDate == this.dueDate &&
          other.dueInstant == this.dueInstant &&
          other.dueZone == this.dueZone &&
          other.dueWallTime == this.dueWallTime &&
          other.estimateMinutes == this.estimateMinutes &&
          other.occurrenceId == this.occurrenceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> status;
  final Value<int> priority;
  final Value<String> dueKind;
  final Value<String?> dueDate;
  final Value<int?> dueInstant;
  final Value<String?> dueZone;
  final Value<String?> dueWallTime;
  final Value<int?> estimateMinutes;
  final Value<String?> occurrenceId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> completedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueKind = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueInstant = const Value.absent(),
    this.dueZone = const Value.absent(),
    this.dueWallTime = const Value.absent(),
    this.estimateMinutes = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueKind = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueInstant = const Value.absent(),
    this.dueZone = const Value.absent(),
    this.dueWallTime = const Value.absent(),
    this.estimateMinutes = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<String>? dueKind,
    Expression<String>? dueDate,
    Expression<int>? dueInstant,
    Expression<String>? dueZone,
    Expression<String>? dueWallTime,
    Expression<int>? estimateMinutes,
    Expression<String>? occurrenceId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (dueKind != null) 'due_kind': dueKind,
      if (dueDate != null) 'due_date': dueDate,
      if (dueInstant != null) 'due_instant': dueInstant,
      if (dueZone != null) 'due_zone': dueZone,
      if (dueWallTime != null) 'due_wall_time': dueWallTime,
      if (estimateMinutes != null) 'estimate_minutes': estimateMinutes,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<String>? status,
    Value<int>? priority,
    Value<String>? dueKind,
    Value<String?>? dueDate,
    Value<int?>? dueInstant,
    Value<String?>? dueZone,
    Value<String?>? dueWallTime,
    Value<int?>? estimateMinutes,
    Value<String?>? occurrenceId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? completedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueKind: dueKind ?? this.dueKind,
      dueDate: dueDate ?? this.dueDate,
      dueInstant: dueInstant ?? this.dueInstant,
      dueZone: dueZone ?? this.dueZone,
      dueWallTime: dueWallTime ?? this.dueWallTime,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (dueKind.present) {
      map['due_kind'] = Variable<String>(dueKind.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (dueInstant.present) {
      map['due_instant'] = Variable<int>(dueInstant.value);
    }
    if (dueZone.present) {
      map['due_zone'] = Variable<String>(dueZone.value);
    }
    if (dueWallTime.present) {
      map['due_wall_time'] = Variable<String>(dueWallTime.value);
    }
    if (estimateMinutes.present) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueKind: $dueKind, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueInstant: $dueInstant, ')
          ..write('dueZone: $dueZone, ')
          ..write('dueWallTime: $dueWallTime, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tags extends Table with TableInfo<Tags, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tags(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, normalizedName, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Tags createAlias(String alias) {
    return Tags(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final String normalizedName;
  final int? deletedAt;
  const Tag({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalized_name']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalized_name': serializer.toJson<String>(normalizedName),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? normalizedName,
    Value<int?> deletedAt = const Value.absent(),
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, normalizedName, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.deletedAt == this.deletedAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TaskTags extends Table with TableInfo<TaskTags, TaskTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TaskTags(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES tasks(id)',
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES tags(id)',
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  late final GeneratedColumn<int> removed = GeneratedColumn<int>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (removed IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, tagId, removed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, tagId};
  @override
  TaskTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTag(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed'],
      )!,
    );
  }

  @override
  TaskTags createAlias(String alias) {
    return TaskTags(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(task_id, tag_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class TaskTag extends DataClass implements Insertable<TaskTag> {
  final String taskId;
  final String tagId;
  final int removed;
  const TaskTag({
    required this.taskId,
    required this.tagId,
    required this.removed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['tag_id'] = Variable<String>(tagId);
    map['removed'] = Variable<int>(removed);
    return map;
  }

  TaskTagsCompanion toCompanion(bool nullToAbsent) {
    return TaskTagsCompanion(
      taskId: Value(taskId),
      tagId: Value(tagId),
      removed: Value(removed),
    );
  }

  factory TaskTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTag(
      taskId: serializer.fromJson<String>(json['task_id']),
      tagId: serializer.fromJson<String>(json['tag_id']),
      removed: serializer.fromJson<int>(json['removed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'task_id': serializer.toJson<String>(taskId),
      'tag_id': serializer.toJson<String>(tagId),
      'removed': serializer.toJson<int>(removed),
    };
  }

  TaskTag copyWith({String? taskId, String? tagId, int? removed}) => TaskTag(
    taskId: taskId ?? this.taskId,
    tagId: tagId ?? this.tagId,
    removed: removed ?? this.removed,
  );
  TaskTag copyWithCompanion(TaskTagsCompanion data) {
    return TaskTag(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      removed: data.removed.present ? data.removed.value : this.removed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTag(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, tagId, removed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTag &&
          other.taskId == this.taskId &&
          other.tagId == this.tagId &&
          other.removed == this.removed);
}

class TaskTagsCompanion extends UpdateCompanion<TaskTag> {
  final Value<String> taskId;
  final Value<String> tagId;
  final Value<int> removed;
  final Value<int> rowid;
  const TaskTagsCompanion({
    this.taskId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.removed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTagsCompanion.insert({
    required String taskId,
    required String tagId,
    this.removed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       tagId = Value(tagId);
  static Insertable<TaskTag> custom({
    Expression<String>? taskId,
    Expression<String>? tagId,
    Expression<int>? removed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (tagId != null) 'tag_id': tagId,
      if (removed != null) 'removed': removed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTagsCompanion copyWith({
    Value<String>? taskId,
    Value<String>? tagId,
    Value<int>? removed,
    Value<int>? rowid,
  }) {
    return TaskTagsCompanion(
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
      removed: removed ?? this.removed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (removed.present) {
      map['removed'] = Variable<int>(removed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('removed: $removed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Milestones extends Table with TableInfo<Milestones, Milestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Milestones(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES tasks(id)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 500)',
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (position >= 0)',
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    title,
    position,
    completedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Milestone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Milestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Milestone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Milestones createAlias(String alias) {
    return Milestones(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Milestone extends DataClass implements Insertable<Milestone> {
  final String id;
  final String taskId;
  final String title;
  final int position;
  final int? completedAt;
  final int? deletedAt;
  const Milestone({
    required this.id,
    required this.taskId,
    required this.title,
    required this.position,
    this.completedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['title'] = Variable<String>(title);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  MilestonesCompanion toCompanion(bool nullToAbsent) {
    return MilestonesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      title: Value(title),
      position: Value(position),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Milestone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Milestone(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['task_id']),
      title: serializer.fromJson<String>(json['title']),
      position: serializer.fromJson<int>(json['position']),
      completedAt: serializer.fromJson<int?>(json['completed_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'task_id': serializer.toJson<String>(taskId),
      'title': serializer.toJson<String>(title),
      'position': serializer.toJson<int>(position),
      'completed_at': serializer.toJson<int?>(completedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  Milestone copyWith({
    String? id,
    String? taskId,
    String? title,
    int? position,
    Value<int?> completedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => Milestone(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    position: position ?? this.position,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Milestone copyWithCompanion(MilestonesCompanion data) {
    return Milestone(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      position: data.position.present ? data.position.value : this.position,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Milestone(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, title, position, completedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Milestone &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.position == this.position &&
          other.completedAt == this.completedAt &&
          other.deletedAt == this.deletedAt);
}

class MilestonesCompanion extends UpdateCompanion<Milestone> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> title;
  final Value<int> position;
  final Value<int?> completedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const MilestonesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.position = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilestonesCompanion.insert({
    required String id,
    required String taskId,
    required String title,
    required int position,
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       title = Value(title),
       position = Value(position);
  static Insertable<Milestone> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<int>? position,
    Expression<int>? completedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (position != null) 'position': position,
      if (completedAt != null) 'completed_at': completedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilestonesCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? title,
    Value<int>? position,
    Value<int?>? completedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MilestonesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      position: position ?? this.position,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilestonesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RecurrenceSeries extends Table
    with TableInfo<RecurrenceSeries, RecurrenceSery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecurrenceSeries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _templateJsonMeta = const VerificationMeta(
    'templateJson',
  );
  late final GeneratedColumn<String> templateJson = GeneratedColumn<String>(
    'template_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, templateJson, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrence_series';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurrenceSery> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_json')) {
      context.handle(
        _templateJsonMeta,
        templateJson.isAcceptableOrUnknown(
          data['template_json']!,
          _templateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateJsonMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurrenceSery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceSery(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_json'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  RecurrenceSeries createAlias(String alias) {
    return RecurrenceSeries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class RecurrenceSery extends DataClass implements Insertable<RecurrenceSery> {
  final String id;
  final String templateJson;
  final int? deletedAt;
  const RecurrenceSery({
    required this.id,
    required this.templateJson,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_json'] = Variable<String>(templateJson);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  RecurrenceSeriesCompanion toCompanion(bool nullToAbsent) {
    return RecurrenceSeriesCompanion(
      id: Value(id),
      templateJson: Value(templateJson),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RecurrenceSery.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceSery(
      id: serializer.fromJson<String>(json['id']),
      templateJson: serializer.fromJson<String>(json['template_json']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'template_json': serializer.toJson<String>(templateJson),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  RecurrenceSery copyWith({
    String? id,
    String? templateJson,
    Value<int?> deletedAt = const Value.absent(),
  }) => RecurrenceSery(
    id: id ?? this.id,
    templateJson: templateJson ?? this.templateJson,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  RecurrenceSery copyWithCompanion(RecurrenceSeriesCompanion data) {
    return RecurrenceSery(
      id: data.id.present ? data.id.value : this.id,
      templateJson: data.templateJson.present
          ? data.templateJson.value
          : this.templateJson,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSery(')
          ..write('id: $id, ')
          ..write('templateJson: $templateJson, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateJson, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceSery &&
          other.id == this.id &&
          other.templateJson == this.templateJson &&
          other.deletedAt == this.deletedAt);
}

class RecurrenceSeriesCompanion extends UpdateCompanion<RecurrenceSery> {
  final Value<String> id;
  final Value<String> templateJson;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const RecurrenceSeriesCompanion({
    this.id = const Value.absent(),
    this.templateJson = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrenceSeriesCompanion.insert({
    required String id,
    required String templateJson,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateJson = Value(templateJson);
  static Insertable<RecurrenceSery> custom({
    Expression<String>? id,
    Expression<String>? templateJson,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateJson != null) 'template_json': templateJson,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrenceSeriesCompanion copyWith({
    Value<String>? id,
    Value<String>? templateJson,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return RecurrenceSeriesCompanion(
      id: id ?? this.id,
      templateJson: templateJson ?? this.templateJson,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateJson.present) {
      map['template_json'] = Variable<String>(templateJson.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSeriesCompanion(')
          ..write('id: $id, ')
          ..write('templateJson: $templateJson, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RecurrenceSegments extends Table
    with TableInfo<RecurrenceSegments, RecurrenceSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecurrenceSegments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES recurrence_series(id)',
  );
  static const VerificationMeta _ruleJsonMeta = const VerificationMeta(
    'ruleJson',
  );
  late final GeneratedColumn<String> ruleJson = GeneratedColumn<String>(
    'rule_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _engineVersionMeta = const VerificationMeta(
    'engineVersion',
  );
  late final GeneratedColumn<int> engineVersion = GeneratedColumn<int>(
    'engine_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (engine_version > 0)',
  );
  static const VerificationMeta _tzdataVersionMeta = const VerificationMeta(
    'tzdataVersion',
  );
  late final GeneratedColumn<String> tzdataVersion = GeneratedColumn<String>(
    'tzdata_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _cutoffOrdinalMeta = const VerificationMeta(
    'cutoffOrdinal',
  );
  late final GeneratedColumn<int> cutoffOrdinal = GeneratedColumn<int>(
    'cutoff_ordinal',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (cutoff_ordinal >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    ruleJson,
    engineVersion,
    tzdataVersion,
    cutoffOrdinal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrence_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurrenceSegment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('rule_json')) {
      context.handle(
        _ruleJsonMeta,
        ruleJson.isAcceptableOrUnknown(data['rule_json']!, _ruleJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleJsonMeta);
    }
    if (data.containsKey('engine_version')) {
      context.handle(
        _engineVersionMeta,
        engineVersion.isAcceptableOrUnknown(
          data['engine_version']!,
          _engineVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_engineVersionMeta);
    }
    if (data.containsKey('tzdata_version')) {
      context.handle(
        _tzdataVersionMeta,
        tzdataVersion.isAcceptableOrUnknown(
          data['tzdata_version']!,
          _tzdataVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzdataVersionMeta);
    }
    if (data.containsKey('cutoff_ordinal')) {
      context.handle(
        _cutoffOrdinalMeta,
        cutoffOrdinal.isAcceptableOrUnknown(
          data['cutoff_ordinal']!,
          _cutoffOrdinalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurrenceSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceSegment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      ruleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_json'],
      )!,
      engineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}engine_version'],
      )!,
      tzdataVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tzdata_version'],
      )!,
      cutoffOrdinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cutoff_ordinal'],
      ),
    );
  }

  @override
  RecurrenceSegments createAlias(String alias) {
    return RecurrenceSegments(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class RecurrenceSegment extends DataClass
    implements Insertable<RecurrenceSegment> {
  final String id;
  final String seriesId;
  final String ruleJson;
  final int engineVersion;
  final String tzdataVersion;
  final int? cutoffOrdinal;
  const RecurrenceSegment({
    required this.id,
    required this.seriesId,
    required this.ruleJson,
    required this.engineVersion,
    required this.tzdataVersion,
    this.cutoffOrdinal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['rule_json'] = Variable<String>(ruleJson);
    map['engine_version'] = Variable<int>(engineVersion);
    map['tzdata_version'] = Variable<String>(tzdataVersion);
    if (!nullToAbsent || cutoffOrdinal != null) {
      map['cutoff_ordinal'] = Variable<int>(cutoffOrdinal);
    }
    return map;
  }

  RecurrenceSegmentsCompanion toCompanion(bool nullToAbsent) {
    return RecurrenceSegmentsCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      ruleJson: Value(ruleJson),
      engineVersion: Value(engineVersion),
      tzdataVersion: Value(tzdataVersion),
      cutoffOrdinal: cutoffOrdinal == null && nullToAbsent
          ? const Value.absent()
          : Value(cutoffOrdinal),
    );
  }

  factory RecurrenceSegment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceSegment(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['series_id']),
      ruleJson: serializer.fromJson<String>(json['rule_json']),
      engineVersion: serializer.fromJson<int>(json['engine_version']),
      tzdataVersion: serializer.fromJson<String>(json['tzdata_version']),
      cutoffOrdinal: serializer.fromJson<int?>(json['cutoff_ordinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'series_id': serializer.toJson<String>(seriesId),
      'rule_json': serializer.toJson<String>(ruleJson),
      'engine_version': serializer.toJson<int>(engineVersion),
      'tzdata_version': serializer.toJson<String>(tzdataVersion),
      'cutoff_ordinal': serializer.toJson<int?>(cutoffOrdinal),
    };
  }

  RecurrenceSegment copyWith({
    String? id,
    String? seriesId,
    String? ruleJson,
    int? engineVersion,
    String? tzdataVersion,
    Value<int?> cutoffOrdinal = const Value.absent(),
  }) => RecurrenceSegment(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    ruleJson: ruleJson ?? this.ruleJson,
    engineVersion: engineVersion ?? this.engineVersion,
    tzdataVersion: tzdataVersion ?? this.tzdataVersion,
    cutoffOrdinal: cutoffOrdinal.present
        ? cutoffOrdinal.value
        : this.cutoffOrdinal,
  );
  RecurrenceSegment copyWithCompanion(RecurrenceSegmentsCompanion data) {
    return RecurrenceSegment(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      ruleJson: data.ruleJson.present ? data.ruleJson.value : this.ruleJson,
      engineVersion: data.engineVersion.present
          ? data.engineVersion.value
          : this.engineVersion,
      tzdataVersion: data.tzdataVersion.present
          ? data.tzdataVersion.value
          : this.tzdataVersion,
      cutoffOrdinal: data.cutoffOrdinal.present
          ? data.cutoffOrdinal.value
          : this.cutoffOrdinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSegment(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('tzdataVersion: $tzdataVersion, ')
          ..write('cutoffOrdinal: $cutoffOrdinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    ruleJson,
    engineVersion,
    tzdataVersion,
    cutoffOrdinal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceSegment &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.ruleJson == this.ruleJson &&
          other.engineVersion == this.engineVersion &&
          other.tzdataVersion == this.tzdataVersion &&
          other.cutoffOrdinal == this.cutoffOrdinal);
}

class RecurrenceSegmentsCompanion extends UpdateCompanion<RecurrenceSegment> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<String> ruleJson;
  final Value<int> engineVersion;
  final Value<String> tzdataVersion;
  final Value<int?> cutoffOrdinal;
  final Value<int> rowid;
  const RecurrenceSegmentsCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.ruleJson = const Value.absent(),
    this.engineVersion = const Value.absent(),
    this.tzdataVersion = const Value.absent(),
    this.cutoffOrdinal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrenceSegmentsCompanion.insert({
    required String id,
    required String seriesId,
    required String ruleJson,
    required int engineVersion,
    required String tzdataVersion,
    this.cutoffOrdinal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seriesId = Value(seriesId),
       ruleJson = Value(ruleJson),
       engineVersion = Value(engineVersion),
       tzdataVersion = Value(tzdataVersion);
  static Insertable<RecurrenceSegment> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<String>? ruleJson,
    Expression<int>? engineVersion,
    Expression<String>? tzdataVersion,
    Expression<int>? cutoffOrdinal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (ruleJson != null) 'rule_json': ruleJson,
      if (engineVersion != null) 'engine_version': engineVersion,
      if (tzdataVersion != null) 'tzdata_version': tzdataVersion,
      if (cutoffOrdinal != null) 'cutoff_ordinal': cutoffOrdinal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrenceSegmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? seriesId,
    Value<String>? ruleJson,
    Value<int>? engineVersion,
    Value<String>? tzdataVersion,
    Value<int?>? cutoffOrdinal,
    Value<int>? rowid,
  }) {
    return RecurrenceSegmentsCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      ruleJson: ruleJson ?? this.ruleJson,
      engineVersion: engineVersion ?? this.engineVersion,
      tzdataVersion: tzdataVersion ?? this.tzdataVersion,
      cutoffOrdinal: cutoffOrdinal ?? this.cutoffOrdinal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (ruleJson.present) {
      map['rule_json'] = Variable<String>(ruleJson.value);
    }
    if (engineVersion.present) {
      map['engine_version'] = Variable<int>(engineVersion.value);
    }
    if (tzdataVersion.present) {
      map['tzdata_version'] = Variable<String>(tzdataVersion.value);
    }
    if (cutoffOrdinal.present) {
      map['cutoff_ordinal'] = Variable<int>(cutoffOrdinal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('tzdataVersion: $tzdataVersion, ')
          ..write('cutoffOrdinal: $cutoffOrdinal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class OccurrenceState extends Table
    with TableInfo<OccurrenceState, OccurrenceStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  OccurrenceState(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES recurrence_segments(id)',
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (ordinal >= 0)',
  );
  static const VerificationMeta _originalSlotMeta = const VerificationMeta(
    'originalSlot',
  );
  late final GeneratedColumn<String> originalSlot = GeneratedColumn<String>(
    'original_slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _overridesJsonMeta = const VerificationMeta(
    'overridesJson',
  );
  late final GeneratedColumn<String> overridesJson = GeneratedColumn<String>(
    'overrides_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _skipReasonMeta = const VerificationMeta(
    'skipReason',
  );
  late final GeneratedColumn<String> skipReason = GeneratedColumn<String>(
    'skip_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    segmentId,
    ordinal,
    originalSlot,
    overridesJson,
    skipReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrence_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<OccurrenceStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('original_slot')) {
      context.handle(
        _originalSlotMeta,
        originalSlot.isAcceptableOrUnknown(
          data['original_slot']!,
          _originalSlotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalSlotMeta);
    }
    if (data.containsKey('overrides_json')) {
      context.handle(
        _overridesJsonMeta,
        overridesJson.isAcceptableOrUnknown(
          data['overrides_json']!,
          _overridesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overridesJsonMeta);
    }
    if (data.containsKey('skip_reason')) {
      context.handle(
        _skipReasonMeta,
        skipReason.isAcceptableOrUnknown(data['skip_reason']!, _skipReasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {segmentId, ordinal},
  ];
  @override
  OccurrenceStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      originalSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_slot'],
      )!,
      overridesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overrides_json'],
      )!,
      skipReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skip_reason'],
      ),
    );
  }

  @override
  OccurrenceState createAlias(String alias) {
    return OccurrenceState(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(segment_id, ordinal)'];
  @override
  bool get dontWriteConstraints => true;
}

class OccurrenceStateData extends DataClass
    implements Insertable<OccurrenceStateData> {
  final String id;
  final String segmentId;
  final int ordinal;
  final String originalSlot;
  final String overridesJson;
  final String? skipReason;
  const OccurrenceStateData({
    required this.id,
    required this.segmentId,
    required this.ordinal,
    required this.originalSlot,
    required this.overridesJson,
    this.skipReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['segment_id'] = Variable<String>(segmentId);
    map['ordinal'] = Variable<int>(ordinal);
    map['original_slot'] = Variable<String>(originalSlot);
    map['overrides_json'] = Variable<String>(overridesJson);
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(skipReason);
    }
    return map;
  }

  OccurrenceStateCompanion toCompanion(bool nullToAbsent) {
    return OccurrenceStateCompanion(
      id: Value(id),
      segmentId: Value(segmentId),
      ordinal: Value(ordinal),
      originalSlot: Value(originalSlot),
      overridesJson: Value(overridesJson),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
    );
  }

  factory OccurrenceStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceStateData(
      id: serializer.fromJson<String>(json['id']),
      segmentId: serializer.fromJson<String>(json['segment_id']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      originalSlot: serializer.fromJson<String>(json['original_slot']),
      overridesJson: serializer.fromJson<String>(json['overrides_json']),
      skipReason: serializer.fromJson<String?>(json['skip_reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'segment_id': serializer.toJson<String>(segmentId),
      'ordinal': serializer.toJson<int>(ordinal),
      'original_slot': serializer.toJson<String>(originalSlot),
      'overrides_json': serializer.toJson<String>(overridesJson),
      'skip_reason': serializer.toJson<String?>(skipReason),
    };
  }

  OccurrenceStateData copyWith({
    String? id,
    String? segmentId,
    int? ordinal,
    String? originalSlot,
    String? overridesJson,
    Value<String?> skipReason = const Value.absent(),
  }) => OccurrenceStateData(
    id: id ?? this.id,
    segmentId: segmentId ?? this.segmentId,
    ordinal: ordinal ?? this.ordinal,
    originalSlot: originalSlot ?? this.originalSlot,
    overridesJson: overridesJson ?? this.overridesJson,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
  );
  OccurrenceStateData copyWithCompanion(OccurrenceStateCompanion data) {
    return OccurrenceStateData(
      id: data.id.present ? data.id.value : this.id,
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      originalSlot: data.originalSlot.present
          ? data.originalSlot.value
          : this.originalSlot,
      overridesJson: data.overridesJson.present
          ? data.overridesJson.value
          : this.overridesJson,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceStateData(')
          ..write('id: $id, ')
          ..write('segmentId: $segmentId, ')
          ..write('ordinal: $ordinal, ')
          ..write('originalSlot: $originalSlot, ')
          ..write('overridesJson: $overridesJson, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    segmentId,
    ordinal,
    originalSlot,
    overridesJson,
    skipReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceStateData &&
          other.id == this.id &&
          other.segmentId == this.segmentId &&
          other.ordinal == this.ordinal &&
          other.originalSlot == this.originalSlot &&
          other.overridesJson == this.overridesJson &&
          other.skipReason == this.skipReason);
}

class OccurrenceStateCompanion extends UpdateCompanion<OccurrenceStateData> {
  final Value<String> id;
  final Value<String> segmentId;
  final Value<int> ordinal;
  final Value<String> originalSlot;
  final Value<String> overridesJson;
  final Value<String?> skipReason;
  final Value<int> rowid;
  const OccurrenceStateCompanion({
    this.id = const Value.absent(),
    this.segmentId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.originalSlot = const Value.absent(),
    this.overridesJson = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrenceStateCompanion.insert({
    required String id,
    required String segmentId,
    required int ordinal,
    required String originalSlot,
    required String overridesJson,
    this.skipReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       segmentId = Value(segmentId),
       ordinal = Value(ordinal),
       originalSlot = Value(originalSlot),
       overridesJson = Value(overridesJson);
  static Insertable<OccurrenceStateData> custom({
    Expression<String>? id,
    Expression<String>? segmentId,
    Expression<int>? ordinal,
    Expression<String>? originalSlot,
    Expression<String>? overridesJson,
    Expression<String>? skipReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (segmentId != null) 'segment_id': segmentId,
      if (ordinal != null) 'ordinal': ordinal,
      if (originalSlot != null) 'original_slot': originalSlot,
      if (overridesJson != null) 'overrides_json': overridesJson,
      if (skipReason != null) 'skip_reason': skipReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrenceStateCompanion copyWith({
    Value<String>? id,
    Value<String>? segmentId,
    Value<int>? ordinal,
    Value<String>? originalSlot,
    Value<String>? overridesJson,
    Value<String?>? skipReason,
    Value<int>? rowid,
  }) {
    return OccurrenceStateCompanion(
      id: id ?? this.id,
      segmentId: segmentId ?? this.segmentId,
      ordinal: ordinal ?? this.ordinal,
      originalSlot: originalSlot ?? this.originalSlot,
      overridesJson: overridesJson ?? this.overridesJson,
      skipReason: skipReason ?? this.skipReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (originalSlot.present) {
      map['original_slot'] = Variable<String>(originalSlot.value);
    }
    if (overridesJson.present) {
      map['overrides_json'] = Variable<String>(overridesJson.value);
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(skipReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceStateCompanion(')
          ..write('id: $id, ')
          ..write('segmentId: $segmentId, ')
          ..write('ordinal: $ordinal, ')
          ..write('originalSlot: $originalSlot, ')
          ..write('overridesJson: $overridesJson, ')
          ..write('skipReason: $skipReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ReminderRules extends Table with TableInfo<ReminderRules, ReminderRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ReminderRules(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES tasks(id)',
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES recurrence_series(id)',
  );
  static const VerificationMeta _ruleJsonMeta = const VerificationMeta(
    'ruleJson',
  );
  late final GeneratedColumn<String> ruleJson = GeneratedColumn<String>(
    'rule_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    seriesId,
    ruleJson,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('rule_json')) {
      context.handle(
        _ruleJsonMeta,
        ruleJson.isAcceptableOrUnknown(data['rule_json']!, _ruleJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleJsonMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      ruleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_json'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  ReminderRules createAlias(String alias) {
    return ReminderRules(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((task_id IS NULL)!=(series_id IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ReminderRule extends DataClass implements Insertable<ReminderRule> {
  final String id;
  final String? taskId;
  final String? seriesId;
  final String ruleJson;
  final int? deletedAt;
  const ReminderRule({
    required this.id,
    this.taskId,
    this.seriesId,
    required this.ruleJson,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    map['rule_json'] = Variable<String>(ruleJson);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ReminderRulesCompanion toCompanion(bool nullToAbsent) {
    return ReminderRulesCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      ruleJson: Value(ruleJson),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ReminderRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRule(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String?>(json['task_id']),
      seriesId: serializer.fromJson<String?>(json['series_id']),
      ruleJson: serializer.fromJson<String>(json['rule_json']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'task_id': serializer.toJson<String?>(taskId),
      'series_id': serializer.toJson<String?>(seriesId),
      'rule_json': serializer.toJson<String>(ruleJson),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  ReminderRule copyWith({
    String? id,
    Value<String?> taskId = const Value.absent(),
    Value<String?> seriesId = const Value.absent(),
    String? ruleJson,
    Value<int?> deletedAt = const Value.absent(),
  }) => ReminderRule(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    ruleJson: ruleJson ?? this.ruleJson,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ReminderRule copyWithCompanion(ReminderRulesCompanion data) {
    return ReminderRule(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      ruleJson: data.ruleJson.present ? data.ruleJson.value : this.ruleJson,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRule(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('seriesId: $seriesId, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, seriesId, ruleJson, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRule &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.seriesId == this.seriesId &&
          other.ruleJson == this.ruleJson &&
          other.deletedAt == this.deletedAt);
}

class ReminderRulesCompanion extends UpdateCompanion<ReminderRule> {
  final Value<String> id;
  final Value<String?> taskId;
  final Value<String?> seriesId;
  final Value<String> ruleJson;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ReminderRulesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.ruleJson = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderRulesCompanion.insert({
    required String id,
    this.taskId = const Value.absent(),
    this.seriesId = const Value.absent(),
    required String ruleJson,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ruleJson = Value(ruleJson);
  static Insertable<ReminderRule> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? seriesId,
    Expression<String>? ruleJson,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (seriesId != null) 'series_id': seriesId,
      if (ruleJson != null) 'rule_json': ruleJson,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderRulesCompanion copyWith({
    Value<String>? id,
    Value<String?>? taskId,
    Value<String?>? seriesId,
    Value<String>? ruleJson,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ReminderRulesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      seriesId: seriesId ?? this.seriesId,
      ruleJson: ruleJson ?? this.ruleJson,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (ruleJson.present) {
      map['rule_json'] = Variable<String>(ruleJson.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRulesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('seriesId: $seriesId, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Snoozes extends Table with TableInfo<Snoozes, Snooze> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Snoozes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES tasks(id)',
  );
  static const VerificationMeta _untilInstantMeta = const VerificationMeta(
    'untilInstant',
  );
  late final GeneratedColumn<int> untilInstant = GeneratedColumn<int>(
    'until_instant',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (generation > 0)',
  );
  static const VerificationMeta _suppressedThroughMeta = const VerificationMeta(
    'suppressedThrough',
  );
  late final GeneratedColumn<int> suppressedThrough = GeneratedColumn<int>(
    'suppressed_through',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    untilInstant,
    generation,
    suppressedThrough,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snoozes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Snooze> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('until_instant')) {
      context.handle(
        _untilInstantMeta,
        untilInstant.isAcceptableOrUnknown(
          data['until_instant']!,
          _untilInstantMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_untilInstantMeta);
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    } else if (isInserting) {
      context.missing(_generationMeta);
    }
    if (data.containsKey('suppressed_through')) {
      context.handle(
        _suppressedThroughMeta,
        suppressedThrough.isAcceptableOrUnknown(
          data['suppressed_through']!,
          _suppressedThroughMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_suppressedThroughMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};
  @override
  Snooze map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Snooze(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      untilInstant: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}until_instant'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
      suppressedThrough: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}suppressed_through'],
      )!,
    );
  }

  @override
  Snoozes createAlias(String alias) {
    return Snoozes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Snooze extends DataClass implements Insertable<Snooze> {
  final String taskId;
  final int untilInstant;
  final int generation;
  final int suppressedThrough;
  const Snooze({
    required this.taskId,
    required this.untilInstant,
    required this.generation,
    required this.suppressedThrough,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['until_instant'] = Variable<int>(untilInstant);
    map['generation'] = Variable<int>(generation);
    map['suppressed_through'] = Variable<int>(suppressedThrough);
    return map;
  }

  SnoozesCompanion toCompanion(bool nullToAbsent) {
    return SnoozesCompanion(
      taskId: Value(taskId),
      untilInstant: Value(untilInstant),
      generation: Value(generation),
      suppressedThrough: Value(suppressedThrough),
    );
  }

  factory Snooze.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Snooze(
      taskId: serializer.fromJson<String>(json['task_id']),
      untilInstant: serializer.fromJson<int>(json['until_instant']),
      generation: serializer.fromJson<int>(json['generation']),
      suppressedThrough: serializer.fromJson<int>(json['suppressed_through']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'task_id': serializer.toJson<String>(taskId),
      'until_instant': serializer.toJson<int>(untilInstant),
      'generation': serializer.toJson<int>(generation),
      'suppressed_through': serializer.toJson<int>(suppressedThrough),
    };
  }

  Snooze copyWith({
    String? taskId,
    int? untilInstant,
    int? generation,
    int? suppressedThrough,
  }) => Snooze(
    taskId: taskId ?? this.taskId,
    untilInstant: untilInstant ?? this.untilInstant,
    generation: generation ?? this.generation,
    suppressedThrough: suppressedThrough ?? this.suppressedThrough,
  );
  Snooze copyWithCompanion(SnoozesCompanion data) {
    return Snooze(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      untilInstant: data.untilInstant.present
          ? data.untilInstant.value
          : this.untilInstant,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      suppressedThrough: data.suppressedThrough.present
          ? data.suppressedThrough.value
          : this.suppressedThrough,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Snooze(')
          ..write('taskId: $taskId, ')
          ..write('untilInstant: $untilInstant, ')
          ..write('generation: $generation, ')
          ..write('suppressedThrough: $suppressedThrough')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(taskId, untilInstant, generation, suppressedThrough);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Snooze &&
          other.taskId == this.taskId &&
          other.untilInstant == this.untilInstant &&
          other.generation == this.generation &&
          other.suppressedThrough == this.suppressedThrough);
}

class SnoozesCompanion extends UpdateCompanion<Snooze> {
  final Value<String> taskId;
  final Value<int> untilInstant;
  final Value<int> generation;
  final Value<int> suppressedThrough;
  final Value<int> rowid;
  const SnoozesCompanion({
    this.taskId = const Value.absent(),
    this.untilInstant = const Value.absent(),
    this.generation = const Value.absent(),
    this.suppressedThrough = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnoozesCompanion.insert({
    required String taskId,
    required int untilInstant,
    required int generation,
    required int suppressedThrough,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       untilInstant = Value(untilInstant),
       generation = Value(generation),
       suppressedThrough = Value(suppressedThrough);
  static Insertable<Snooze> custom({
    Expression<String>? taskId,
    Expression<int>? untilInstant,
    Expression<int>? generation,
    Expression<int>? suppressedThrough,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (untilInstant != null) 'until_instant': untilInstant,
      if (generation != null) 'generation': generation,
      if (suppressedThrough != null) 'suppressed_through': suppressedThrough,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnoozesCompanion copyWith({
    Value<String>? taskId,
    Value<int>? untilInstant,
    Value<int>? generation,
    Value<int>? suppressedThrough,
    Value<int>? rowid,
  }) {
    return SnoozesCompanion(
      taskId: taskId ?? this.taskId,
      untilInstant: untilInstant ?? this.untilInstant,
      generation: generation ?? this.generation,
      suppressedThrough: suppressedThrough ?? this.suppressedThrough,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (untilInstant.present) {
      map['until_instant'] = Variable<int>(untilInstant.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (suppressedThrough.present) {
      map['suppressed_through'] = Variable<int>(suppressedThrough.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnoozesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('untilInstant: $untilInstant, ')
          ..write('generation: $generation, ')
          ..write('suppressedThrough: $suppressedThrough, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SavedViews extends Table with TableInfo<SavedViews, SavedView> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SavedViews(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _specVersionMeta = const VerificationMeta(
    'specVersion',
  );
  late final GeneratedColumn<int> specVersion = GeneratedColumn<int>(
    'spec_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (spec_version > 0)',
  );
  static const VerificationMeta _specJsonMeta = const VerificationMeta(
    'specJson',
  );
  late final GeneratedColumn<String> specJson = GeneratedColumn<String>(
    'spec_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    specVersion,
    specJson,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_views';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedView> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('spec_version')) {
      context.handle(
        _specVersionMeta,
        specVersion.isAcceptableOrUnknown(
          data['spec_version']!,
          _specVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_specVersionMeta);
    }
    if (data.containsKey('spec_json')) {
      context.handle(
        _specJsonMeta,
        specJson.isAcceptableOrUnknown(data['spec_json']!, _specJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_specJsonMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedView map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedView(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      specVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spec_version'],
      )!,
      specJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec_json'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  SavedViews createAlias(String alias) {
    return SavedViews(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SavedView extends DataClass implements Insertable<SavedView> {
  final String id;
  final String name;
  final int specVersion;
  final String specJson;
  final int? deletedAt;
  const SavedView({
    required this.id,
    required this.name,
    required this.specVersion,
    required this.specJson,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['spec_version'] = Variable<int>(specVersion);
    map['spec_json'] = Variable<String>(specJson);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  SavedViewsCompanion toCompanion(bool nullToAbsent) {
    return SavedViewsCompanion(
      id: Value(id),
      name: Value(name),
      specVersion: Value(specVersion),
      specJson: Value(specJson),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SavedView.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedView(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      specVersion: serializer.fromJson<int>(json['spec_version']),
      specJson: serializer.fromJson<String>(json['spec_json']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'spec_version': serializer.toJson<int>(specVersion),
      'spec_json': serializer.toJson<String>(specJson),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  SavedView copyWith({
    String? id,
    String? name,
    int? specVersion,
    String? specJson,
    Value<int?> deletedAt = const Value.absent(),
  }) => SavedView(
    id: id ?? this.id,
    name: name ?? this.name,
    specVersion: specVersion ?? this.specVersion,
    specJson: specJson ?? this.specJson,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SavedView copyWithCompanion(SavedViewsCompanion data) {
    return SavedView(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      specVersion: data.specVersion.present
          ? data.specVersion.value
          : this.specVersion,
      specJson: data.specJson.present ? data.specJson.value : this.specJson,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedView(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('specVersion: $specVersion, ')
          ..write('specJson: $specJson, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, specVersion, specJson, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedView &&
          other.id == this.id &&
          other.name == this.name &&
          other.specVersion == this.specVersion &&
          other.specJson == this.specJson &&
          other.deletedAt == this.deletedAt);
}

class SavedViewsCompanion extends UpdateCompanion<SavedView> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> specVersion;
  final Value<String> specJson;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SavedViewsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.specVersion = const Value.absent(),
    this.specJson = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedViewsCompanion.insert({
    required String id,
    required String name,
    required int specVersion,
    required String specJson,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       specVersion = Value(specVersion),
       specJson = Value(specJson);
  static Insertable<SavedView> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? specVersion,
    Expression<String>? specJson,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (specVersion != null) 'spec_version': specVersion,
      if (specJson != null) 'spec_json': specJson,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedViewsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? specVersion,
    Value<String>? specJson,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SavedViewsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      specVersion: specVersion ?? this.specVersion,
      specJson: specJson ?? this.specJson,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (specVersion.present) {
      map['spec_version'] = Variable<int>(specVersion.value);
    }
    if (specJson.present) {
      map['spec_json'] = Variable<String>(specJson.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedViewsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('specVersion: $specVersion, ')
          ..write('specJson: $specJson, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SharedPreferences extends Table
    with TableInfo<SharedPreferences, SharedPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SharedPreferences(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<SharedPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SharedPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SharedPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  SharedPreferences createAlias(String alias) {
    return SharedPreferences(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SharedPreference extends DataClass
    implements Insertable<SharedPreference> {
  final String key;
  final String valueJson;
  const SharedPreference({required this.key, required this.valueJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  SharedPreferencesCompanion toCompanion(bool nullToAbsent) {
    return SharedPreferencesCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
    );
  }

  factory SharedPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedPreference(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['value_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value_json': serializer.toJson<String>(valueJson),
    };
  }

  SharedPreference copyWith({String? key, String? valueJson}) =>
      SharedPreference(
        key: key ?? this.key,
        valueJson: valueJson ?? this.valueJson,
      );
  SharedPreference copyWithCompanion(SharedPreferencesCompanion data) {
    return SharedPreference(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SharedPreference(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharedPreference &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class SharedPreferencesCompanion extends UpdateCompanion<SharedPreference> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> rowid;
  const SharedPreferencesCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SharedPreferencesCompanion.insert({
    required String key,
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson);
  static Insertable<SharedPreference> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SharedPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return SharedPreferencesCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DevicePreferences extends Table
    with TableInfo<DevicePreferences, DevicePreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DevicePreferences(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<DevicePreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DevicePreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DevicePreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  DevicePreferences createAlias(String alias) {
    return DevicePreferences(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DevicePreference extends DataClass
    implements Insertable<DevicePreference> {
  final String key;
  final String valueJson;
  const DevicePreference({required this.key, required this.valueJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  DevicePreferencesCompanion toCompanion(bool nullToAbsent) {
    return DevicePreferencesCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
    );
  }

  factory DevicePreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DevicePreference(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['value_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value_json': serializer.toJson<String>(valueJson),
    };
  }

  DevicePreference copyWith({String? key, String? valueJson}) =>
      DevicePreference(
        key: key ?? this.key,
        valueJson: valueJson ?? this.valueJson,
      );
  DevicePreference copyWithCompanion(DevicePreferencesCompanion data) {
    return DevicePreference(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DevicePreference(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DevicePreference &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class DevicePreferencesCompanion extends UpdateCompanion<DevicePreference> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> rowid;
  const DevicePreferencesCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicePreferencesCompanion.insert({
    required String key,
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson);
  static Insertable<DevicePreference> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicePreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return DevicePreferencesCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicePreferencesCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncShadow extends Table with TableInfo<SyncShadow, SyncShadowData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncShadow(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _versionsJsonMeta = const VerificationMeta(
    'versionsJson',
  );
  late final GeneratedColumn<String> versionsJson = GeneratedColumn<String>(
    'versions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (revision >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityId,
    valueJson,
    versionsJson,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_shadow';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncShadowData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('versions_json')) {
      context.handle(
        _versionsJsonMeta,
        versionsJson.isAcceptableOrUnknown(
          data['versions_json']!,
          _versionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionsJsonMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId};
  @override
  SyncShadowData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncShadowData(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      versionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}versions_json'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  SyncShadow createAlias(String alias) {
    return SyncShadow(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncShadowData extends DataClass implements Insertable<SyncShadowData> {
  final String entityId;
  final String valueJson;
  final String versionsJson;
  final int revision;
  const SyncShadowData({
    required this.entityId,
    required this.valueJson,
    required this.versionsJson,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['value_json'] = Variable<String>(valueJson);
    map['versions_json'] = Variable<String>(versionsJson);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  SyncShadowCompanion toCompanion(bool nullToAbsent) {
    return SyncShadowCompanion(
      entityId: Value(entityId),
      valueJson: Value(valueJson),
      versionsJson: Value(versionsJson),
      revision: Value(revision),
    );
  }

  factory SyncShadowData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncShadowData(
      entityId: serializer.fromJson<String>(json['entity_id']),
      valueJson: serializer.fromJson<String>(json['value_json']),
      versionsJson: serializer.fromJson<String>(json['versions_json']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity_id': serializer.toJson<String>(entityId),
      'value_json': serializer.toJson<String>(valueJson),
      'versions_json': serializer.toJson<String>(versionsJson),
      'revision': serializer.toJson<int>(revision),
    };
  }

  SyncShadowData copyWith({
    String? entityId,
    String? valueJson,
    String? versionsJson,
    int? revision,
  }) => SyncShadowData(
    entityId: entityId ?? this.entityId,
    valueJson: valueJson ?? this.valueJson,
    versionsJson: versionsJson ?? this.versionsJson,
    revision: revision ?? this.revision,
  );
  SyncShadowData copyWithCompanion(SyncShadowCompanion data) {
    return SyncShadowData(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      versionsJson: data.versionsJson.present
          ? data.versionsJson.value
          : this.versionsJson,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncShadowData(')
          ..write('entityId: $entityId, ')
          ..write('valueJson: $valueJson, ')
          ..write('versionsJson: $versionsJson, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityId, valueJson, versionsJson, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncShadowData &&
          other.entityId == this.entityId &&
          other.valueJson == this.valueJson &&
          other.versionsJson == this.versionsJson &&
          other.revision == this.revision);
}

class SyncShadowCompanion extends UpdateCompanion<SyncShadowData> {
  final Value<String> entityId;
  final Value<String> valueJson;
  final Value<String> versionsJson;
  final Value<int> revision;
  final Value<int> rowid;
  const SyncShadowCompanion({
    this.entityId = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.versionsJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncShadowCompanion.insert({
    required String entityId,
    required String valueJson,
    required String versionsJson,
    required int revision,
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId),
       valueJson = Value(valueJson),
       versionsJson = Value(versionsJson),
       revision = Value(revision);
  static Insertable<SyncShadowData> custom({
    Expression<String>? entityId,
    Expression<String>? valueJson,
    Expression<String>? versionsJson,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (valueJson != null) 'value_json': valueJson,
      if (versionsJson != null) 'versions_json': versionsJson,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncShadowCompanion copyWith({
    Value<String>? entityId,
    Value<String>? valueJson,
    Value<String>? versionsJson,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return SyncShadowCompanion(
      entityId: entityId ?? this.entityId,
      valueJson: valueJson ?? this.valueJson,
      versionsJson: versionsJson ?? this.versionsJson,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (versionsJson.present) {
      map['versions_json'] = Variable<String>(versionsJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncShadowCompanion(')
          ..write('entityId: $entityId, ')
          ..write('valueJson: $valueJson, ')
          ..write('versionsJson: $versionsJson, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Outbox extends Table with TableInfo<Outbox, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Outbox(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (sequence > 0)',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _envelopeJsonMeta = const VerificationMeta(
    'envelopeJson',
  );
  late final GeneratedColumn<String> envelopeJson = GeneratedColumn<String>(
    'envelope_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'local\' CHECK (state IN (\'local\', \'pending\', \'sending\', \'acknowledged\', \'conflict\', \'rejected\'))',
    defaultValue: const CustomExpression('\'local\''),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (attempts >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _retryAtMeta = const VerificationMeta(
    'retryAt',
  );
  late final GeneratedColumn<int> retryAt = GeneratedColumn<int>(
    'retry_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    sequence,
    entityId,
    envelopeJson,
    state,
    attempts,
    retryAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('envelope_json')) {
      context.handle(
        _envelopeJsonMeta,
        envelopeJson.isAcceptableOrUnknown(
          data['envelope_json']!,
          _envelopeJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_envelopeJsonMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('retry_at')) {
      context.handle(
        _retryAtMeta,
        retryAt.isAcceptableOrUnknown(data['retry_at']!, _retryAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      envelopeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope_json'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      retryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Outbox createAlias(String alias) {
    return Outbox(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final String operationId;
  final int sequence;
  final String entityId;
  final String envelopeJson;
  final String state;
  final int attempts;
  final int? retryAt;
  final int createdAt;
  const OutboxData({
    required this.operationId,
    required this.sequence,
    required this.entityId,
    required this.envelopeJson,
    required this.state,
    required this.attempts,
    this.retryAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['sequence'] = Variable<int>(sequence);
    map['entity_id'] = Variable<String>(entityId);
    map['envelope_json'] = Variable<String>(envelopeJson);
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || retryAt != null) {
      map['retry_at'] = Variable<int>(retryAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      operationId: Value(operationId),
      sequence: Value(sequence),
      entityId: Value(entityId),
      envelopeJson: Value(envelopeJson),
      state: Value(state),
      attempts: Value(attempts),
      retryAt: retryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retryAt),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      operationId: serializer.fromJson<String>(json['operation_id']),
      sequence: serializer.fromJson<int>(json['sequence']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      envelopeJson: serializer.fromJson<String>(json['envelope_json']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      retryAt: serializer.fromJson<int?>(json['retry_at']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operation_id': serializer.toJson<String>(operationId),
      'sequence': serializer.toJson<int>(sequence),
      'entity_id': serializer.toJson<String>(entityId),
      'envelope_json': serializer.toJson<String>(envelopeJson),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'retry_at': serializer.toJson<int?>(retryAt),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  OutboxData copyWith({
    String? operationId,
    int? sequence,
    String? entityId,
    String? envelopeJson,
    String? state,
    int? attempts,
    Value<int?> retryAt = const Value.absent(),
    int? createdAt,
  }) => OutboxData(
    operationId: operationId ?? this.operationId,
    sequence: sequence ?? this.sequence,
    entityId: entityId ?? this.entityId,
    envelopeJson: envelopeJson ?? this.envelopeJson,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    retryAt: retryAt.present ? retryAt.value : this.retryAt,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      envelopeJson: data.envelopeJson.present
          ? data.envelopeJson.value
          : this.envelopeJson,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      retryAt: data.retryAt.present ? data.retryAt.value : this.retryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('operationId: $operationId, ')
          ..write('sequence: $sequence, ')
          ..write('entityId: $entityId, ')
          ..write('envelopeJson: $envelopeJson, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('retryAt: $retryAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    sequence,
    entityId,
    envelopeJson,
    state,
    attempts,
    retryAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.operationId == this.operationId &&
          other.sequence == this.sequence &&
          other.entityId == this.entityId &&
          other.envelopeJson == this.envelopeJson &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.retryAt == this.retryAt &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<String> operationId;
  final Value<int> sequence;
  final Value<String> entityId;
  final Value<String> envelopeJson;
  final Value<String> state;
  final Value<int> attempts;
  final Value<int?> retryAt;
  final Value<int> createdAt;
  final Value<int> rowid;
  const OutboxCompanion({
    this.operationId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.entityId = const Value.absent(),
    this.envelopeJson = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.retryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String operationId,
    required int sequence,
    required String entityId,
    required String envelopeJson,
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.retryAt = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       sequence = Value(sequence),
       entityId = Value(entityId),
       envelopeJson = Value(envelopeJson),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<String>? operationId,
    Expression<int>? sequence,
    Expression<String>? entityId,
    Expression<String>? envelopeJson,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<int>? retryAt,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (sequence != null) 'sequence': sequence,
      if (entityId != null) 'entity_id': entityId,
      if (envelopeJson != null) 'envelope_json': envelopeJson,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (retryAt != null) 'retry_at': retryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? operationId,
    Value<int>? sequence,
    Value<String>? entityId,
    Value<String>? envelopeJson,
    Value<String>? state,
    Value<int>? attempts,
    Value<int?>? retryAt,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      operationId: operationId ?? this.operationId,
      sequence: sequence ?? this.sequence,
      entityId: entityId ?? this.entityId,
      envelopeJson: envelopeJson ?? this.envelopeJson,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      retryAt: retryAt ?? this.retryAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (envelopeJson.present) {
      map['envelope_json'] = Variable<String>(envelopeJson.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (retryAt.present) {
      map['retry_at'] = Variable<int>(retryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('operationId: $operationId, ')
          ..write('sequence: $sequence, ')
          ..write('entityId: $entityId, ')
          ..write('envelopeJson: $envelopeJson, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('retryAt: $retryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncCheckpoint extends Table
    with TableInfo<SyncCheckpoint, SyncCheckpointData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncCheckpoint(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (singleton = 1)',
  );
  static const VerificationMeta _serverEpochMeta = const VerificationMeta(
    'serverEpoch',
  );
  late final GeneratedColumn<String> serverEpoch = GeneratedColumn<String>(
    'server_epoch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (cursor >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _bootstrapTokenMeta = const VerificationMeta(
    'bootstrapToken',
  );
  late final GeneratedColumn<String> bootstrapToken = GeneratedColumn<String>(
    'bootstrap_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _bootstrapPageMeta = const VerificationMeta(
    'bootstrapPage',
  );
  late final GeneratedColumn<int> bootstrapPage = GeneratedColumn<int>(
    'bootstrap_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastSuccessMeta = const VerificationMeta(
    'lastSuccess',
  );
  late final GeneratedColumn<int> lastSuccess = GeneratedColumn<int>(
    'last_success',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    singleton,
    serverEpoch,
    cursor,
    bootstrapToken,
    bootstrapPage,
    lastSuccess,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_checkpoint';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCheckpointData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    if (data.containsKey('server_epoch')) {
      context.handle(
        _serverEpochMeta,
        serverEpoch.isAcceptableOrUnknown(
          data['server_epoch']!,
          _serverEpochMeta,
        ),
      );
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('bootstrap_token')) {
      context.handle(
        _bootstrapTokenMeta,
        bootstrapToken.isAcceptableOrUnknown(
          data['bootstrap_token']!,
          _bootstrapTokenMeta,
        ),
      );
    }
    if (data.containsKey('bootstrap_page')) {
      context.handle(
        _bootstrapPageMeta,
        bootstrapPage.isAcceptableOrUnknown(
          data['bootstrap_page']!,
          _bootstrapPageMeta,
        ),
      );
    }
    if (data.containsKey('last_success')) {
      context.handle(
        _lastSuccessMeta,
        lastSuccess.isAcceptableOrUnknown(
          data['last_success']!,
          _lastSuccessMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singleton};
  @override
  SyncCheckpointData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCheckpointData(
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
      serverEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_epoch'],
      ),
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
      bootstrapToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bootstrap_token'],
      ),
      bootstrapPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bootstrap_page'],
      ),
      lastSuccess: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_success'],
      ),
    );
  }

  @override
  SyncCheckpoint createAlias(String alias) {
    return SyncCheckpoint(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncCheckpointData extends DataClass
    implements Insertable<SyncCheckpointData> {
  final int singleton;
  final String? serverEpoch;
  final int cursor;
  final String? bootstrapToken;
  final int? bootstrapPage;
  final int? lastSuccess;
  const SyncCheckpointData({
    required this.singleton,
    this.serverEpoch,
    required this.cursor,
    this.bootstrapToken,
    this.bootstrapPage,
    this.lastSuccess,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton'] = Variable<int>(singleton);
    if (!nullToAbsent || serverEpoch != null) {
      map['server_epoch'] = Variable<String>(serverEpoch);
    }
    map['cursor'] = Variable<int>(cursor);
    if (!nullToAbsent || bootstrapToken != null) {
      map['bootstrap_token'] = Variable<String>(bootstrapToken);
    }
    if (!nullToAbsent || bootstrapPage != null) {
      map['bootstrap_page'] = Variable<int>(bootstrapPage);
    }
    if (!nullToAbsent || lastSuccess != null) {
      map['last_success'] = Variable<int>(lastSuccess);
    }
    return map;
  }

  SyncCheckpointCompanion toCompanion(bool nullToAbsent) {
    return SyncCheckpointCompanion(
      singleton: Value(singleton),
      serverEpoch: serverEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(serverEpoch),
      cursor: Value(cursor),
      bootstrapToken: bootstrapToken == null && nullToAbsent
          ? const Value.absent()
          : Value(bootstrapToken),
      bootstrapPage: bootstrapPage == null && nullToAbsent
          ? const Value.absent()
          : Value(bootstrapPage),
      lastSuccess: lastSuccess == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccess),
    );
  }

  factory SyncCheckpointData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCheckpointData(
      singleton: serializer.fromJson<int>(json['singleton']),
      serverEpoch: serializer.fromJson<String?>(json['server_epoch']),
      cursor: serializer.fromJson<int>(json['cursor']),
      bootstrapToken: serializer.fromJson<String?>(json['bootstrap_token']),
      bootstrapPage: serializer.fromJson<int?>(json['bootstrap_page']),
      lastSuccess: serializer.fromJson<int?>(json['last_success']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singleton': serializer.toJson<int>(singleton),
      'server_epoch': serializer.toJson<String?>(serverEpoch),
      'cursor': serializer.toJson<int>(cursor),
      'bootstrap_token': serializer.toJson<String?>(bootstrapToken),
      'bootstrap_page': serializer.toJson<int?>(bootstrapPage),
      'last_success': serializer.toJson<int?>(lastSuccess),
    };
  }

  SyncCheckpointData copyWith({
    int? singleton,
    Value<String?> serverEpoch = const Value.absent(),
    int? cursor,
    Value<String?> bootstrapToken = const Value.absent(),
    Value<int?> bootstrapPage = const Value.absent(),
    Value<int?> lastSuccess = const Value.absent(),
  }) => SyncCheckpointData(
    singleton: singleton ?? this.singleton,
    serverEpoch: serverEpoch.present ? serverEpoch.value : this.serverEpoch,
    cursor: cursor ?? this.cursor,
    bootstrapToken: bootstrapToken.present
        ? bootstrapToken.value
        : this.bootstrapToken,
    bootstrapPage: bootstrapPage.present
        ? bootstrapPage.value
        : this.bootstrapPage,
    lastSuccess: lastSuccess.present ? lastSuccess.value : this.lastSuccess,
  );
  SyncCheckpointData copyWithCompanion(SyncCheckpointCompanion data) {
    return SyncCheckpointData(
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
      serverEpoch: data.serverEpoch.present
          ? data.serverEpoch.value
          : this.serverEpoch,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      bootstrapToken: data.bootstrapToken.present
          ? data.bootstrapToken.value
          : this.bootstrapToken,
      bootstrapPage: data.bootstrapPage.present
          ? data.bootstrapPage.value
          : this.bootstrapPage,
      lastSuccess: data.lastSuccess.present
          ? data.lastSuccess.value
          : this.lastSuccess,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointData(')
          ..write('singleton: $singleton, ')
          ..write('serverEpoch: $serverEpoch, ')
          ..write('cursor: $cursor, ')
          ..write('bootstrapToken: $bootstrapToken, ')
          ..write('bootstrapPage: $bootstrapPage, ')
          ..write('lastSuccess: $lastSuccess')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singleton,
    serverEpoch,
    cursor,
    bootstrapToken,
    bootstrapPage,
    lastSuccess,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCheckpointData &&
          other.singleton == this.singleton &&
          other.serverEpoch == this.serverEpoch &&
          other.cursor == this.cursor &&
          other.bootstrapToken == this.bootstrapToken &&
          other.bootstrapPage == this.bootstrapPage &&
          other.lastSuccess == this.lastSuccess);
}

class SyncCheckpointCompanion extends UpdateCompanion<SyncCheckpointData> {
  final Value<int> singleton;
  final Value<String?> serverEpoch;
  final Value<int> cursor;
  final Value<String?> bootstrapToken;
  final Value<int?> bootstrapPage;
  final Value<int?> lastSuccess;
  const SyncCheckpointCompanion({
    this.singleton = const Value.absent(),
    this.serverEpoch = const Value.absent(),
    this.cursor = const Value.absent(),
    this.bootstrapToken = const Value.absent(),
    this.bootstrapPage = const Value.absent(),
    this.lastSuccess = const Value.absent(),
  });
  SyncCheckpointCompanion.insert({
    this.singleton = const Value.absent(),
    this.serverEpoch = const Value.absent(),
    this.cursor = const Value.absent(),
    this.bootstrapToken = const Value.absent(),
    this.bootstrapPage = const Value.absent(),
    this.lastSuccess = const Value.absent(),
  });
  static Insertable<SyncCheckpointData> custom({
    Expression<int>? singleton,
    Expression<String>? serverEpoch,
    Expression<int>? cursor,
    Expression<String>? bootstrapToken,
    Expression<int>? bootstrapPage,
    Expression<int>? lastSuccess,
  }) {
    return RawValuesInsertable({
      if (singleton != null) 'singleton': singleton,
      if (serverEpoch != null) 'server_epoch': serverEpoch,
      if (cursor != null) 'cursor': cursor,
      if (bootstrapToken != null) 'bootstrap_token': bootstrapToken,
      if (bootstrapPage != null) 'bootstrap_page': bootstrapPage,
      if (lastSuccess != null) 'last_success': lastSuccess,
    });
  }

  SyncCheckpointCompanion copyWith({
    Value<int>? singleton,
    Value<String?>? serverEpoch,
    Value<int>? cursor,
    Value<String?>? bootstrapToken,
    Value<int?>? bootstrapPage,
    Value<int?>? lastSuccess,
  }) {
    return SyncCheckpointCompanion(
      singleton: singleton ?? this.singleton,
      serverEpoch: serverEpoch ?? this.serverEpoch,
      cursor: cursor ?? this.cursor,
      bootstrapToken: bootstrapToken ?? this.bootstrapToken,
      bootstrapPage: bootstrapPage ?? this.bootstrapPage,
      lastSuccess: lastSuccess ?? this.lastSuccess,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (serverEpoch.present) {
      map['server_epoch'] = Variable<String>(serverEpoch.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (bootstrapToken.present) {
      map['bootstrap_token'] = Variable<String>(bootstrapToken.value);
    }
    if (bootstrapPage.present) {
      map['bootstrap_page'] = Variable<int>(bootstrapPage.value);
    }
    if (lastSuccess.present) {
      map['last_success'] = Variable<int>(lastSuccess.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointCompanion(')
          ..write('singleton: $singleton, ')
          ..write('serverEpoch: $serverEpoch, ')
          ..write('cursor: $cursor, ')
          ..write('bootstrapToken: $bootstrapToken, ')
          ..write('bootstrapPage: $bootstrapPage, ')
          ..write('lastSuccess: $lastSuccess')
          ..write(')'))
        .toString();
  }
}

class Conflicts extends Table with TableInfo<Conflicts, Conflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Conflicts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _baseJsonMeta = const VerificationMeta(
    'baseJson',
  );
  late final GeneratedColumn<String> baseJson = GeneratedColumn<String>(
    'base_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _localJsonMeta = const VerificationMeta(
    'localJson',
  );
  late final GeneratedColumn<String> localJson = GeneratedColumn<String>(
    'local_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _serverJsonMeta = const VerificationMeta(
    'serverJson',
  );
  late final GeneratedColumn<String> serverJson = GeneratedColumn<String>(
    'server_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  late final GeneratedColumn<int> resolvedAt = GeneratedColumn<int>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityId,
    baseJson,
    localJson,
    serverJson,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conflict> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('base_json')) {
      context.handle(
        _baseJsonMeta,
        baseJson.isAcceptableOrUnknown(data['base_json']!, _baseJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_baseJsonMeta);
    }
    if (data.containsKey('local_json')) {
      context.handle(
        _localJsonMeta,
        localJson.isAcceptableOrUnknown(data['local_json']!, _localJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_localJsonMeta);
    }
    if (data.containsKey('server_json')) {
      context.handle(
        _serverJsonMeta,
        serverJson.isAcceptableOrUnknown(data['server_json']!, _serverJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_serverJsonMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conflict(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      baseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_json'],
      )!,
      localJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_json'],
      )!,
      serverJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_json'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  Conflicts createAlias(String alias) {
    return Conflicts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Conflict extends DataClass implements Insertable<Conflict> {
  final String id;
  final String entityId;
  final String baseJson;
  final String localJson;
  final String serverJson;
  final int? resolvedAt;
  const Conflict({
    required this.id,
    required this.entityId,
    required this.baseJson,
    required this.localJson,
    required this.serverJson,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['base_json'] = Variable<String>(baseJson);
    map['local_json'] = Variable<String>(localJson);
    map['server_json'] = Variable<String>(serverJson);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<int>(resolvedAt);
    }
    return map;
  }

  ConflictsCompanion toCompanion(bool nullToAbsent) {
    return ConflictsCompanion(
      id: Value(id),
      entityId: Value(entityId),
      baseJson: Value(baseJson),
      localJson: Value(localJson),
      serverJson: Value(serverJson),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory Conflict.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conflict(
      id: serializer.fromJson<String>(json['id']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      baseJson: serializer.fromJson<String>(json['base_json']),
      localJson: serializer.fromJson<String>(json['local_json']),
      serverJson: serializer.fromJson<String>(json['server_json']),
      resolvedAt: serializer.fromJson<int?>(json['resolved_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entity_id': serializer.toJson<String>(entityId),
      'base_json': serializer.toJson<String>(baseJson),
      'local_json': serializer.toJson<String>(localJson),
      'server_json': serializer.toJson<String>(serverJson),
      'resolved_at': serializer.toJson<int?>(resolvedAt),
    };
  }

  Conflict copyWith({
    String? id,
    String? entityId,
    String? baseJson,
    String? localJson,
    String? serverJson,
    Value<int?> resolvedAt = const Value.absent(),
  }) => Conflict(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    baseJson: baseJson ?? this.baseJson,
    localJson: localJson ?? this.localJson,
    serverJson: serverJson ?? this.serverJson,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  Conflict copyWithCompanion(ConflictsCompanion data) {
    return Conflict(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      baseJson: data.baseJson.present ? data.baseJson.value : this.baseJson,
      localJson: data.localJson.present ? data.localJson.value : this.localJson,
      serverJson: data.serverJson.present
          ? data.serverJson.value
          : this.serverJson,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conflict(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('baseJson: $baseJson, ')
          ..write('localJson: $localJson, ')
          ..write('serverJson: $serverJson, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityId, baseJson, localJson, serverJson, resolvedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conflict &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.baseJson == this.baseJson &&
          other.localJson == this.localJson &&
          other.serverJson == this.serverJson &&
          other.resolvedAt == this.resolvedAt);
}

class ConflictsCompanion extends UpdateCompanion<Conflict> {
  final Value<String> id;
  final Value<String> entityId;
  final Value<String> baseJson;
  final Value<String> localJson;
  final Value<String> serverJson;
  final Value<int?> resolvedAt;
  final Value<int> rowid;
  const ConflictsCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.baseJson = const Value.absent(),
    this.localJson = const Value.absent(),
    this.serverJson = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictsCompanion.insert({
    required String id,
    required String entityId,
    required String baseJson,
    required String localJson,
    required String serverJson,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityId = Value(entityId),
       baseJson = Value(baseJson),
       localJson = Value(localJson),
       serverJson = Value(serverJson);
  static Insertable<Conflict> custom({
    Expression<String>? id,
    Expression<String>? entityId,
    Expression<String>? baseJson,
    Expression<String>? localJson,
    Expression<String>? serverJson,
    Expression<int>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (baseJson != null) 'base_json': baseJson,
      if (localJson != null) 'local_json': localJson,
      if (serverJson != null) 'server_json': serverJson,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityId,
    Value<String>? baseJson,
    Value<String>? localJson,
    Value<String>? serverJson,
    Value<int?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return ConflictsCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      baseJson: baseJson ?? this.baseJson,
      localJson: localJson ?? this.localJson,
      serverJson: serverJson ?? this.serverJson,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (baseJson.present) {
      map['base_json'] = Variable<String>(baseJson.value);
    }
    if (localJson.present) {
      map['local_json'] = Variable<String>(localJson.value);
    }
    if (serverJson.present) {
      map['server_json'] = Variable<String>(serverJson.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictsCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('baseJson: $baseJson, ')
          ..write('localJson: $localJson, ')
          ..write('serverJson: $serverJson, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class History extends Table with TableInfo<History, HistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  History(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityId,
    operationId,
    kind,
    occurredAt,
    detailJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_detailJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      )!,
    );
  }

  @override
  History createAlias(String alias) {
    return History(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class HistoryData extends DataClass implements Insertable<HistoryData> {
  final String id;
  final String entityId;
  final String operationId;
  final String kind;
  final int occurredAt;
  final String detailJson;
  const HistoryData({
    required this.id,
    required this.entityId,
    required this.operationId,
    required this.kind,
    required this.occurredAt,
    required this.detailJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['operation_id'] = Variable<String>(operationId);
    map['kind'] = Variable<String>(kind);
    map['occurred_at'] = Variable<int>(occurredAt);
    map['detail_json'] = Variable<String>(detailJson);
    return map;
  }

  HistoryCompanion toCompanion(bool nullToAbsent) {
    return HistoryCompanion(
      id: Value(id),
      entityId: Value(entityId),
      operationId: Value(operationId),
      kind: Value(kind),
      occurredAt: Value(occurredAt),
      detailJson: Value(detailJson),
    );
  }

  factory HistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryData(
      id: serializer.fromJson<String>(json['id']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      operationId: serializer.fromJson<String>(json['operation_id']),
      kind: serializer.fromJson<String>(json['kind']),
      occurredAt: serializer.fromJson<int>(json['occurred_at']),
      detailJson: serializer.fromJson<String>(json['detail_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entity_id': serializer.toJson<String>(entityId),
      'operation_id': serializer.toJson<String>(operationId),
      'kind': serializer.toJson<String>(kind),
      'occurred_at': serializer.toJson<int>(occurredAt),
      'detail_json': serializer.toJson<String>(detailJson),
    };
  }

  HistoryData copyWith({
    String? id,
    String? entityId,
    String? operationId,
    String? kind,
    int? occurredAt,
    String? detailJson,
  }) => HistoryData(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    operationId: operationId ?? this.operationId,
    kind: kind ?? this.kind,
    occurredAt: occurredAt ?? this.occurredAt,
    detailJson: detailJson ?? this.detailJson,
  );
  HistoryData copyWithCompanion(HistoryCompanion data) {
    return HistoryData(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      kind: data.kind.present ? data.kind.value : this.kind,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryData(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('operationId: $operationId, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('detailJson: $detailJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityId, operationId, kind, occurredAt, detailJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryData &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.operationId == this.operationId &&
          other.kind == this.kind &&
          other.occurredAt == this.occurredAt &&
          other.detailJson == this.detailJson);
}

class HistoryCompanion extends UpdateCompanion<HistoryData> {
  final Value<String> id;
  final Value<String> entityId;
  final Value<String> operationId;
  final Value<String> kind;
  final Value<int> occurredAt;
  final Value<String> detailJson;
  final Value<int> rowid;
  const HistoryCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operationId = const Value.absent(),
    this.kind = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryCompanion.insert({
    required String id,
    required String entityId,
    required String operationId,
    required String kind,
    required int occurredAt,
    required String detailJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityId = Value(entityId),
       operationId = Value(operationId),
       kind = Value(kind),
       occurredAt = Value(occurredAt),
       detailJson = Value(detailJson);
  static Insertable<HistoryData> custom({
    Expression<String>? id,
    Expression<String>? entityId,
    Expression<String>? operationId,
    Expression<String>? kind,
    Expression<int>? occurredAt,
    Expression<String>? detailJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (operationId != null) 'operation_id': operationId,
      if (kind != null) 'kind': kind,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (detailJson != null) 'detail_json': detailJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? entityId,
    Value<String>? operationId,
    Value<String>? kind,
    Value<int>? occurredAt,
    Value<String>? detailJson,
    Value<int>? rowid,
  }) {
    return HistoryCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      operationId: operationId ?? this.operationId,
      kind: kind ?? this.kind,
      occurredAt: occurredAt ?? this.occurredAt,
      detailJson: detailJson ?? this.detailJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('operationId: $operationId, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('detailJson: $detailJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tombstones extends Table with TableInfo<Tombstones, Tombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tombstones(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityId,
    entityKind,
    revision,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId};
  @override
  Tombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tombstone(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  Tombstones createAlias(String alias) {
    return Tombstones(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Tombstone extends DataClass implements Insertable<Tombstone> {
  final String entityId;
  final String entityKind;
  final int? revision;
  final int deletedAt;
  const Tombstone({
    required this.entityId,
    required this.entityKind,
    this.revision,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['entity_kind'] = Variable<String>(entityKind);
    if (!nullToAbsent || revision != null) {
      map['revision'] = Variable<int>(revision);
    }
    map['deleted_at'] = Variable<int>(deletedAt);
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      entityId: Value(entityId),
      entityKind: Value(entityKind),
      revision: revision == null && nullToAbsent
          ? const Value.absent()
          : Value(revision),
      deletedAt: Value(deletedAt),
    );
  }

  factory Tombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tombstone(
      entityId: serializer.fromJson<String>(json['entity_id']),
      entityKind: serializer.fromJson<String>(json['entity_kind']),
      revision: serializer.fromJson<int?>(json['revision']),
      deletedAt: serializer.fromJson<int>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity_id': serializer.toJson<String>(entityId),
      'entity_kind': serializer.toJson<String>(entityKind),
      'revision': serializer.toJson<int?>(revision),
      'deleted_at': serializer.toJson<int>(deletedAt),
    };
  }

  Tombstone copyWith({
    String? entityId,
    String? entityKind,
    Value<int?> revision = const Value.absent(),
    int? deletedAt,
  }) => Tombstone(
    entityId: entityId ?? this.entityId,
    entityKind: entityKind ?? this.entityKind,
    revision: revision.present ? revision.value : this.revision,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  Tombstone copyWithCompanion(TombstonesCompanion data) {
    return Tombstone(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      revision: data.revision.present ? data.revision.value : this.revision,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tombstone(')
          ..write('entityId: $entityId, ')
          ..write('entityKind: $entityKind, ')
          ..write('revision: $revision, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityId, entityKind, revision, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tombstone &&
          other.entityId == this.entityId &&
          other.entityKind == this.entityKind &&
          other.revision == this.revision &&
          other.deletedAt == this.deletedAt);
}

class TombstonesCompanion extends UpdateCompanion<Tombstone> {
  final Value<String> entityId;
  final Value<String> entityKind;
  final Value<int?> revision;
  final Value<int> deletedAt;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.entityId = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.revision = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String entityId,
    required String entityKind,
    this.revision = const Value.absent(),
    required int deletedAt,
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId),
       entityKind = Value(entityKind),
       deletedAt = Value(deletedAt);
  static Insertable<Tombstone> custom({
    Expression<String>? entityId,
    Expression<String>? entityKind,
    Expression<int>? revision,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (entityKind != null) 'entity_kind': entityKind,
      if (revision != null) 'revision': revision,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? entityId,
    Value<String>? entityKind,
    Value<int?>? revision,
    Value<int>? deletedAt,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      entityId: entityId ?? this.entityId,
      entityKind: entityKind ?? this.entityKind,
      revision: revision ?? this.revision,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('entityId: $entityId, ')
          ..write('entityKind: $entityKind, ')
          ..write('revision: $revision, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NotificationDirty extends Table
    with TableInfo<NotificationDirty, NotificationDirtyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NotificationDirty(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (generation > 0)',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [entityId, generation];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_dirty';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationDirtyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId};
  @override
  NotificationDirtyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationDirtyData(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
    );
  }

  @override
  NotificationDirty createAlias(String alias) {
    return NotificationDirty(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class NotificationDirtyData extends DataClass
    implements Insertable<NotificationDirtyData> {
  final String entityId;
  final int generation;
  const NotificationDirtyData({
    required this.entityId,
    required this.generation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['generation'] = Variable<int>(generation);
    return map;
  }

  NotificationDirtyCompanion toCompanion(bool nullToAbsent) {
    return NotificationDirtyCompanion(
      entityId: Value(entityId),
      generation: Value(generation),
    );
  }

  factory NotificationDirtyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationDirtyData(
      entityId: serializer.fromJson<String>(json['entity_id']),
      generation: serializer.fromJson<int>(json['generation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity_id': serializer.toJson<String>(entityId),
      'generation': serializer.toJson<int>(generation),
    };
  }

  NotificationDirtyData copyWith({String? entityId, int? generation}) =>
      NotificationDirtyData(
        entityId: entityId ?? this.entityId,
        generation: generation ?? this.generation,
      );
  NotificationDirtyData copyWithCompanion(NotificationDirtyCompanion data) {
    return NotificationDirtyData(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationDirtyData(')
          ..write('entityId: $entityId, ')
          ..write('generation: $generation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityId, generation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationDirtyData &&
          other.entityId == this.entityId &&
          other.generation == this.generation);
}

class NotificationDirtyCompanion
    extends UpdateCompanion<NotificationDirtyData> {
  final Value<String> entityId;
  final Value<int> generation;
  final Value<int> rowid;
  const NotificationDirtyCompanion({
    this.entityId = const Value.absent(),
    this.generation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationDirtyCompanion.insert({
    required String entityId,
    this.generation = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId);
  static Insertable<NotificationDirtyData> custom({
    Expression<String>? entityId,
    Expression<int>? generation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (generation != null) 'generation': generation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationDirtyCompanion copyWith({
    Value<String>? entityId,
    Value<int>? generation,
    Value<int>? rowid,
  }) {
    return NotificationDirtyCompanion(
      entityId: entityId ?? this.entityId,
      generation: generation ?? this.generation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationDirtyCompanion(')
          ..write('entityId: $entityId, ')
          ..write('generation: $generation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DeviceNotifications extends Table
    with TableInfo<DeviceNotifications, DeviceNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DeviceNotifications(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _logicalKeyMeta = const VerificationMeta(
    'logicalKey',
  );
  late final GeneratedColumn<String> logicalKey = GeneratedColumn<String>(
    'logical_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _osIdMeta = const VerificationMeta('osId');
  late final GeneratedColumn<int> osId = GeneratedColumn<int>(
    'os_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  late final GeneratedColumn<int> scheduledAt = GeneratedColumn<int>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _registrationStateMeta = const VerificationMeta(
    'registrationState',
  );
  late final GeneratedColumn<String> registrationState =
      GeneratedColumn<String>(
        'registration_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<GeneratedColumn> get $columns => [
    logicalKey,
    osId,
    scheduledAt,
    generation,
    fingerprint,
    registrationState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('logical_key')) {
      context.handle(
        _logicalKeyMeta,
        logicalKey.isAcceptableOrUnknown(data['logical_key']!, _logicalKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_logicalKeyMeta);
    }
    if (data.containsKey('os_id')) {
      context.handle(
        _osIdMeta,
        osId.isAcceptableOrUnknown(data['os_id']!, _osIdMeta),
      );
    } else if (isInserting) {
      context.missing(_osIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    } else if (isInserting) {
      context.missing(_generationMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('registration_state')) {
      context.handle(
        _registrationStateMeta,
        registrationState.isAcceptableOrUnknown(
          data['registration_state']!,
          _registrationStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registrationStateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {logicalKey};
  @override
  DeviceNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceNotification(
      logicalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logical_key'],
      )!,
      osId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}os_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_at'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      registrationState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_state'],
      )!,
    );
  }

  @override
  DeviceNotifications createAlias(String alias) {
    return DeviceNotifications(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DeviceNotification extends DataClass
    implements Insertable<DeviceNotification> {
  final String logicalKey;
  final int osId;
  final int scheduledAt;
  final int generation;
  final String fingerprint;
  final String registrationState;
  const DeviceNotification({
    required this.logicalKey,
    required this.osId,
    required this.scheduledAt,
    required this.generation,
    required this.fingerprint,
    required this.registrationState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['logical_key'] = Variable<String>(logicalKey);
    map['os_id'] = Variable<int>(osId);
    map['scheduled_at'] = Variable<int>(scheduledAt);
    map['generation'] = Variable<int>(generation);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['registration_state'] = Variable<String>(registrationState);
    return map;
  }

  DeviceNotificationsCompanion toCompanion(bool nullToAbsent) {
    return DeviceNotificationsCompanion(
      logicalKey: Value(logicalKey),
      osId: Value(osId),
      scheduledAt: Value(scheduledAt),
      generation: Value(generation),
      fingerprint: Value(fingerprint),
      registrationState: Value(registrationState),
    );
  }

  factory DeviceNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceNotification(
      logicalKey: serializer.fromJson<String>(json['logical_key']),
      osId: serializer.fromJson<int>(json['os_id']),
      scheduledAt: serializer.fromJson<int>(json['scheduled_at']),
      generation: serializer.fromJson<int>(json['generation']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      registrationState: serializer.fromJson<String>(
        json['registration_state'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'logical_key': serializer.toJson<String>(logicalKey),
      'os_id': serializer.toJson<int>(osId),
      'scheduled_at': serializer.toJson<int>(scheduledAt),
      'generation': serializer.toJson<int>(generation),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'registration_state': serializer.toJson<String>(registrationState),
    };
  }

  DeviceNotification copyWith({
    String? logicalKey,
    int? osId,
    int? scheduledAt,
    int? generation,
    String? fingerprint,
    String? registrationState,
  }) => DeviceNotification(
    logicalKey: logicalKey ?? this.logicalKey,
    osId: osId ?? this.osId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    generation: generation ?? this.generation,
    fingerprint: fingerprint ?? this.fingerprint,
    registrationState: registrationState ?? this.registrationState,
  );
  DeviceNotification copyWithCompanion(DeviceNotificationsCompanion data) {
    return DeviceNotification(
      logicalKey: data.logicalKey.present
          ? data.logicalKey.value
          : this.logicalKey,
      osId: data.osId.present ? data.osId.value : this.osId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      registrationState: data.registrationState.present
          ? data.registrationState.value
          : this.registrationState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceNotification(')
          ..write('logicalKey: $logicalKey, ')
          ..write('osId: $osId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('generation: $generation, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('registrationState: $registrationState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    logicalKey,
    osId,
    scheduledAt,
    generation,
    fingerprint,
    registrationState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceNotification &&
          other.logicalKey == this.logicalKey &&
          other.osId == this.osId &&
          other.scheduledAt == this.scheduledAt &&
          other.generation == this.generation &&
          other.fingerprint == this.fingerprint &&
          other.registrationState == this.registrationState);
}

class DeviceNotificationsCompanion extends UpdateCompanion<DeviceNotification> {
  final Value<String> logicalKey;
  final Value<int> osId;
  final Value<int> scheduledAt;
  final Value<int> generation;
  final Value<String> fingerprint;
  final Value<String> registrationState;
  final Value<int> rowid;
  const DeviceNotificationsCompanion({
    this.logicalKey = const Value.absent(),
    this.osId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.generation = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.registrationState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceNotificationsCompanion.insert({
    required String logicalKey,
    required int osId,
    required int scheduledAt,
    required int generation,
    required String fingerprint,
    required String registrationState,
    this.rowid = const Value.absent(),
  }) : logicalKey = Value(logicalKey),
       osId = Value(osId),
       scheduledAt = Value(scheduledAt),
       generation = Value(generation),
       fingerprint = Value(fingerprint),
       registrationState = Value(registrationState);
  static Insertable<DeviceNotification> custom({
    Expression<String>? logicalKey,
    Expression<int>? osId,
    Expression<int>? scheduledAt,
    Expression<int>? generation,
    Expression<String>? fingerprint,
    Expression<String>? registrationState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (logicalKey != null) 'logical_key': logicalKey,
      if (osId != null) 'os_id': osId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (generation != null) 'generation': generation,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (registrationState != null) 'registration_state': registrationState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceNotificationsCompanion copyWith({
    Value<String>? logicalKey,
    Value<int>? osId,
    Value<int>? scheduledAt,
    Value<int>? generation,
    Value<String>? fingerprint,
    Value<String>? registrationState,
    Value<int>? rowid,
  }) {
    return DeviceNotificationsCompanion(
      logicalKey: logicalKey ?? this.logicalKey,
      osId: osId ?? this.osId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      generation: generation ?? this.generation,
      fingerprint: fingerprint ?? this.fingerprint,
      registrationState: registrationState ?? this.registrationState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (logicalKey.present) {
      map['logical_key'] = Variable<String>(logicalKey.value);
    }
    if (osId.present) {
      map['os_id'] = Variable<int>(osId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<int>(scheduledAt.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (registrationState.present) {
      map['registration_state'] = Variable<String>(registrationState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceNotificationsCompanion(')
          ..write('logicalKey: $logicalKey, ')
          ..write('osId: $osId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('generation: $generation, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('registrationState: $registrationState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ImportJournal extends Table
    with TableInfo<ImportJournal, ImportJournalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ImportJournal(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceLineageMeta = const VerificationMeta(
    'sourceLineage',
  );
  late final GeneratedColumn<String> sourceLineage = GeneratedColumn<String>(
    'source_lineage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _destinationIdMeta = const VerificationMeta(
    'destinationId',
  );
  late final GeneratedColumn<String> destinationId = GeneratedColumn<String>(
    'destination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceLineage,
    sourceId,
    destinationId,
    batchId,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_journal';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportJournalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_lineage')) {
      context.handle(
        _sourceLineageMeta,
        sourceLineage.isAcceptableOrUnknown(
          data['source_lineage']!,
          _sourceLineageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceLineageMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('destination_id')) {
      context.handle(
        _destinationIdMeta,
        destinationId.isAcceptableOrUnknown(
          data['destination_id']!,
          _destinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceLineage, sourceId};
  @override
  ImportJournalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportJournalData(
      sourceLineage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_lineage'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      destinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  ImportJournal createAlias(String alias) {
    return ImportJournal(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(source_lineage, source_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ImportJournalData extends DataClass
    implements Insertable<ImportJournalData> {
  final String sourceLineage;
  final String sourceId;
  final String destinationId;
  final String batchId;
  final String state;
  const ImportJournalData({
    required this.sourceLineage,
    required this.sourceId,
    required this.destinationId,
    required this.batchId,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_lineage'] = Variable<String>(sourceLineage);
    map['source_id'] = Variable<String>(sourceId);
    map['destination_id'] = Variable<String>(destinationId);
    map['batch_id'] = Variable<String>(batchId);
    map['state'] = Variable<String>(state);
    return map;
  }

  ImportJournalCompanion toCompanion(bool nullToAbsent) {
    return ImportJournalCompanion(
      sourceLineage: Value(sourceLineage),
      sourceId: Value(sourceId),
      destinationId: Value(destinationId),
      batchId: Value(batchId),
      state: Value(state),
    );
  }

  factory ImportJournalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportJournalData(
      sourceLineage: serializer.fromJson<String>(json['source_lineage']),
      sourceId: serializer.fromJson<String>(json['source_id']),
      destinationId: serializer.fromJson<String>(json['destination_id']),
      batchId: serializer.fromJson<String>(json['batch_id']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_lineage': serializer.toJson<String>(sourceLineage),
      'source_id': serializer.toJson<String>(sourceId),
      'destination_id': serializer.toJson<String>(destinationId),
      'batch_id': serializer.toJson<String>(batchId),
      'state': serializer.toJson<String>(state),
    };
  }

  ImportJournalData copyWith({
    String? sourceLineage,
    String? sourceId,
    String? destinationId,
    String? batchId,
    String? state,
  }) => ImportJournalData(
    sourceLineage: sourceLineage ?? this.sourceLineage,
    sourceId: sourceId ?? this.sourceId,
    destinationId: destinationId ?? this.destinationId,
    batchId: batchId ?? this.batchId,
    state: state ?? this.state,
  );
  ImportJournalData copyWithCompanion(ImportJournalCompanion data) {
    return ImportJournalData(
      sourceLineage: data.sourceLineage.present
          ? data.sourceLineage.value
          : this.sourceLineage,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      destinationId: data.destinationId.present
          ? data.destinationId.value
          : this.destinationId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportJournalData(')
          ..write('sourceLineage: $sourceLineage, ')
          ..write('sourceId: $sourceId, ')
          ..write('destinationId: $destinationId, ')
          ..write('batchId: $batchId, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceLineage, sourceId, destinationId, batchId, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportJournalData &&
          other.sourceLineage == this.sourceLineage &&
          other.sourceId == this.sourceId &&
          other.destinationId == this.destinationId &&
          other.batchId == this.batchId &&
          other.state == this.state);
}

class ImportJournalCompanion extends UpdateCompanion<ImportJournalData> {
  final Value<String> sourceLineage;
  final Value<String> sourceId;
  final Value<String> destinationId;
  final Value<String> batchId;
  final Value<String> state;
  final Value<int> rowid;
  const ImportJournalCompanion({
    this.sourceLineage = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.destinationId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportJournalCompanion.insert({
    required String sourceLineage,
    required String sourceId,
    required String destinationId,
    required String batchId,
    required String state,
    this.rowid = const Value.absent(),
  }) : sourceLineage = Value(sourceLineage),
       sourceId = Value(sourceId),
       destinationId = Value(destinationId),
       batchId = Value(batchId),
       state = Value(state);
  static Insertable<ImportJournalData> custom({
    Expression<String>? sourceLineage,
    Expression<String>? sourceId,
    Expression<String>? destinationId,
    Expression<String>? batchId,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceLineage != null) 'source_lineage': sourceLineage,
      if (sourceId != null) 'source_id': sourceId,
      if (destinationId != null) 'destination_id': destinationId,
      if (batchId != null) 'batch_id': batchId,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportJournalCompanion copyWith({
    Value<String>? sourceLineage,
    Value<String>? sourceId,
    Value<String>? destinationId,
    Value<String>? batchId,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return ImportJournalCompanion(
      sourceLineage: sourceLineage ?? this.sourceLineage,
      sourceId: sourceId ?? this.sourceId,
      destinationId: destinationId ?? this.destinationId,
      batchId: batchId ?? this.batchId,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceLineage.present) {
      map['source_lineage'] = Variable<String>(sourceLineage.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (destinationId.present) {
      map['destination_id'] = Variable<String>(destinationId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportJournalCompanion(')
          ..write('sourceLineage: $sourceLineage, ')
          ..write('sourceId: $sourceId, ')
          ..write('destinationId: $destinationId, ')
          ..write('batchId: $batchId, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final ProfileMetadata profileMetadata = ProfileMetadata(this);
  late final Tasks tasks = Tasks(this);
  late final Index tasksStatus = Index(
    'tasks_status',
    'CREATE INDEX tasks_status ON tasks (status, deleted_at)',
  );
  late final Index tasksDue = Index(
    'tasks_due',
    'CREATE INDEX tasks_due ON tasks (due_date, due_instant)',
  );
  late final Tags tags = Tags(this);
  late final TaskTags taskTags = TaskTags(this);
  late final Milestones milestones = Milestones(this);
  late final Index milestonesParent = Index(
    'milestones_parent',
    'CREATE INDEX milestones_parent ON milestones (task_id, position, id)',
  );
  late final RecurrenceSeries recurrenceSeries = RecurrenceSeries(this);
  late final RecurrenceSegments recurrenceSegments = RecurrenceSegments(this);
  late final OccurrenceState occurrenceState = OccurrenceState(this);
  late final ReminderRules reminderRules = ReminderRules(this);
  late final Snoozes snoozes = Snoozes(this);
  late final SavedViews savedViews = SavedViews(this);
  late final SharedPreferences sharedPreferences = SharedPreferences(this);
  late final DevicePreferences devicePreferences = DevicePreferences(this);
  late final SyncShadow syncShadow = SyncShadow(this);
  late final Outbox outbox = Outbox(this);
  late final SyncCheckpoint syncCheckpoint = SyncCheckpoint(this);
  late final Conflicts conflicts = Conflicts(this);
  late final History history = History(this);
  late final Tombstones tombstones = Tombstones(this);
  late final NotificationDirty notificationDirty = NotificationDirty(this);
  late final DeviceNotifications deviceNotifications = DeviceNotifications(
    this,
  );
  late final ImportJournal importJournal = ImportJournal(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profileMetadata,
    tasks,
    tasksStatus,
    tasksDue,
    tags,
    taskTags,
    milestones,
    milestonesParent,
    recurrenceSeries,
    recurrenceSegments,
    occurrenceState,
    reminderRules,
    snoozes,
    savedViews,
    sharedPreferences,
    devicePreferences,
    syncShadow,
    outbox,
    syncCheckpoint,
    conflicts,
    history,
    tombstones,
    notificationDirty,
    deviceNotifications,
    importJournal,
  ];
}

typedef $ProfileMetadataCreateCompanionBuilder =
    ProfileMetadataCompanion Function({
      Value<int> singleton,
      required String profileId,
      required String lineageId,
      required String deviceEpoch,
      Value<int> nextSequence,
    });
typedef $ProfileMetadataUpdateCompanionBuilder =
    ProfileMetadataCompanion Function({
      Value<int> singleton,
      Value<String> profileId,
      Value<String> lineageId,
      Value<String> deviceEpoch,
      Value<int> nextSequence,
    });

class $ProfileMetadataFilterComposer
    extends Composer<_$AppDatabase, ProfileMetadata> {
  $ProfileMetadataFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineageId => $composableBuilder(
    column: $table.lineageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceEpoch => $composableBuilder(
    column: $table.deviceEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextSequence => $composableBuilder(
    column: $table.nextSequence,
    builder: (column) => ColumnFilters(column),
  );
}

class $ProfileMetadataOrderingComposer
    extends Composer<_$AppDatabase, ProfileMetadata> {
  $ProfileMetadataOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineageId => $composableBuilder(
    column: $table.lineageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceEpoch => $composableBuilder(
    column: $table.deviceEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextSequence => $composableBuilder(
    column: $table.nextSequence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ProfileMetadataAnnotationComposer
    extends Composer<_$AppDatabase, ProfileMetadata> {
  $ProfileMetadataAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singleton =>
      $composableBuilder(column: $table.singleton, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get lineageId =>
      $composableBuilder(column: $table.lineageId, builder: (column) => column);

  GeneratedColumn<String> get deviceEpoch => $composableBuilder(
    column: $table.deviceEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextSequence => $composableBuilder(
    column: $table.nextSequence,
    builder: (column) => column,
  );
}

class $ProfileMetadataTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ProfileMetadata,
          ProfileMetadataData,
          $ProfileMetadataFilterComposer,
          $ProfileMetadataOrderingComposer,
          $ProfileMetadataAnnotationComposer,
          $ProfileMetadataCreateCompanionBuilder,
          $ProfileMetadataUpdateCompanionBuilder,
          (
            ProfileMetadataData,
            BaseReferences<_$AppDatabase, ProfileMetadata, ProfileMetadataData>,
          ),
          ProfileMetadataData,
          PrefetchHooks Function()
        > {
  $ProfileMetadataTableManager(_$AppDatabase db, ProfileMetadata table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProfileMetadataFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProfileMetadataOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProfileMetadataAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> lineageId = const Value.absent(),
                Value<String> deviceEpoch = const Value.absent(),
                Value<int> nextSequence = const Value.absent(),
              }) => ProfileMetadataCompanion(
                singleton: singleton,
                profileId: profileId,
                lineageId: lineageId,
                deviceEpoch: deviceEpoch,
                nextSequence: nextSequence,
              ),
          createCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                required String profileId,
                required String lineageId,
                required String deviceEpoch,
                Value<int> nextSequence = const Value.absent(),
              }) => ProfileMetadataCompanion.insert(
                singleton: singleton,
                profileId: profileId,
                lineageId: lineageId,
                deviceEpoch: deviceEpoch,
                nextSequence: nextSequence,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ProfileMetadata, ProfileMetadataData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    ProfileMetadata,
                    ProfileMetadataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ProfileMetadataProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ProfileMetadata,
      ProfileMetadataData,
      $ProfileMetadataFilterComposer,
      $ProfileMetadataOrderingComposer,
      $ProfileMetadataAnnotationComposer,
      $ProfileMetadataCreateCompanionBuilder,
      $ProfileMetadataUpdateCompanionBuilder,
      (
        ProfileMetadataData,
        BaseReferences<_$AppDatabase, ProfileMetadata, ProfileMetadataData>,
      ),
      ProfileMetadataData,
      PrefetchHooks Function()
    >;
typedef $TasksCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String> description,
  Value<String> status,
  Value<int> priority,
  Value<String> dueKind,
  Value<String?> dueDate,
  Value<int?> dueInstant,
  Value<String?> dueZone,
  Value<String?> dueWallTime,
  Value<int?> estimateMinutes,
  Value<String?> occurrenceId,
  required int createdAt,
  required int updatedAt,
  Value<int?> completedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $TasksUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> description,
  Value<String> status,
  Value<int> priority,
  Value<String> dueKind,
  Value<String?> dueDate,
  Value<int?> dueInstant,
  Value<String?> dueZone,
  Value<String?> dueWallTime,
  Value<int?> estimateMinutes,
  Value<String?> occurrenceId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> completedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $TasksReferences
    extends BaseReferences<_$AppDatabase, Tasks, Task> {
  $TasksReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<TaskTags, List<TaskTag>> _taskTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: 'tasks__id__task_tags__task_id',
  );

  $TaskTagsProcessedTableManager get taskTagsRefs {
    final manager = $TaskTagsTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Milestones, List<Milestone>> _milestonesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.milestones,
    aliasName: 'tasks__id__milestones__task_id',
  );

  $MilestonesProcessedTableManager get milestonesRefs {
    final manager = $MilestonesTableManager(
      $_db,
      $_db.milestones,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_milestonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ReminderRules, List<ReminderRule>>
  _reminderRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminderRules,
    aliasName: 'tasks__id__reminder_rules__task_id',
  );

  $ReminderRulesProcessedTableManager get reminderRulesRefs {
    final manager = $ReminderRulesTableManager(
      $_db,
      $_db.reminderRules,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reminderRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Snoozes, List<Snooze>> _snoozesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.snoozes,
    aliasName: 'tasks__id__snoozes__task_id',
  );

  $SnoozesProcessedTableManager get snoozesRefs {
    final manager = $SnoozesTableManager(
      $_db,
      $_db.snoozes,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_snoozesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TasksFilterComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueKind => $composableBuilder(
    column: $table.dueKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueInstant => $composableBuilder(
    column: $table.dueInstant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueZone => $composableBuilder(
    column: $table.dueZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueWallTime => $composableBuilder(
    column: $table.dueWallTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($TaskTagsFilterComposer f) f,
  ) {
    final $TaskTagsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TaskTagsFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> milestonesRefs(
    Expression<bool> Function($MilestonesFilterComposer f) f,
  ) {
    final $MilestonesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestones,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MilestonesFilterComposer(
            $db: $db,
            $table: $db.milestones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reminderRulesRefs(
    Expression<bool> Function($ReminderRulesFilterComposer f) f,
  ) {
    final $ReminderRulesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReminderRulesFilterComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> snoozesRefs(
    Expression<bool> Function($SnoozesFilterComposer f) f,
  ) {
    final $SnoozesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snoozes,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SnoozesFilterComposer(
            $db: $db,
            $table: $db.snoozes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TasksOrderingComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueKind => $composableBuilder(
    column: $table.dueKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueInstant => $composableBuilder(
    column: $table.dueInstant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueZone => $composableBuilder(
    column: $table.dueZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueWallTime => $composableBuilder(
    column: $table.dueWallTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TasksAnnotationComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get dueKind =>
      $composableBuilder(column: $table.dueKind, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueInstant => $composableBuilder(
    column: $table.dueInstant,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueZone =>
      $composableBuilder(column: $table.dueZone, builder: (column) => column);

  GeneratedColumn<String> get dueWallTime => $composableBuilder(
    column: $table.dueWallTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($TaskTagsAnnotationComposer a) f,
  ) {
    final $TaskTagsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TaskTagsAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> milestonesRefs<T extends Object>(
    Expression<T> Function($MilestonesAnnotationComposer a) f,
  ) {
    final $MilestonesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestones,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MilestonesAnnotationComposer(
            $db: $db,
            $table: $db.milestones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reminderRulesRefs<T extends Object>(
    Expression<T> Function($ReminderRulesAnnotationComposer a) f,
  ) {
    final $ReminderRulesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReminderRulesAnnotationComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> snoozesRefs<T extends Object>(
    Expression<T> Function($SnoozesAnnotationComposer a) f,
  ) {
    final $SnoozesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snoozes,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SnoozesAnnotationComposer(
            $db: $db,
            $table: $db.snoozes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TasksTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Tasks,
          Task,
          $TasksFilterComposer,
          $TasksOrderingComposer,
          $TasksAnnotationComposer,
          $TasksCreateCompanionBuilder,
          $TasksUpdateCompanionBuilder,
          (Task, $TasksReferences),
          Task,
          PrefetchHooks Function({
            bool taskTagsRefs,
            bool milestonesRefs,
            bool reminderRulesRefs,
            bool snoozesRefs,
          })
        > {
  $TasksTableManager(_$AppDatabase db, Tasks table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TasksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TasksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TasksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> dueKind = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> dueInstant = const Value.absent(),
                Value<String?> dueZone = const Value.absent(),
                Value<String?> dueWallTime = const Value.absent(),
                Value<int?> estimateMinutes = const Value.absent(),
                Value<String?> occurrenceId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                description: description,
                status: status,
                priority: priority,
                dueKind: dueKind,
                dueDate: dueDate,
                dueInstant: dueInstant,
                dueZone: dueZone,
                dueWallTime: dueWallTime,
                estimateMinutes: estimateMinutes,
                occurrenceId: occurrenceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> dueKind = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> dueInstant = const Value.absent(),
                Value<String?> dueZone = const Value.absent(),
                Value<String?> dueWallTime = const Value.absent(),
                Value<int?> estimateMinutes = const Value.absent(),
                Value<String?> occurrenceId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                description: description,
                status: status,
                priority: priority,
                dueKind: dueKind,
                dueDate: dueDate,
                dueInstant: dueInstant,
                dueZone: dueZone,
                dueWallTime: dueWallTime,
                estimateMinutes: estimateMinutes,
                occurrenceId: occurrenceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Tasks, Task>(table),
                  $TasksReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                taskTagsRefs = false,
                milestonesRefs = false,
                reminderRulesRefs = false,
                snoozesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskTagsRefs) db.taskTags,
                    if (milestonesRefs) db.milestones,
                    if (reminderRulesRefs) db.reminderRules,
                    if (snoozesRefs) db.snoozes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskTagsRefs)
                        await $_getPrefetchedData<Task, Tasks, TaskTag>(
                          currentTable: table,
                          referencedTable: $TasksReferences._taskTagsRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $TasksReferences(db, table, p0).taskTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (milestonesRefs)
                        await $_getPrefetchedData<Task, Tasks, Milestone>(
                          currentTable: table,
                          referencedTable: $TasksReferences
                              ._milestonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $TasksReferences(db, table, p0).milestonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reminderRulesRefs)
                        await $_getPrefetchedData<Task, Tasks, ReminderRule>(
                          currentTable: table,
                          referencedTable: $TasksReferences
                              ._reminderRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $TasksReferences(db, table, p0).reminderRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (snoozesRefs)
                        await $_getPrefetchedData<Task, Tasks, Snooze>(
                          currentTable: table,
                          referencedTable: $TasksReferences._snoozesRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $TasksReferences(db, table, p0).snoozesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $TasksProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Tasks,
      Task,
      $TasksFilterComposer,
      $TasksOrderingComposer,
      $TasksAnnotationComposer,
      $TasksCreateCompanionBuilder,
      $TasksUpdateCompanionBuilder,
      (Task, $TasksReferences),
      Task,
      PrefetchHooks Function({
        bool taskTagsRefs,
        bool milestonesRefs,
        bool reminderRulesRefs,
        bool snoozesRefs,
      })
    >;
typedef $TagsCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String name,
  required String normalizedName,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $TagsUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> normalizedName,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $TagsReferences extends BaseReferences<_$AppDatabase, Tags, Tag> {
  $TagsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<TaskTags, List<TaskTag>> _taskTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: 'tags__id__task_tags__tag_id',
  );

  $TaskTagsProcessedTableManager get taskTagsRefs {
    final manager = $TaskTagsTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TagsFilterComposer extends Composer<_$AppDatabase, Tags> {
  $TagsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($TaskTagsFilterComposer f) f,
  ) {
    final $TaskTagsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TaskTagsFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TagsOrderingComposer extends Composer<_$AppDatabase, Tags> {
  $TagsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TagsAnnotationComposer extends Composer<_$AppDatabase, Tags> {
  $TagsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($TaskTagsAnnotationComposer a) f,
  ) {
    final $TaskTagsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TaskTagsAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TagsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Tags,
          Tag,
          $TagsFilterComposer,
          $TagsOrderingComposer,
          $TagsAnnotationComposer,
          $TagsCreateCompanionBuilder,
          $TagsUpdateCompanionBuilder,
          (Tag, $TagsReferences),
          Tag,
          PrefetchHooks Function({bool taskTagsRefs})
        > {
  $TagsTableManager(_$AppDatabase db, Tags table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TagsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TagsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TagsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Tags, Tag>(table),
                  $TagsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (taskTagsRefs) db.taskTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskTagsRefs)
                    await $_getPrefetchedData<Tag, Tags, TaskTag>(
                      currentTable: table,
                      referencedTable: $TagsReferences._taskTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $TagsReferences(db, table, p0).taskTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $TagsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Tags,
      Tag,
      $TagsFilterComposer,
      $TagsOrderingComposer,
      $TagsAnnotationComposer,
      $TagsCreateCompanionBuilder,
      $TagsUpdateCompanionBuilder,
      (Tag, $TagsReferences),
      Tag,
      PrefetchHooks Function({bool taskTagsRefs})
    >;
typedef $TaskTagsCreateCompanionBuilder = TaskTagsCompanion Function({
  required String taskId,
  required String tagId,
  Value<int> removed,
  Value<int> rowid,
});
typedef $TaskTagsUpdateCompanionBuilder = TaskTagsCompanion Function({
  Value<String> taskId,
  Value<String> tagId,
  Value<int> removed,
  Value<int> rowid,
});

final class $TaskTagsReferences
    extends BaseReferences<_$AppDatabase, TaskTags, TaskTag> {
  $TaskTagsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Tasks _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_tags__task_id__tasks__id');

  $TasksProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $TasksTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Tags _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('task_tags__tag_id__tags__id');

  $TagsProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $TagsTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TaskTagsFilterComposer extends Composer<_$AppDatabase, TaskTags> {
  $TaskTagsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnFilters(column),
  );

  $TasksFilterComposer get taskId {
    final $TasksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TagsFilterComposer get tagId {
    final $TagsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TagsFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TaskTagsOrderingComposer extends Composer<_$AppDatabase, TaskTags> {
  $TaskTagsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnOrderings(column),
  );

  $TasksOrderingComposer get taskId {
    final $TasksOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TagsOrderingComposer get tagId {
    final $TagsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TagsOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TaskTagsAnnotationComposer extends Composer<_$AppDatabase, TaskTags> {
  $TaskTagsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get removed =>
      $composableBuilder(column: $table.removed, builder: (column) => column);

  $TasksAnnotationComposer get taskId {
    final $TasksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TagsAnnotationComposer get tagId {
    final $TagsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TagsAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TaskTagsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TaskTags,
          TaskTag,
          $TaskTagsFilterComposer,
          $TaskTagsOrderingComposer,
          $TaskTagsAnnotationComposer,
          $TaskTagsCreateCompanionBuilder,
          $TaskTagsUpdateCompanionBuilder,
          (TaskTag, $TaskTagsReferences),
          TaskTag,
          PrefetchHooks Function({bool taskId, bool tagId})
        > {
  $TaskTagsTableManager(_$AppDatabase db, TaskTags table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TaskTagsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TaskTagsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TaskTagsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> removed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion(
                taskId: taskId,
                tagId: tagId,
                removed: removed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String tagId,
                Value<int> removed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion.insert(
                taskId: taskId,
                tagId: tagId,
                removed: removed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TaskTags, TaskTag>(table),
                  $TaskTagsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $TaskTagsReferences._taskIdTable(db),
                        referencedColumn: $TaskTagsReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $TaskTagsReferences._tagIdTable(db),
                        referencedColumn: $TaskTagsReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $TaskTagsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TaskTags,
      TaskTag,
      $TaskTagsFilterComposer,
      $TaskTagsOrderingComposer,
      $TaskTagsAnnotationComposer,
      $TaskTagsCreateCompanionBuilder,
      $TaskTagsUpdateCompanionBuilder,
      (TaskTag, $TaskTagsReferences),
      TaskTag,
      PrefetchHooks Function({bool taskId, bool tagId})
    >;
typedef $MilestonesCreateCompanionBuilder = MilestonesCompanion Function({
  required String id,
  required String taskId,
  required String title,
  required int position,
  Value<int?> completedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $MilestonesUpdateCompanionBuilder = MilestonesCompanion Function({
  Value<String> id,
  Value<String> taskId,
  Value<String> title,
  Value<int> position,
  Value<int?> completedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $MilestonesReferences
    extends BaseReferences<_$AppDatabase, Milestones, Milestone> {
  $MilestonesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Tasks _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('milestones__task_id__tasks__id');

  $TasksProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $TasksTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $MilestonesFilterComposer extends Composer<_$AppDatabase, Milestones> {
  $MilestonesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $TasksFilterComposer get taskId {
    final $TasksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MilestonesOrderingComposer extends Composer<_$AppDatabase, Milestones> {
  $MilestonesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $TasksOrderingComposer get taskId {
    final $TasksOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MilestonesAnnotationComposer
    extends Composer<_$AppDatabase, Milestones> {
  $MilestonesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $TasksAnnotationComposer get taskId {
    final $TasksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MilestonesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Milestones,
          Milestone,
          $MilestonesFilterComposer,
          $MilestonesOrderingComposer,
          $MilestonesAnnotationComposer,
          $MilestonesCreateCompanionBuilder,
          $MilestonesUpdateCompanionBuilder,
          (Milestone, $MilestonesReferences),
          Milestone,
          PrefetchHooks Function({bool taskId})
        > {
  $MilestonesTableManager(_$AppDatabase db, Milestones table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MilestonesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MilestonesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MilestonesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion(
                id: id,
                taskId: taskId,
                title: title,
                position: position,
                completedAt: completedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String title,
                required int position,
                Value<int?> completedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion.insert(
                id: id,
                taskId: taskId,
                title: title,
                position: position,
                completedAt: completedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Milestones, Milestone>(table),
                  $MilestonesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $MilestonesReferences._taskIdTable(db),
                        referencedColumn: $MilestonesReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $MilestonesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Milestones,
      Milestone,
      $MilestonesFilterComposer,
      $MilestonesOrderingComposer,
      $MilestonesAnnotationComposer,
      $MilestonesCreateCompanionBuilder,
      $MilestonesUpdateCompanionBuilder,
      (Milestone, $MilestonesReferences),
      Milestone,
      PrefetchHooks Function({bool taskId})
    >;
typedef $RecurrenceSeriesCreateCompanionBuilder =
    RecurrenceSeriesCompanion Function({
      required String id,
      required String templateJson,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $RecurrenceSeriesUpdateCompanionBuilder =
    RecurrenceSeriesCompanion Function({
      Value<String> id,
      Value<String> templateJson,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $RecurrenceSeriesReferences
    extends BaseReferences<_$AppDatabase, RecurrenceSeries, RecurrenceSery> {
  $RecurrenceSeriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<RecurrenceSegments, List<RecurrenceSegment>>
  _recurrenceSegmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recurrenceSegments,
        aliasName: 'recurrence_series__id__recurrence_segments__series_id',
      );

  $RecurrenceSegmentsProcessedTableManager get recurrenceSegmentsRefs {
    final manager = $RecurrenceSegmentsTableManager(
      $_db,
      $_db.recurrenceSegments,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recurrenceSegmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ReminderRules, List<ReminderRule>>
  _reminderRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminderRules,
    aliasName: 'recurrence_series__id__reminder_rules__series_id',
  );

  $ReminderRulesProcessedTableManager get reminderRulesRefs {
    final manager = $ReminderRulesTableManager(
      $_db,
      $_db.reminderRules,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reminderRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $RecurrenceSeriesFilterComposer
    extends Composer<_$AppDatabase, RecurrenceSeries> {
  $RecurrenceSeriesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recurrenceSegmentsRefs(
    Expression<bool> Function($RecurrenceSegmentsFilterComposer f) f,
  ) {
    final $RecurrenceSegmentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurrenceSegments,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSegmentsFilterComposer(
            $db: $db,
            $table: $db.recurrenceSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reminderRulesRefs(
    Expression<bool> Function($ReminderRulesFilterComposer f) f,
  ) {
    final $ReminderRulesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReminderRulesFilterComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecurrenceSeriesOrderingComposer
    extends Composer<_$AppDatabase, RecurrenceSeries> {
  $RecurrenceSeriesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RecurrenceSeriesAnnotationComposer
    extends Composer<_$AppDatabase, RecurrenceSeries> {
  $RecurrenceSeriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> recurrenceSegmentsRefs<T extends Object>(
    Expression<T> Function($RecurrenceSegmentsAnnotationComposer a) f,
  ) {
    final $RecurrenceSegmentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurrenceSegments,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSegmentsAnnotationComposer(
            $db: $db,
            $table: $db.recurrenceSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reminderRulesRefs<T extends Object>(
    Expression<T> Function($ReminderRulesAnnotationComposer a) f,
  ) {
    final $ReminderRulesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ReminderRulesAnnotationComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecurrenceSeriesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RecurrenceSeries,
          RecurrenceSery,
          $RecurrenceSeriesFilterComposer,
          $RecurrenceSeriesOrderingComposer,
          $RecurrenceSeriesAnnotationComposer,
          $RecurrenceSeriesCreateCompanionBuilder,
          $RecurrenceSeriesUpdateCompanionBuilder,
          (RecurrenceSery, $RecurrenceSeriesReferences),
          RecurrenceSery,
          PrefetchHooks Function({
            bool recurrenceSegmentsRefs,
            bool reminderRulesRefs,
          })
        > {
  $RecurrenceSeriesTableManager(_$AppDatabase db, RecurrenceSeries table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecurrenceSeriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecurrenceSeriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecurrenceSeriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateJson = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrenceSeriesCompanion(
                id: id,
                templateJson: templateJson,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateJson,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrenceSeriesCompanion.insert(
                id: id,
                templateJson: templateJson,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<RecurrenceSeries, RecurrenceSery>(table),
                  $RecurrenceSeriesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({recurrenceSegmentsRefs = false, reminderRulesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recurrenceSegmentsRefs) db.recurrenceSegments,
                    if (reminderRulesRefs) db.reminderRules,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recurrenceSegmentsRefs)
                        await $_getPrefetchedData<
                          RecurrenceSery,
                          RecurrenceSeries,
                          RecurrenceSegment
                        >(
                          currentTable: table,
                          referencedTable: $RecurrenceSeriesReferences
                              ._recurrenceSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $RecurrenceSeriesReferences(
                                db,
                                table,
                                p0,
                              ).recurrenceSegmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reminderRulesRefs)
                        await $_getPrefetchedData<
                          RecurrenceSery,
                          RecurrenceSeries,
                          ReminderRule
                        >(
                          currentTable: table,
                          referencedTable: $RecurrenceSeriesReferences
                              ._reminderRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $RecurrenceSeriesReferences(
                                db,
                                table,
                                p0,
                              ).reminderRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $RecurrenceSeriesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RecurrenceSeries,
      RecurrenceSery,
      $RecurrenceSeriesFilterComposer,
      $RecurrenceSeriesOrderingComposer,
      $RecurrenceSeriesAnnotationComposer,
      $RecurrenceSeriesCreateCompanionBuilder,
      $RecurrenceSeriesUpdateCompanionBuilder,
      (RecurrenceSery, $RecurrenceSeriesReferences),
      RecurrenceSery,
      PrefetchHooks Function({
        bool recurrenceSegmentsRefs,
        bool reminderRulesRefs,
      })
    >;
typedef $RecurrenceSegmentsCreateCompanionBuilder =
    RecurrenceSegmentsCompanion Function({
      required String id,
      required String seriesId,
      required String ruleJson,
      required int engineVersion,
      required String tzdataVersion,
      Value<int?> cutoffOrdinal,
      Value<int> rowid,
    });
typedef $RecurrenceSegmentsUpdateCompanionBuilder =
    RecurrenceSegmentsCompanion Function({
      Value<String> id,
      Value<String> seriesId,
      Value<String> ruleJson,
      Value<int> engineVersion,
      Value<String> tzdataVersion,
      Value<int?> cutoffOrdinal,
      Value<int> rowid,
    });

final class $RecurrenceSegmentsReferences
    extends
        BaseReferences<_$AppDatabase, RecurrenceSegments, RecurrenceSegment> {
  $RecurrenceSegmentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static RecurrenceSeries _seriesIdTable(_$AppDatabase db) => db
      .recurrenceSeries
      .createAlias('recurrence_segments__series_id__recurrence_series__id');

  $RecurrenceSeriesProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $RecurrenceSeriesTableManager(
      $_db,
      $_db.recurrenceSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<OccurrenceState, List<OccurrenceStateData>>
  _occurrenceStateRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.occurrenceState,
    aliasName: 'recurrence_segments__id__occurrence_state__segment_id',
  );

  $OccurrenceStateProcessedTableManager get occurrenceStateRefs {
    final manager = $OccurrenceStateTableManager(
      $_db,
      $_db.occurrenceState,
    ).filter((f) => f.segmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _occurrenceStateRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $RecurrenceSegmentsFilterComposer
    extends Composer<_$AppDatabase, RecurrenceSegments> {
  $RecurrenceSegmentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tzdataVersion => $composableBuilder(
    column: $table.tzdataVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cutoffOrdinal => $composableBuilder(
    column: $table.cutoffOrdinal,
    builder: (column) => ColumnFilters(column),
  );

  $RecurrenceSeriesFilterComposer get seriesId {
    final $RecurrenceSeriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.recurrenceSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSeriesFilterComposer(
            $db: $db,
            $table: $db.recurrenceSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> occurrenceStateRefs(
    Expression<bool> Function($OccurrenceStateFilterComposer f) f,
  ) {
    final $OccurrenceStateFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrenceState,
      getReferencedColumn: (t) => t.segmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OccurrenceStateFilterComposer(
            $db: $db,
            $table: $db.occurrenceState,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecurrenceSegmentsOrderingComposer
    extends Composer<_$AppDatabase, RecurrenceSegments> {
  $RecurrenceSegmentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tzdataVersion => $composableBuilder(
    column: $table.tzdataVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cutoffOrdinal => $composableBuilder(
    column: $table.cutoffOrdinal,
    builder: (column) => ColumnOrderings(column),
  );

  $RecurrenceSeriesOrderingComposer get seriesId {
    final $RecurrenceSeriesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.recurrenceSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSeriesOrderingComposer(
            $db: $db,
            $table: $db.recurrenceSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecurrenceSegmentsAnnotationComposer
    extends Composer<_$AppDatabase, RecurrenceSegments> {
  $RecurrenceSegmentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ruleJson =>
      $composableBuilder(column: $table.ruleJson, builder: (column) => column);

  GeneratedColumn<int> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tzdataVersion => $composableBuilder(
    column: $table.tzdataVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cutoffOrdinal => $composableBuilder(
    column: $table.cutoffOrdinal,
    builder: (column) => column,
  );

  $RecurrenceSeriesAnnotationComposer get seriesId {
    final $RecurrenceSeriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.recurrenceSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSeriesAnnotationComposer(
            $db: $db,
            $table: $db.recurrenceSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> occurrenceStateRefs<T extends Object>(
    Expression<T> Function($OccurrenceStateAnnotationComposer a) f,
  ) {
    final $OccurrenceStateAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrenceState,
      getReferencedColumn: (t) => t.segmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OccurrenceStateAnnotationComposer(
            $db: $db,
            $table: $db.occurrenceState,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecurrenceSegmentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RecurrenceSegments,
          RecurrenceSegment,
          $RecurrenceSegmentsFilterComposer,
          $RecurrenceSegmentsOrderingComposer,
          $RecurrenceSegmentsAnnotationComposer,
          $RecurrenceSegmentsCreateCompanionBuilder,
          $RecurrenceSegmentsUpdateCompanionBuilder,
          (RecurrenceSegment, $RecurrenceSegmentsReferences),
          RecurrenceSegment,
          PrefetchHooks Function({bool seriesId, bool occurrenceStateRefs})
        > {
  $RecurrenceSegmentsTableManager(_$AppDatabase db, RecurrenceSegments table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecurrenceSegmentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecurrenceSegmentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecurrenceSegmentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> ruleJson = const Value.absent(),
                Value<int> engineVersion = const Value.absent(),
                Value<String> tzdataVersion = const Value.absent(),
                Value<int?> cutoffOrdinal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrenceSegmentsCompanion(
                id: id,
                seriesId: seriesId,
                ruleJson: ruleJson,
                engineVersion: engineVersion,
                tzdataVersion: tzdataVersion,
                cutoffOrdinal: cutoffOrdinal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seriesId,
                required String ruleJson,
                required int engineVersion,
                required String tzdataVersion,
                Value<int?> cutoffOrdinal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrenceSegmentsCompanion.insert(
                id: id,
                seriesId: seriesId,
                ruleJson: ruleJson,
                engineVersion: engineVersion,
                tzdataVersion: tzdataVersion,
                cutoffOrdinal: cutoffOrdinal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<RecurrenceSegments, RecurrenceSegment>(table),
                  $RecurrenceSegmentsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({seriesId = false, occurrenceStateRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (occurrenceStateRefs) db.occurrenceState,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (seriesId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.seriesId,
                            referencedTable: $RecurrenceSegmentsReferences
                                ._seriesIdTable(db),
                            referencedColumn: $RecurrenceSegmentsReferences
                                ._seriesIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (occurrenceStateRefs)
                        await $_getPrefetchedData<
                          RecurrenceSegment,
                          RecurrenceSegments,
                          OccurrenceStateData
                        >(
                          currentTable: table,
                          referencedTable: $RecurrenceSegmentsReferences
                              ._occurrenceStateRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $RecurrenceSegmentsReferences(
                                db,
                                table,
                                p0,
                              ).occurrenceStateRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.segmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $RecurrenceSegmentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RecurrenceSegments,
      RecurrenceSegment,
      $RecurrenceSegmentsFilterComposer,
      $RecurrenceSegmentsOrderingComposer,
      $RecurrenceSegmentsAnnotationComposer,
      $RecurrenceSegmentsCreateCompanionBuilder,
      $RecurrenceSegmentsUpdateCompanionBuilder,
      (RecurrenceSegment, $RecurrenceSegmentsReferences),
      RecurrenceSegment,
      PrefetchHooks Function({bool seriesId, bool occurrenceStateRefs})
    >;
typedef $OccurrenceStateCreateCompanionBuilder =
    OccurrenceStateCompanion Function({
      required String id,
      required String segmentId,
      required int ordinal,
      required String originalSlot,
      required String overridesJson,
      Value<String?> skipReason,
      Value<int> rowid,
    });
typedef $OccurrenceStateUpdateCompanionBuilder =
    OccurrenceStateCompanion Function({
      Value<String> id,
      Value<String> segmentId,
      Value<int> ordinal,
      Value<String> originalSlot,
      Value<String> overridesJson,
      Value<String?> skipReason,
      Value<int> rowid,
    });

final class $OccurrenceStateReferences
    extends
        BaseReferences<_$AppDatabase, OccurrenceState, OccurrenceStateData> {
  $OccurrenceStateReferences(super.$_db, super.$_table, super.$_typedResult);

  static RecurrenceSegments _segmentIdTable(_$AppDatabase db) => db
      .recurrenceSegments
      .createAlias('occurrence_state__segment_id__recurrence_segments__id');

  $RecurrenceSegmentsProcessedTableManager get segmentId {
    final $_column = $_itemColumn<String>('segment_id')!;

    final manager = $RecurrenceSegmentsTableManager(
      $_db,
      $_db.recurrenceSegments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_segmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $OccurrenceStateFilterComposer
    extends Composer<_$AppDatabase, OccurrenceState> {
  $OccurrenceStateFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalSlot => $composableBuilder(
    column: $table.originalSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overridesJson => $composableBuilder(
    column: $table.overridesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnFilters(column),
  );

  $RecurrenceSegmentsFilterComposer get segmentId {
    final $RecurrenceSegmentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.recurrenceSegments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSegmentsFilterComposer(
            $db: $db,
            $table: $db.recurrenceSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $OccurrenceStateOrderingComposer
    extends Composer<_$AppDatabase, OccurrenceState> {
  $OccurrenceStateOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalSlot => $composableBuilder(
    column: $table.originalSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overridesJson => $composableBuilder(
    column: $table.overridesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnOrderings(column),
  );

  $RecurrenceSegmentsOrderingComposer get segmentId {
    final $RecurrenceSegmentsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.recurrenceSegments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSegmentsOrderingComposer(
            $db: $db,
            $table: $db.recurrenceSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $OccurrenceStateAnnotationComposer
    extends Composer<_$AppDatabase, OccurrenceState> {
  $OccurrenceStateAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get originalSlot => $composableBuilder(
    column: $table.originalSlot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overridesJson => $composableBuilder(
    column: $table.overridesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => column,
  );

  $RecurrenceSegmentsAnnotationComposer get segmentId {
    final $RecurrenceSegmentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.segmentId,
      referencedTable: $db.recurrenceSegments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSegmentsAnnotationComposer(
            $db: $db,
            $table: $db.recurrenceSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $OccurrenceStateTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          OccurrenceState,
          OccurrenceStateData,
          $OccurrenceStateFilterComposer,
          $OccurrenceStateOrderingComposer,
          $OccurrenceStateAnnotationComposer,
          $OccurrenceStateCreateCompanionBuilder,
          $OccurrenceStateUpdateCompanionBuilder,
          (OccurrenceStateData, $OccurrenceStateReferences),
          OccurrenceStateData,
          PrefetchHooks Function({bool segmentId})
        > {
  $OccurrenceStateTableManager(_$AppDatabase db, OccurrenceState table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OccurrenceStateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OccurrenceStateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OccurrenceStateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> segmentId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> originalSlot = const Value.absent(),
                Value<String> overridesJson = const Value.absent(),
                Value<String?> skipReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceStateCompanion(
                id: id,
                segmentId: segmentId,
                ordinal: ordinal,
                originalSlot: originalSlot,
                overridesJson: overridesJson,
                skipReason: skipReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String segmentId,
                required int ordinal,
                required String originalSlot,
                required String overridesJson,
                Value<String?> skipReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceStateCompanion.insert(
                id: id,
                segmentId: segmentId,
                ordinal: ordinal,
                originalSlot: originalSlot,
                overridesJson: overridesJson,
                skipReason: skipReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<OccurrenceState, OccurrenceStateData>(table),
                  $OccurrenceStateReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({segmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (segmentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.segmentId,
                        referencedTable: $OccurrenceStateReferences
                            ._segmentIdTable(db),
                        referencedColumn: $OccurrenceStateReferences
                            ._segmentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $OccurrenceStateProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      OccurrenceState,
      OccurrenceStateData,
      $OccurrenceStateFilterComposer,
      $OccurrenceStateOrderingComposer,
      $OccurrenceStateAnnotationComposer,
      $OccurrenceStateCreateCompanionBuilder,
      $OccurrenceStateUpdateCompanionBuilder,
      (OccurrenceStateData, $OccurrenceStateReferences),
      OccurrenceStateData,
      PrefetchHooks Function({bool segmentId})
    >;
typedef $ReminderRulesCreateCompanionBuilder = ReminderRulesCompanion Function({
  required String id,
  Value<String?> taskId,
  Value<String?> seriesId,
  required String ruleJson,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $ReminderRulesUpdateCompanionBuilder = ReminderRulesCompanion Function({
  Value<String> id,
  Value<String?> taskId,
  Value<String?> seriesId,
  Value<String> ruleJson,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $ReminderRulesReferences
    extends BaseReferences<_$AppDatabase, ReminderRules, ReminderRule> {
  $ReminderRulesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Tasks _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('reminder_rules__task_id__tasks__id');

  $TasksProcessedTableManager? get taskId {
    final $_column = $_itemColumn<String>('task_id');
    if ($_column == null) return null;
    final manager = $TasksTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static RecurrenceSeries _seriesIdTable(_$AppDatabase db) => db
      .recurrenceSeries
      .createAlias('reminder_rules__series_id__recurrence_series__id');

  $RecurrenceSeriesProcessedTableManager? get seriesId {
    final $_column = $_itemColumn<String>('series_id');
    if ($_column == null) return null;
    final manager = $RecurrenceSeriesTableManager(
      $_db,
      $_db.recurrenceSeries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ReminderRulesFilterComposer
    extends Composer<_$AppDatabase, ReminderRules> {
  $ReminderRulesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $TasksFilterComposer get taskId {
    final $TasksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RecurrenceSeriesFilterComposer get seriesId {
    final $RecurrenceSeriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.recurrenceSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSeriesFilterComposer(
            $db: $db,
            $table: $db.recurrenceSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReminderRulesOrderingComposer
    extends Composer<_$AppDatabase, ReminderRules> {
  $ReminderRulesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $TasksOrderingComposer get taskId {
    final $TasksOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RecurrenceSeriesOrderingComposer get seriesId {
    final $RecurrenceSeriesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.recurrenceSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSeriesOrderingComposer(
            $db: $db,
            $table: $db.recurrenceSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReminderRulesAnnotationComposer
    extends Composer<_$AppDatabase, ReminderRules> {
  $ReminderRulesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ruleJson =>
      $composableBuilder(column: $table.ruleJson, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $TasksAnnotationComposer get taskId {
    final $TasksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RecurrenceSeriesAnnotationComposer get seriesId {
    final $RecurrenceSeriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.recurrenceSeries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecurrenceSeriesAnnotationComposer(
            $db: $db,
            $table: $db.recurrenceSeries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ReminderRulesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ReminderRules,
          ReminderRule,
          $ReminderRulesFilterComposer,
          $ReminderRulesOrderingComposer,
          $ReminderRulesAnnotationComposer,
          $ReminderRulesCreateCompanionBuilder,
          $ReminderRulesUpdateCompanionBuilder,
          (ReminderRule, $ReminderRulesReferences),
          ReminderRule,
          PrefetchHooks Function({bool taskId, bool seriesId})
        > {
  $ReminderRulesTableManager(_$AppDatabase db, ReminderRules table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ReminderRulesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ReminderRulesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ReminderRulesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String> ruleJson = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRulesCompanion(
                id: id,
                taskId: taskId,
                seriesId: seriesId,
                ruleJson: ruleJson,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> taskId = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                required String ruleJson,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRulesCompanion.insert(
                id: id,
                taskId: taskId,
                seriesId: seriesId,
                ruleJson: ruleJson,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ReminderRules, ReminderRule>(table),
                  $ReminderRulesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, seriesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $ReminderRulesReferences._taskIdTable(
                          db,
                        ),
                        referencedColumn: $ReminderRulesReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (seriesId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.seriesId,
                        referencedTable: $ReminderRulesReferences
                            ._seriesIdTable(db),
                        referencedColumn: $ReminderRulesReferences
                            ._seriesIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ReminderRulesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ReminderRules,
      ReminderRule,
      $ReminderRulesFilterComposer,
      $ReminderRulesOrderingComposer,
      $ReminderRulesAnnotationComposer,
      $ReminderRulesCreateCompanionBuilder,
      $ReminderRulesUpdateCompanionBuilder,
      (ReminderRule, $ReminderRulesReferences),
      ReminderRule,
      PrefetchHooks Function({bool taskId, bool seriesId})
    >;
typedef $SnoozesCreateCompanionBuilder = SnoozesCompanion Function({
  required String taskId,
  required int untilInstant,
  required int generation,
  required int suppressedThrough,
  Value<int> rowid,
});
typedef $SnoozesUpdateCompanionBuilder = SnoozesCompanion Function({
  Value<String> taskId,
  Value<int> untilInstant,
  Value<int> generation,
  Value<int> suppressedThrough,
  Value<int> rowid,
});

final class $SnoozesReferences
    extends BaseReferences<_$AppDatabase, Snoozes, Snooze> {
  $SnoozesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Tasks _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('snoozes__task_id__tasks__id');

  $TasksProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $TasksTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SnoozesFilterComposer extends Composer<_$AppDatabase, Snoozes> {
  $SnoozesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get untilInstant => $composableBuilder(
    column: $table.untilInstant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get suppressedThrough => $composableBuilder(
    column: $table.suppressedThrough,
    builder: (column) => ColumnFilters(column),
  );

  $TasksFilterComposer get taskId {
    final $TasksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SnoozesOrderingComposer extends Composer<_$AppDatabase, Snoozes> {
  $SnoozesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get untilInstant => $composableBuilder(
    column: $table.untilInstant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get suppressedThrough => $composableBuilder(
    column: $table.suppressedThrough,
    builder: (column) => ColumnOrderings(column),
  );

  $TasksOrderingComposer get taskId {
    final $TasksOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SnoozesAnnotationComposer extends Composer<_$AppDatabase, Snoozes> {
  $SnoozesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get untilInstant => $composableBuilder(
    column: $table.untilInstant,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get suppressedThrough => $composableBuilder(
    column: $table.suppressedThrough,
    builder: (column) => column,
  );

  $TasksAnnotationComposer get taskId {
    final $TasksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SnoozesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Snoozes,
          Snooze,
          $SnoozesFilterComposer,
          $SnoozesOrderingComposer,
          $SnoozesAnnotationComposer,
          $SnoozesCreateCompanionBuilder,
          $SnoozesUpdateCompanionBuilder,
          (Snooze, $SnoozesReferences),
          Snooze,
          PrefetchHooks Function({bool taskId})
        > {
  $SnoozesTableManager(_$AppDatabase db, Snoozes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SnoozesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SnoozesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SnoozesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<int> untilInstant = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<int> suppressedThrough = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnoozesCompanion(
                taskId: taskId,
                untilInstant: untilInstant,
                generation: generation,
                suppressedThrough: suppressedThrough,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required int untilInstant,
                required int generation,
                required int suppressedThrough,
                Value<int> rowid = const Value.absent(),
              }) => SnoozesCompanion.insert(
                taskId: taskId,
                untilInstant: untilInstant,
                generation: generation,
                suppressedThrough: suppressedThrough,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Snoozes, Snooze>(table),
                  $SnoozesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $SnoozesReferences._taskIdTable(db),
                        referencedColumn: $SnoozesReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $SnoozesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Snoozes,
      Snooze,
      $SnoozesFilterComposer,
      $SnoozesOrderingComposer,
      $SnoozesAnnotationComposer,
      $SnoozesCreateCompanionBuilder,
      $SnoozesUpdateCompanionBuilder,
      (Snooze, $SnoozesReferences),
      Snooze,
      PrefetchHooks Function({bool taskId})
    >;
typedef $SavedViewsCreateCompanionBuilder = SavedViewsCompanion Function({
  required String id,
  required String name,
  required int specVersion,
  required String specJson,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $SavedViewsUpdateCompanionBuilder = SavedViewsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> specVersion,
  Value<String> specJson,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $SavedViewsFilterComposer extends Composer<_$AppDatabase, SavedViews> {
  $SavedViewsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get specVersion => $composableBuilder(
    column: $table.specVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SavedViewsOrderingComposer extends Composer<_$AppDatabase, SavedViews> {
  $SavedViewsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get specVersion => $composableBuilder(
    column: $table.specVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SavedViewsAnnotationComposer
    extends Composer<_$AppDatabase, SavedViews> {
  $SavedViewsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get specVersion => $composableBuilder(
    column: $table.specVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specJson =>
      $composableBuilder(column: $table.specJson, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $SavedViewsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SavedViews,
          SavedView,
          $SavedViewsFilterComposer,
          $SavedViewsOrderingComposer,
          $SavedViewsAnnotationComposer,
          $SavedViewsCreateCompanionBuilder,
          $SavedViewsUpdateCompanionBuilder,
          (SavedView, BaseReferences<_$AppDatabase, SavedViews, SavedView>),
          SavedView,
          PrefetchHooks Function()
        > {
  $SavedViewsTableManager(_$AppDatabase db, SavedViews table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SavedViewsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SavedViewsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SavedViewsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> specVersion = const Value.absent(),
                Value<String> specJson = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedViewsCompanion(
                id: id,
                name: name,
                specVersion: specVersion,
                specJson: specJson,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int specVersion,
                required String specJson,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedViewsCompanion.insert(
                id: id,
                name: name,
                specVersion: specVersion,
                specJson: specJson,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SavedViews, SavedView>(table),
                  BaseReferences<_$AppDatabase, SavedViews, SavedView>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SavedViewsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SavedViews,
      SavedView,
      $SavedViewsFilterComposer,
      $SavedViewsOrderingComposer,
      $SavedViewsAnnotationComposer,
      $SavedViewsCreateCompanionBuilder,
      $SavedViewsUpdateCompanionBuilder,
      (SavedView, BaseReferences<_$AppDatabase, SavedViews, SavedView>),
      SavedView,
      PrefetchHooks Function()
    >;
typedef $SharedPreferencesCreateCompanionBuilder =
    SharedPreferencesCompanion Function({
      required String key,
      required String valueJson,
      Value<int> rowid,
    });
typedef $SharedPreferencesUpdateCompanionBuilder =
    SharedPreferencesCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> rowid,
    });

class $SharedPreferencesFilterComposer
    extends Composer<_$AppDatabase, SharedPreferences> {
  $SharedPreferencesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $SharedPreferencesOrderingComposer
    extends Composer<_$AppDatabase, SharedPreferences> {
  $SharedPreferencesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SharedPreferencesAnnotationComposer
    extends Composer<_$AppDatabase, SharedPreferences> {
  $SharedPreferencesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);
}

class $SharedPreferencesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SharedPreferences,
          SharedPreference,
          $SharedPreferencesFilterComposer,
          $SharedPreferencesOrderingComposer,
          $SharedPreferencesAnnotationComposer,
          $SharedPreferencesCreateCompanionBuilder,
          $SharedPreferencesUpdateCompanionBuilder,
          (
            SharedPreference,
            BaseReferences<_$AppDatabase, SharedPreferences, SharedPreference>,
          ),
          SharedPreference,
          PrefetchHooks Function()
        > {
  $SharedPreferencesTableManager(_$AppDatabase db, SharedPreferences table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SharedPreferencesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SharedPreferencesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SharedPreferencesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SharedPreferencesCompanion(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                Value<int> rowid = const Value.absent(),
              }) => SharedPreferencesCompanion.insert(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SharedPreferences, SharedPreference>(table),
                  BaseReferences<
                    _$AppDatabase,
                    SharedPreferences,
                    SharedPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SharedPreferencesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SharedPreferences,
      SharedPreference,
      $SharedPreferencesFilterComposer,
      $SharedPreferencesOrderingComposer,
      $SharedPreferencesAnnotationComposer,
      $SharedPreferencesCreateCompanionBuilder,
      $SharedPreferencesUpdateCompanionBuilder,
      (
        SharedPreference,
        BaseReferences<_$AppDatabase, SharedPreferences, SharedPreference>,
      ),
      SharedPreference,
      PrefetchHooks Function()
    >;
typedef $DevicePreferencesCreateCompanionBuilder =
    DevicePreferencesCompanion Function({
      required String key,
      required String valueJson,
      Value<int> rowid,
    });
typedef $DevicePreferencesUpdateCompanionBuilder =
    DevicePreferencesCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> rowid,
    });

class $DevicePreferencesFilterComposer
    extends Composer<_$AppDatabase, DevicePreferences> {
  $DevicePreferencesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $DevicePreferencesOrderingComposer
    extends Composer<_$AppDatabase, DevicePreferences> {
  $DevicePreferencesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DevicePreferencesAnnotationComposer
    extends Composer<_$AppDatabase, DevicePreferences> {
  $DevicePreferencesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);
}

class $DevicePreferencesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DevicePreferences,
          DevicePreference,
          $DevicePreferencesFilterComposer,
          $DevicePreferencesOrderingComposer,
          $DevicePreferencesAnnotationComposer,
          $DevicePreferencesCreateCompanionBuilder,
          $DevicePreferencesUpdateCompanionBuilder,
          (
            DevicePreference,
            BaseReferences<_$AppDatabase, DevicePreferences, DevicePreference>,
          ),
          DevicePreference,
          PrefetchHooks Function()
        > {
  $DevicePreferencesTableManager(_$AppDatabase db, DevicePreferences table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DevicePreferencesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DevicePreferencesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DevicePreferencesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicePreferencesCompanion(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                Value<int> rowid = const Value.absent(),
              }) => DevicePreferencesCompanion.insert(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DevicePreferences, DevicePreference>(table),
                  BaseReferences<
                    _$AppDatabase,
                    DevicePreferences,
                    DevicePreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DevicePreferencesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DevicePreferences,
      DevicePreference,
      $DevicePreferencesFilterComposer,
      $DevicePreferencesOrderingComposer,
      $DevicePreferencesAnnotationComposer,
      $DevicePreferencesCreateCompanionBuilder,
      $DevicePreferencesUpdateCompanionBuilder,
      (
        DevicePreference,
        BaseReferences<_$AppDatabase, DevicePreferences, DevicePreference>,
      ),
      DevicePreference,
      PrefetchHooks Function()
    >;
typedef $SyncShadowCreateCompanionBuilder = SyncShadowCompanion Function({
  required String entityId,
  required String valueJson,
  required String versionsJson,
  required int revision,
  Value<int> rowid,
});
typedef $SyncShadowUpdateCompanionBuilder = SyncShadowCompanion Function({
  Value<String> entityId,
  Value<String> valueJson,
  Value<String> versionsJson,
  Value<int> revision,
  Value<int> rowid,
});

class $SyncShadowFilterComposer extends Composer<_$AppDatabase, SyncShadow> {
  $SyncShadowFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionsJson => $composableBuilder(
    column: $table.versionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncShadowOrderingComposer extends Composer<_$AppDatabase, SyncShadow> {
  $SyncShadowOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionsJson => $composableBuilder(
    column: $table.versionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncShadowAnnotationComposer
    extends Composer<_$AppDatabase, SyncShadow> {
  $SyncShadowAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<String> get versionsJson => $composableBuilder(
    column: $table.versionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $SyncShadowTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncShadow,
          SyncShadowData,
          $SyncShadowFilterComposer,
          $SyncShadowOrderingComposer,
          $SyncShadowAnnotationComposer,
          $SyncShadowCreateCompanionBuilder,
          $SyncShadowUpdateCompanionBuilder,
          (
            SyncShadowData,
            BaseReferences<_$AppDatabase, SyncShadow, SyncShadowData>,
          ),
          SyncShadowData,
          PrefetchHooks Function()
        > {
  $SyncShadowTableManager(_$AppDatabase db, SyncShadow table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncShadowFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncShadowOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncShadowAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<String> versionsJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncShadowCompanion(
                entityId: entityId,
                valueJson: valueJson,
                versionsJson: versionsJson,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                required String valueJson,
                required String versionsJson,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => SyncShadowCompanion.insert(
                entityId: entityId,
                valueJson: valueJson,
                versionsJson: versionsJson,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SyncShadow, SyncShadowData>(table),
                  BaseReferences<_$AppDatabase, SyncShadow, SyncShadowData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncShadowProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncShadow,
      SyncShadowData,
      $SyncShadowFilterComposer,
      $SyncShadowOrderingComposer,
      $SyncShadowAnnotationComposer,
      $SyncShadowCreateCompanionBuilder,
      $SyncShadowUpdateCompanionBuilder,
      (
        SyncShadowData,
        BaseReferences<_$AppDatabase, SyncShadow, SyncShadowData>,
      ),
      SyncShadowData,
      PrefetchHooks Function()
    >;
typedef $OutboxCreateCompanionBuilder = OutboxCompanion Function({
  required String operationId,
  required int sequence,
  required String entityId,
  required String envelopeJson,
  Value<String> state,
  Value<int> attempts,
  Value<int?> retryAt,
  required int createdAt,
  Value<int> rowid,
});
typedef $OutboxUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> operationId,
  Value<int> sequence,
  Value<String> entityId,
  Value<String> envelopeJson,
  Value<String> state,
  Value<int> attempts,
  Value<int?> retryAt,
  Value<int> createdAt,
  Value<int> rowid,
});

class $OutboxFilterComposer extends Composer<_$AppDatabase, Outbox> {
  $OutboxFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envelopeJson => $composableBuilder(
    column: $table.envelopeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryAt => $composableBuilder(
    column: $table.retryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $OutboxOrderingComposer extends Composer<_$AppDatabase, Outbox> {
  $OutboxOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envelopeJson => $composableBuilder(
    column: $table.envelopeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryAt => $composableBuilder(
    column: $table.retryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OutboxAnnotationComposer extends Composer<_$AppDatabase, Outbox> {
  $OutboxAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get envelopeJson => $composableBuilder(
    column: $table.envelopeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get retryAt =>
      $composableBuilder(column: $table.retryAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $OutboxTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Outbox,
          OutboxData,
          $OutboxFilterComposer,
          $OutboxOrderingComposer,
          $OutboxAnnotationComposer,
          $OutboxCreateCompanionBuilder,
          $OutboxUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, Outbox, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $OutboxTableManager(_$AppDatabase db, Outbox table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OutboxFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OutboxOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OutboxAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> envelopeJson = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> retryAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                operationId: operationId,
                sequence: sequence,
                entityId: entityId,
                envelopeJson: envelopeJson,
                state: state,
                attempts: attempts,
                retryAt: retryAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required int sequence,
                required String entityId,
                required String envelopeJson,
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> retryAt = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                operationId: operationId,
                sequence: sequence,
                entityId: entityId,
                envelopeJson: envelopeJson,
                state: state,
                attempts: attempts,
                retryAt: retryAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Outbox, OutboxData>(table),
                  BaseReferences<_$AppDatabase, Outbox, OutboxData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $OutboxProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Outbox,
      OutboxData,
      $OutboxFilterComposer,
      $OutboxOrderingComposer,
      $OutboxAnnotationComposer,
      $OutboxCreateCompanionBuilder,
      $OutboxUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, Outbox, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $SyncCheckpointCreateCompanionBuilder =
    SyncCheckpointCompanion Function({
      Value<int> singleton,
      Value<String?> serverEpoch,
      Value<int> cursor,
      Value<String?> bootstrapToken,
      Value<int?> bootstrapPage,
      Value<int?> lastSuccess,
    });
typedef $SyncCheckpointUpdateCompanionBuilder =
    SyncCheckpointCompanion Function({
      Value<int> singleton,
      Value<String?> serverEpoch,
      Value<int> cursor,
      Value<String?> bootstrapToken,
      Value<int?> bootstrapPage,
      Value<int?> lastSuccess,
    });

class $SyncCheckpointFilterComposer
    extends Composer<_$AppDatabase, SyncCheckpoint> {
  $SyncCheckpointFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverEpoch => $composableBuilder(
    column: $table.serverEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bootstrapToken => $composableBuilder(
    column: $table.bootstrapToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bootstrapPage => $composableBuilder(
    column: $table.bootstrapPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSuccess => $composableBuilder(
    column: $table.lastSuccess,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncCheckpointOrderingComposer
    extends Composer<_$AppDatabase, SyncCheckpoint> {
  $SyncCheckpointOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverEpoch => $composableBuilder(
    column: $table.serverEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bootstrapToken => $composableBuilder(
    column: $table.bootstrapToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bootstrapPage => $composableBuilder(
    column: $table.bootstrapPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSuccess => $composableBuilder(
    column: $table.lastSuccess,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncCheckpointAnnotationComposer
    extends Composer<_$AppDatabase, SyncCheckpoint> {
  $SyncCheckpointAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singleton =>
      $composableBuilder(column: $table.singleton, builder: (column) => column);

  GeneratedColumn<String> get serverEpoch => $composableBuilder(
    column: $table.serverEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<String> get bootstrapToken => $composableBuilder(
    column: $table.bootstrapToken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bootstrapPage => $composableBuilder(
    column: $table.bootstrapPage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSuccess => $composableBuilder(
    column: $table.lastSuccess,
    builder: (column) => column,
  );
}

class $SyncCheckpointTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncCheckpoint,
          SyncCheckpointData,
          $SyncCheckpointFilterComposer,
          $SyncCheckpointOrderingComposer,
          $SyncCheckpointAnnotationComposer,
          $SyncCheckpointCreateCompanionBuilder,
          $SyncCheckpointUpdateCompanionBuilder,
          (
            SyncCheckpointData,
            BaseReferences<_$AppDatabase, SyncCheckpoint, SyncCheckpointData>,
          ),
          SyncCheckpointData,
          PrefetchHooks Function()
        > {
  $SyncCheckpointTableManager(_$AppDatabase db, SyncCheckpoint table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncCheckpointFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncCheckpointOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncCheckpointAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                Value<String?> serverEpoch = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<String?> bootstrapToken = const Value.absent(),
                Value<int?> bootstrapPage = const Value.absent(),
                Value<int?> lastSuccess = const Value.absent(),
              }) => SyncCheckpointCompanion(
                singleton: singleton,
                serverEpoch: serverEpoch,
                cursor: cursor,
                bootstrapToken: bootstrapToken,
                bootstrapPage: bootstrapPage,
                lastSuccess: lastSuccess,
              ),
          createCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                Value<String?> serverEpoch = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<String?> bootstrapToken = const Value.absent(),
                Value<int?> bootstrapPage = const Value.absent(),
                Value<int?> lastSuccess = const Value.absent(),
              }) => SyncCheckpointCompanion.insert(
                singleton: singleton,
                serverEpoch: serverEpoch,
                cursor: cursor,
                bootstrapToken: bootstrapToken,
                bootstrapPage: bootstrapPage,
                lastSuccess: lastSuccess,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SyncCheckpoint, SyncCheckpointData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    SyncCheckpoint,
                    SyncCheckpointData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncCheckpointProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncCheckpoint,
      SyncCheckpointData,
      $SyncCheckpointFilterComposer,
      $SyncCheckpointOrderingComposer,
      $SyncCheckpointAnnotationComposer,
      $SyncCheckpointCreateCompanionBuilder,
      $SyncCheckpointUpdateCompanionBuilder,
      (
        SyncCheckpointData,
        BaseReferences<_$AppDatabase, SyncCheckpoint, SyncCheckpointData>,
      ),
      SyncCheckpointData,
      PrefetchHooks Function()
    >;
typedef $ConflictsCreateCompanionBuilder = ConflictsCompanion Function({
  required String id,
  required String entityId,
  required String baseJson,
  required String localJson,
  required String serverJson,
  Value<int?> resolvedAt,
  Value<int> rowid,
});
typedef $ConflictsUpdateCompanionBuilder = ConflictsCompanion Function({
  Value<String> id,
  Value<String> entityId,
  Value<String> baseJson,
  Value<String> localJson,
  Value<String> serverJson,
  Value<int?> resolvedAt,
  Value<int> rowid,
});

class $ConflictsFilterComposer extends Composer<_$AppDatabase, Conflicts> {
  $ConflictsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseJson => $composableBuilder(
    column: $table.baseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localJson => $composableBuilder(
    column: $table.localJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $ConflictsOrderingComposer extends Composer<_$AppDatabase, Conflicts> {
  $ConflictsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseJson => $composableBuilder(
    column: $table.baseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localJson => $composableBuilder(
    column: $table.localJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ConflictsAnnotationComposer extends Composer<_$AppDatabase, Conflicts> {
  $ConflictsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get baseJson =>
      $composableBuilder(column: $table.baseJson, builder: (column) => column);

  GeneratedColumn<String> get localJson =>
      $composableBuilder(column: $table.localJson, builder: (column) => column);

  GeneratedColumn<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $ConflictsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Conflicts,
          Conflict,
          $ConflictsFilterComposer,
          $ConflictsOrderingComposer,
          $ConflictsAnnotationComposer,
          $ConflictsCreateCompanionBuilder,
          $ConflictsUpdateCompanionBuilder,
          (Conflict, BaseReferences<_$AppDatabase, Conflicts, Conflict>),
          Conflict,
          PrefetchHooks Function()
        > {
  $ConflictsTableManager(_$AppDatabase db, Conflicts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ConflictsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ConflictsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ConflictsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> baseJson = const Value.absent(),
                Value<String> localJson = const Value.absent(),
                Value<String> serverJson = const Value.absent(),
                Value<int?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion(
                id: id,
                entityId: entityId,
                baseJson: baseJson,
                localJson: localJson,
                serverJson: serverJson,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityId,
                required String baseJson,
                required String localJson,
                required String serverJson,
                Value<int?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictsCompanion.insert(
                id: id,
                entityId: entityId,
                baseJson: baseJson,
                localJson: localJson,
                serverJson: serverJson,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Conflicts, Conflict>(table),
                  BaseReferences<_$AppDatabase, Conflicts, Conflict>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ConflictsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Conflicts,
      Conflict,
      $ConflictsFilterComposer,
      $ConflictsOrderingComposer,
      $ConflictsAnnotationComposer,
      $ConflictsCreateCompanionBuilder,
      $ConflictsUpdateCompanionBuilder,
      (Conflict, BaseReferences<_$AppDatabase, Conflicts, Conflict>),
      Conflict,
      PrefetchHooks Function()
    >;
typedef $HistoryCreateCompanionBuilder = HistoryCompanion Function({
  required String id,
  required String entityId,
  required String operationId,
  required String kind,
  required int occurredAt,
  required String detailJson,
  Value<int> rowid,
});
typedef $HistoryUpdateCompanionBuilder = HistoryCompanion Function({
  Value<String> id,
  Value<String> entityId,
  Value<String> operationId,
  Value<String> kind,
  Value<int> occurredAt,
  Value<String> detailJson,
  Value<int> rowid,
});

class $HistoryFilterComposer extends Composer<_$AppDatabase, History> {
  $HistoryFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $HistoryOrderingComposer extends Composer<_$AppDatabase, History> {
  $HistoryOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $HistoryAnnotationComposer extends Composer<_$AppDatabase, History> {
  $HistoryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );
}

class $HistoryTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          History,
          HistoryData,
          $HistoryFilterComposer,
          $HistoryOrderingComposer,
          $HistoryAnnotationComposer,
          $HistoryCreateCompanionBuilder,
          $HistoryUpdateCompanionBuilder,
          (HistoryData, BaseReferences<_$AppDatabase, History, HistoryData>),
          HistoryData,
          PrefetchHooks Function()
        > {
  $HistoryTableManager(_$AppDatabase db, History table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $HistoryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $HistoryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $HistoryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<String> detailJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion(
                id: id,
                entityId: entityId,
                operationId: operationId,
                kind: kind,
                occurredAt: occurredAt,
                detailJson: detailJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityId,
                required String operationId,
                required String kind,
                required int occurredAt,
                required String detailJson,
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion.insert(
                id: id,
                entityId: entityId,
                operationId: operationId,
                kind: kind,
                occurredAt: occurredAt,
                detailJson: detailJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<History, HistoryData>(table),
                  BaseReferences<_$AppDatabase, History, HistoryData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $HistoryProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      History,
      HistoryData,
      $HistoryFilterComposer,
      $HistoryOrderingComposer,
      $HistoryAnnotationComposer,
      $HistoryCreateCompanionBuilder,
      $HistoryUpdateCompanionBuilder,
      (HistoryData, BaseReferences<_$AppDatabase, History, HistoryData>),
      HistoryData,
      PrefetchHooks Function()
    >;
typedef $TombstonesCreateCompanionBuilder = TombstonesCompanion Function({
  required String entityId,
  required String entityKind,
  Value<int?> revision,
  required int deletedAt,
  Value<int> rowid,
});
typedef $TombstonesUpdateCompanionBuilder = TombstonesCompanion Function({
  Value<String> entityId,
  Value<String> entityKind,
  Value<int?> revision,
  Value<int> deletedAt,
  Value<int> rowid,
});

class $TombstonesFilterComposer extends Composer<_$AppDatabase, Tombstones> {
  $TombstonesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $TombstonesOrderingComposer extends Composer<_$AppDatabase, Tombstones> {
  $TombstonesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TombstonesAnnotationComposer
    extends Composer<_$AppDatabase, Tombstones> {
  $TombstonesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $TombstonesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Tombstones,
          Tombstone,
          $TombstonesFilterComposer,
          $TombstonesOrderingComposer,
          $TombstonesAnnotationComposer,
          $TombstonesCreateCompanionBuilder,
          $TombstonesUpdateCompanionBuilder,
          (Tombstone, BaseReferences<_$AppDatabase, Tombstones, Tombstone>),
          Tombstone,
          PrefetchHooks Function()
        > {
  $TombstonesTableManager(_$AppDatabase db, Tombstones table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TombstonesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TombstonesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TombstonesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<String> entityKind = const Value.absent(),
                Value<int?> revision = const Value.absent(),
                Value<int> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion(
                entityId: entityId,
                entityKind: entityKind,
                revision: revision,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                required String entityKind,
                Value<int?> revision = const Value.absent(),
                required int deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion.insert(
                entityId: entityId,
                entityKind: entityKind,
                revision: revision,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Tombstones, Tombstone>(table),
                  BaseReferences<_$AppDatabase, Tombstones, Tombstone>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TombstonesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Tombstones,
      Tombstone,
      $TombstonesFilterComposer,
      $TombstonesOrderingComposer,
      $TombstonesAnnotationComposer,
      $TombstonesCreateCompanionBuilder,
      $TombstonesUpdateCompanionBuilder,
      (Tombstone, BaseReferences<_$AppDatabase, Tombstones, Tombstone>),
      Tombstone,
      PrefetchHooks Function()
    >;
typedef $NotificationDirtyCreateCompanionBuilder =
    NotificationDirtyCompanion Function({
      required String entityId,
      Value<int> generation,
      Value<int> rowid,
    });
typedef $NotificationDirtyUpdateCompanionBuilder =
    NotificationDirtyCompanion Function({
      Value<String> entityId,
      Value<int> generation,
      Value<int> rowid,
    });

class $NotificationDirtyFilterComposer
    extends Composer<_$AppDatabase, NotificationDirty> {
  $NotificationDirtyFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );
}

class $NotificationDirtyOrderingComposer
    extends Composer<_$AppDatabase, NotificationDirty> {
  $NotificationDirtyOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $NotificationDirtyAnnotationComposer
    extends Composer<_$AppDatabase, NotificationDirty> {
  $NotificationDirtyAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );
}

class $NotificationDirtyTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          NotificationDirty,
          NotificationDirtyData,
          $NotificationDirtyFilterComposer,
          $NotificationDirtyOrderingComposer,
          $NotificationDirtyAnnotationComposer,
          $NotificationDirtyCreateCompanionBuilder,
          $NotificationDirtyUpdateCompanionBuilder,
          (
            NotificationDirtyData,
            BaseReferences<
              _$AppDatabase,
              NotificationDirty,
              NotificationDirtyData
            >,
          ),
          NotificationDirtyData,
          PrefetchHooks Function()
        > {
  $NotificationDirtyTableManager(_$AppDatabase db, NotificationDirty table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $NotificationDirtyFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $NotificationDirtyOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $NotificationDirtyAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationDirtyCompanion(
                entityId: entityId,
                generation: generation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                Value<int> generation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationDirtyCompanion.insert(
                entityId: entityId,
                generation: generation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<NotificationDirty, NotificationDirtyData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    NotificationDirty,
                    NotificationDirtyData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $NotificationDirtyProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      NotificationDirty,
      NotificationDirtyData,
      $NotificationDirtyFilterComposer,
      $NotificationDirtyOrderingComposer,
      $NotificationDirtyAnnotationComposer,
      $NotificationDirtyCreateCompanionBuilder,
      $NotificationDirtyUpdateCompanionBuilder,
      (
        NotificationDirtyData,
        BaseReferences<_$AppDatabase, NotificationDirty, NotificationDirtyData>,
      ),
      NotificationDirtyData,
      PrefetchHooks Function()
    >;
typedef $DeviceNotificationsCreateCompanionBuilder =
    DeviceNotificationsCompanion Function({
      required String logicalKey,
      required int osId,
      required int scheduledAt,
      required int generation,
      required String fingerprint,
      required String registrationState,
      Value<int> rowid,
    });
typedef $DeviceNotificationsUpdateCompanionBuilder =
    DeviceNotificationsCompanion Function({
      Value<String> logicalKey,
      Value<int> osId,
      Value<int> scheduledAt,
      Value<int> generation,
      Value<String> fingerprint,
      Value<String> registrationState,
      Value<int> rowid,
    });

class $DeviceNotificationsFilterComposer
    extends Composer<_$AppDatabase, DeviceNotifications> {
  $DeviceNotificationsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get osId => $composableBuilder(
    column: $table.osId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationState => $composableBuilder(
    column: $table.registrationState,
    builder: (column) => ColumnFilters(column),
  );
}

class $DeviceNotificationsOrderingComposer
    extends Composer<_$AppDatabase, DeviceNotifications> {
  $DeviceNotificationsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get osId => $composableBuilder(
    column: $table.osId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationState => $composableBuilder(
    column: $table.registrationState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DeviceNotificationsAnnotationComposer
    extends Composer<_$AppDatabase, DeviceNotifications> {
  $DeviceNotificationsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get osId =>
      $composableBuilder(column: $table.osId, builder: (column) => column);

  GeneratedColumn<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get registrationState => $composableBuilder(
    column: $table.registrationState,
    builder: (column) => column,
  );
}

class $DeviceNotificationsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DeviceNotifications,
          DeviceNotification,
          $DeviceNotificationsFilterComposer,
          $DeviceNotificationsOrderingComposer,
          $DeviceNotificationsAnnotationComposer,
          $DeviceNotificationsCreateCompanionBuilder,
          $DeviceNotificationsUpdateCompanionBuilder,
          (
            DeviceNotification,
            BaseReferences<
              _$AppDatabase,
              DeviceNotifications,
              DeviceNotification
            >,
          ),
          DeviceNotification,
          PrefetchHooks Function()
        > {
  $DeviceNotificationsTableManager(_$AppDatabase db, DeviceNotifications table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DeviceNotificationsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DeviceNotificationsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DeviceNotificationsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> logicalKey = const Value.absent(),
                Value<int> osId = const Value.absent(),
                Value<int> scheduledAt = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String> registrationState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceNotificationsCompanion(
                logicalKey: logicalKey,
                osId: osId,
                scheduledAt: scheduledAt,
                generation: generation,
                fingerprint: fingerprint,
                registrationState: registrationState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String logicalKey,
                required int osId,
                required int scheduledAt,
                required int generation,
                required String fingerprint,
                required String registrationState,
                Value<int> rowid = const Value.absent(),
              }) => DeviceNotificationsCompanion.insert(
                logicalKey: logicalKey,
                osId: osId,
                scheduledAt: scheduledAt,
                generation: generation,
                fingerprint: fingerprint,
                registrationState: registrationState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DeviceNotifications, DeviceNotification>(table),
                  BaseReferences<
                    _$AppDatabase,
                    DeviceNotifications,
                    DeviceNotification
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DeviceNotificationsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DeviceNotifications,
      DeviceNotification,
      $DeviceNotificationsFilterComposer,
      $DeviceNotificationsOrderingComposer,
      $DeviceNotificationsAnnotationComposer,
      $DeviceNotificationsCreateCompanionBuilder,
      $DeviceNotificationsUpdateCompanionBuilder,
      (
        DeviceNotification,
        BaseReferences<_$AppDatabase, DeviceNotifications, DeviceNotification>,
      ),
      DeviceNotification,
      PrefetchHooks Function()
    >;
typedef $ImportJournalCreateCompanionBuilder = ImportJournalCompanion Function({
  required String sourceLineage,
  required String sourceId,
  required String destinationId,
  required String batchId,
  required String state,
  Value<int> rowid,
});
typedef $ImportJournalUpdateCompanionBuilder = ImportJournalCompanion Function({
  Value<String> sourceLineage,
  Value<String> sourceId,
  Value<String> destinationId,
  Value<String> batchId,
  Value<String> state,
  Value<int> rowid,
});

class $ImportJournalFilterComposer
    extends Composer<_$AppDatabase, ImportJournal> {
  $ImportJournalFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceLineage => $composableBuilder(
    column: $table.sourceLineage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationId => $composableBuilder(
    column: $table.destinationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $ImportJournalOrderingComposer
    extends Composer<_$AppDatabase, ImportJournal> {
  $ImportJournalOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceLineage => $composableBuilder(
    column: $table.sourceLineage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationId => $composableBuilder(
    column: $table.destinationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ImportJournalAnnotationComposer
    extends Composer<_$AppDatabase, ImportJournal> {
  $ImportJournalAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceLineage => $composableBuilder(
    column: $table.sourceLineage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get destinationId => $composableBuilder(
    column: $table.destinationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $ImportJournalTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ImportJournal,
          ImportJournalData,
          $ImportJournalFilterComposer,
          $ImportJournalOrderingComposer,
          $ImportJournalAnnotationComposer,
          $ImportJournalCreateCompanionBuilder,
          $ImportJournalUpdateCompanionBuilder,
          (
            ImportJournalData,
            BaseReferences<_$AppDatabase, ImportJournal, ImportJournalData>,
          ),
          ImportJournalData,
          PrefetchHooks Function()
        > {
  $ImportJournalTableManager(_$AppDatabase db, ImportJournal table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ImportJournalFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ImportJournalOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ImportJournalAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceLineage = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> destinationId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJournalCompanion(
                sourceLineage: sourceLineage,
                sourceId: sourceId,
                destinationId: destinationId,
                batchId: batchId,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceLineage,
                required String sourceId,
                required String destinationId,
                required String batchId,
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => ImportJournalCompanion.insert(
                sourceLineage: sourceLineage,
                sourceId: sourceId,
                destinationId: destinationId,
                batchId: batchId,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ImportJournal, ImportJournalData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    ImportJournal,
                    ImportJournalData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ImportJournalProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ImportJournal,
      ImportJournalData,
      $ImportJournalFilterComposer,
      $ImportJournalOrderingComposer,
      $ImportJournalAnnotationComposer,
      $ImportJournalCreateCompanionBuilder,
      $ImportJournalUpdateCompanionBuilder,
      (
        ImportJournalData,
        BaseReferences<_$AppDatabase, ImportJournal, ImportJournalData>,
      ),
      ImportJournalData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $ProfileMetadataTableManager get profileMetadata =>
      $ProfileMetadataTableManager(_db, _db.profileMetadata);
  $TasksTableManager get tasks => $TasksTableManager(_db, _db.tasks);
  $TagsTableManager get tags => $TagsTableManager(_db, _db.tags);
  $TaskTagsTableManager get taskTags =>
      $TaskTagsTableManager(_db, _db.taskTags);
  $MilestonesTableManager get milestones =>
      $MilestonesTableManager(_db, _db.milestones);
  $RecurrenceSeriesTableManager get recurrenceSeries =>
      $RecurrenceSeriesTableManager(_db, _db.recurrenceSeries);
  $RecurrenceSegmentsTableManager get recurrenceSegments =>
      $RecurrenceSegmentsTableManager(_db, _db.recurrenceSegments);
  $OccurrenceStateTableManager get occurrenceState =>
      $OccurrenceStateTableManager(_db, _db.occurrenceState);
  $ReminderRulesTableManager get reminderRules =>
      $ReminderRulesTableManager(_db, _db.reminderRules);
  $SnoozesTableManager get snoozes => $SnoozesTableManager(_db, _db.snoozes);
  $SavedViewsTableManager get savedViews =>
      $SavedViewsTableManager(_db, _db.savedViews);
  $SharedPreferencesTableManager get sharedPreferences =>
      $SharedPreferencesTableManager(_db, _db.sharedPreferences);
  $DevicePreferencesTableManager get devicePreferences =>
      $DevicePreferencesTableManager(_db, _db.devicePreferences);
  $SyncShadowTableManager get syncShadow =>
      $SyncShadowTableManager(_db, _db.syncShadow);
  $OutboxTableManager get outbox => $OutboxTableManager(_db, _db.outbox);
  $SyncCheckpointTableManager get syncCheckpoint =>
      $SyncCheckpointTableManager(_db, _db.syncCheckpoint);
  $ConflictsTableManager get conflicts =>
      $ConflictsTableManager(_db, _db.conflicts);
  $HistoryTableManager get history => $HistoryTableManager(_db, _db.history);
  $TombstonesTableManager get tombstones =>
      $TombstonesTableManager(_db, _db.tombstones);
  $NotificationDirtyTableManager get notificationDirty =>
      $NotificationDirtyTableManager(_db, _db.notificationDirty);
  $DeviceNotificationsTableManager get deviceNotifications =>
      $DeviceNotificationsTableManager(_db, _db.deviceNotifications);
  $ImportJournalTableManager get importJournal =>
      $ImportJournalTableManager(_db, _db.importJournal);
}
