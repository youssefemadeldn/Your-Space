// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PersonsTableTable extends PersonsTable
    with TableInfo<$PersonsTableTable, PersonsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumber2Meta = const VerificationMeta(
    'phoneNumber2',
  );
  @override
  late final GeneratedColumn<String> phoneNumber2 = GeneratedColumn<String>(
    'phone_number2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subGroupIdMeta = const VerificationMeta(
    'subGroupId',
  );
  @override
  late final GeneratedColumn<int> subGroupId = GeneratedColumn<int>(
    'sub_group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subGroupNameMeta = const VerificationMeta(
    'subGroupName',
  );
  @override
  late final GeneratedColumn<String> subGroupName = GeneratedColumn<String>(
    'sub_group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _governorateIdMeta = const VerificationMeta(
    'governorateId',
  );
  @override
  late final GeneratedColumn<int> governorateId = GeneratedColumn<int>(
    'governorate_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _governorateNameMeta = const VerificationMeta(
    'governorateName',
  );
  @override
  late final GeneratedColumn<String> governorateName = GeneratedColumn<String>(
    'governorate_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<int> cityId = GeneratedColumn<int>(
    'city_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityNameMeta = const VerificationMeta(
    'cityName',
  );
  @override
  late final GeneratedColumn<String> cityName = GeneratedColumn<String>(
    'city_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neighborhoodIdMeta = const VerificationMeta(
    'neighborhoodId',
  );
  @override
  late final GeneratedColumn<int> neighborhoodId = GeneratedColumn<int>(
    'neighborhood_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neighborhoodNameMeta = const VerificationMeta(
    'neighborhoodName',
  );
  @override
  late final GeneratedColumn<String> neighborhoodName = GeneratedColumn<String>(
    'neighborhood_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryPhotoUrlMeta = const VerificationMeta(
    'primaryPhotoUrl',
  );
  @override
  late final GeneratedColumn<String> primaryPhotoUrl = GeneratedColumn<String>(
    'primary_photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasReciprocityHistoryMeta =
      const VerificationMeta('hasReciprocityHistory');
  @override
  late final GeneratedColumn<bool> hasReciprocityHistory =
      GeneratedColumn<bool>(
        'has_reciprocity_history',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_reciprocity_history" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phoneNumber,
    phoneNumber2,
    gender,
    groupId,
    groupName,
    subGroupId,
    subGroupName,
    governorateId,
    governorateName,
    cityId,
    cityName,
    neighborhoodId,
    neighborhoodName,
    primaryPhotoUrl,
    notes,
    hasReciprocityHistory,
    updatedAt,
    isDeleted,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('phone_number2')) {
      context.handle(
        _phoneNumber2Meta,
        phoneNumber2.isAcceptableOrUnknown(
          data['phone_number2']!,
          _phoneNumber2Meta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_groupNameMeta);
    }
    if (data.containsKey('sub_group_id')) {
      context.handle(
        _subGroupIdMeta,
        subGroupId.isAcceptableOrUnknown(
          data['sub_group_id']!,
          _subGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('sub_group_name')) {
      context.handle(
        _subGroupNameMeta,
        subGroupName.isAcceptableOrUnknown(
          data['sub_group_name']!,
          _subGroupNameMeta,
        ),
      );
    }
    if (data.containsKey('governorate_id')) {
      context.handle(
        _governorateIdMeta,
        governorateId.isAcceptableOrUnknown(
          data['governorate_id']!,
          _governorateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_governorateIdMeta);
    }
    if (data.containsKey('governorate_name')) {
      context.handle(
        _governorateNameMeta,
        governorateName.isAcceptableOrUnknown(
          data['governorate_name']!,
          _governorateNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_governorateNameMeta);
    }
    if (data.containsKey('city_id')) {
      context.handle(
        _cityIdMeta,
        cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta),
      );
    }
    if (data.containsKey('city_name')) {
      context.handle(
        _cityNameMeta,
        cityName.isAcceptableOrUnknown(data['city_name']!, _cityNameMeta),
      );
    }
    if (data.containsKey('neighborhood_id')) {
      context.handle(
        _neighborhoodIdMeta,
        neighborhoodId.isAcceptableOrUnknown(
          data['neighborhood_id']!,
          _neighborhoodIdMeta,
        ),
      );
    }
    if (data.containsKey('neighborhood_name')) {
      context.handle(
        _neighborhoodNameMeta,
        neighborhoodName.isAcceptableOrUnknown(
          data['neighborhood_name']!,
          _neighborhoodNameMeta,
        ),
      );
    }
    if (data.containsKey('primary_photo_url')) {
      context.handle(
        _primaryPhotoUrlMeta,
        primaryPhotoUrl.isAcceptableOrUnknown(
          data['primary_photo_url']!,
          _primaryPhotoUrlMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('has_reciprocity_history')) {
      context.handle(
        _hasReciprocityHistoryMeta,
        hasReciprocityHistory.isAcceptableOrUnknown(
          data['has_reciprocity_history']!,
          _hasReciprocityHistoryMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      phoneNumber2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number2'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      )!,
      subGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_group_id'],
      ),
      subGroupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_group_name'],
      ),
      governorateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}governorate_id'],
      )!,
      governorateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}governorate_name'],
      )!,
      cityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}city_id'],
      ),
      cityName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city_name'],
      ),
      neighborhoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}neighborhood_id'],
      ),
      neighborhoodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}neighborhood_name'],
      ),
      primaryPhotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_photo_url'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      hasReciprocityHistory: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_reciprocity_history'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $PersonsTableTable createAlias(String alias) {
    return $PersonsTableTable(attachedDatabase, alias);
  }
}

class PersonsTableData extends DataClass
    implements Insertable<PersonsTableData> {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? phoneNumber2;
  final String gender;
  final int groupId;
  final String groupName;
  final int? subGroupId;
  final String? subGroupName;
  final int governorateId;
  final String governorateName;
  final int? cityId;
  final String? cityName;
  final int? neighborhoodId;
  final String? neighborhoodName;
  final String? primaryPhotoUrl;
  final String? notes;
  final bool hasReciprocityHistory;
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isDirty;
  const PersonsTableData({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.phoneNumber2,
    required this.gender,
    required this.groupId,
    required this.groupName,
    this.subGroupId,
    this.subGroupName,
    required this.governorateId,
    required this.governorateName,
    this.cityId,
    this.cityName,
    this.neighborhoodId,
    this.neighborhoodName,
    this.primaryPhotoUrl,
    this.notes,
    required this.hasReciprocityHistory,
    this.updatedAt,
    required this.isDeleted,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || phoneNumber2 != null) {
      map['phone_number2'] = Variable<String>(phoneNumber2);
    }
    map['gender'] = Variable<String>(gender);
    map['group_id'] = Variable<int>(groupId);
    map['group_name'] = Variable<String>(groupName);
    if (!nullToAbsent || subGroupId != null) {
      map['sub_group_id'] = Variable<int>(subGroupId);
    }
    if (!nullToAbsent || subGroupName != null) {
      map['sub_group_name'] = Variable<String>(subGroupName);
    }
    map['governorate_id'] = Variable<int>(governorateId);
    map['governorate_name'] = Variable<String>(governorateName);
    if (!nullToAbsent || cityId != null) {
      map['city_id'] = Variable<int>(cityId);
    }
    if (!nullToAbsent || cityName != null) {
      map['city_name'] = Variable<String>(cityName);
    }
    if (!nullToAbsent || neighborhoodId != null) {
      map['neighborhood_id'] = Variable<int>(neighborhoodId);
    }
    if (!nullToAbsent || neighborhoodName != null) {
      map['neighborhood_name'] = Variable<String>(neighborhoodName);
    }
    if (!nullToAbsent || primaryPhotoUrl != null) {
      map['primary_photo_url'] = Variable<String>(primaryPhotoUrl);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['has_reciprocity_history'] = Variable<bool>(hasReciprocityHistory);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  PersonsTableCompanion toCompanion(bool nullToAbsent) {
    return PersonsTableCompanion(
      id: Value(id),
      name: Value(name),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      phoneNumber2: phoneNumber2 == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber2),
      gender: Value(gender),
      groupId: Value(groupId),
      groupName: Value(groupName),
      subGroupId: subGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(subGroupId),
      subGroupName: subGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(subGroupName),
      governorateId: Value(governorateId),
      governorateName: Value(governorateName),
      cityId: cityId == null && nullToAbsent
          ? const Value.absent()
          : Value(cityId),
      cityName: cityName == null && nullToAbsent
          ? const Value.absent()
          : Value(cityName),
      neighborhoodId: neighborhoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(neighborhoodId),
      neighborhoodName: neighborhoodName == null && nullToAbsent
          ? const Value.absent()
          : Value(neighborhoodName),
      primaryPhotoUrl: primaryPhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryPhotoUrl),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      hasReciprocityHistory: Value(hasReciprocityHistory),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
      isDirty: Value(isDirty),
    );
  }

  factory PersonsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      phoneNumber2: serializer.fromJson<String?>(json['phoneNumber2']),
      gender: serializer.fromJson<String>(json['gender']),
      groupId: serializer.fromJson<int>(json['groupId']),
      groupName: serializer.fromJson<String>(json['groupName']),
      subGroupId: serializer.fromJson<int?>(json['subGroupId']),
      subGroupName: serializer.fromJson<String?>(json['subGroupName']),
      governorateId: serializer.fromJson<int>(json['governorateId']),
      governorateName: serializer.fromJson<String>(json['governorateName']),
      cityId: serializer.fromJson<int?>(json['cityId']),
      cityName: serializer.fromJson<String?>(json['cityName']),
      neighborhoodId: serializer.fromJson<int?>(json['neighborhoodId']),
      neighborhoodName: serializer.fromJson<String?>(json['neighborhoodName']),
      primaryPhotoUrl: serializer.fromJson<String?>(json['primaryPhotoUrl']),
      notes: serializer.fromJson<String?>(json['notes']),
      hasReciprocityHistory: serializer.fromJson<bool>(
        json['hasReciprocityHistory'],
      ),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'phoneNumber2': serializer.toJson<String?>(phoneNumber2),
      'gender': serializer.toJson<String>(gender),
      'groupId': serializer.toJson<int>(groupId),
      'groupName': serializer.toJson<String>(groupName),
      'subGroupId': serializer.toJson<int?>(subGroupId),
      'subGroupName': serializer.toJson<String?>(subGroupName),
      'governorateId': serializer.toJson<int>(governorateId),
      'governorateName': serializer.toJson<String>(governorateName),
      'cityId': serializer.toJson<int?>(cityId),
      'cityName': serializer.toJson<String?>(cityName),
      'neighborhoodId': serializer.toJson<int?>(neighborhoodId),
      'neighborhoodName': serializer.toJson<String?>(neighborhoodName),
      'primaryPhotoUrl': serializer.toJson<String?>(primaryPhotoUrl),
      'notes': serializer.toJson<String?>(notes),
      'hasReciprocityHistory': serializer.toJson<bool>(hasReciprocityHistory),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  PersonsTableData copyWith({
    int? id,
    String? name,
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> phoneNumber2 = const Value.absent(),
    String? gender,
    int? groupId,
    String? groupName,
    Value<int?> subGroupId = const Value.absent(),
    Value<String?> subGroupName = const Value.absent(),
    int? governorateId,
    String? governorateName,
    Value<int?> cityId = const Value.absent(),
    Value<String?> cityName = const Value.absent(),
    Value<int?> neighborhoodId = const Value.absent(),
    Value<String?> neighborhoodName = const Value.absent(),
    Value<String?> primaryPhotoUrl = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? hasReciprocityHistory,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isDeleted,
    bool? isDirty,
  }) => PersonsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    phoneNumber2: phoneNumber2.present ? phoneNumber2.value : this.phoneNumber2,
    gender: gender ?? this.gender,
    groupId: groupId ?? this.groupId,
    groupName: groupName ?? this.groupName,
    subGroupId: subGroupId.present ? subGroupId.value : this.subGroupId,
    subGroupName: subGroupName.present ? subGroupName.value : this.subGroupName,
    governorateId: governorateId ?? this.governorateId,
    governorateName: governorateName ?? this.governorateName,
    cityId: cityId.present ? cityId.value : this.cityId,
    cityName: cityName.present ? cityName.value : this.cityName,
    neighborhoodId: neighborhoodId.present
        ? neighborhoodId.value
        : this.neighborhoodId,
    neighborhoodName: neighborhoodName.present
        ? neighborhoodName.value
        : this.neighborhoodName,
    primaryPhotoUrl: primaryPhotoUrl.present
        ? primaryPhotoUrl.value
        : this.primaryPhotoUrl,
    notes: notes.present ? notes.value : this.notes,
    hasReciprocityHistory: hasReciprocityHistory ?? this.hasReciprocityHistory,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    isDirty: isDirty ?? this.isDirty,
  );
  PersonsTableData copyWithCompanion(PersonsTableCompanion data) {
    return PersonsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      phoneNumber2: data.phoneNumber2.present
          ? data.phoneNumber2.value
          : this.phoneNumber2,
      gender: data.gender.present ? data.gender.value : this.gender,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      subGroupId: data.subGroupId.present
          ? data.subGroupId.value
          : this.subGroupId,
      subGroupName: data.subGroupName.present
          ? data.subGroupName.value
          : this.subGroupName,
      governorateId: data.governorateId.present
          ? data.governorateId.value
          : this.governorateId,
      governorateName: data.governorateName.present
          ? data.governorateName.value
          : this.governorateName,
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      cityName: data.cityName.present ? data.cityName.value : this.cityName,
      neighborhoodId: data.neighborhoodId.present
          ? data.neighborhoodId.value
          : this.neighborhoodId,
      neighborhoodName: data.neighborhoodName.present
          ? data.neighborhoodName.value
          : this.neighborhoodName,
      primaryPhotoUrl: data.primaryPhotoUrl.present
          ? data.primaryPhotoUrl.value
          : this.primaryPhotoUrl,
      notes: data.notes.present ? data.notes.value : this.notes,
      hasReciprocityHistory: data.hasReciprocityHistory.present
          ? data.hasReciprocityHistory.value
          : this.hasReciprocityHistory,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('phoneNumber2: $phoneNumber2, ')
          ..write('gender: $gender, ')
          ..write('groupId: $groupId, ')
          ..write('groupName: $groupName, ')
          ..write('subGroupId: $subGroupId, ')
          ..write('subGroupName: $subGroupName, ')
          ..write('governorateId: $governorateId, ')
          ..write('governorateName: $governorateName, ')
          ..write('cityId: $cityId, ')
          ..write('cityName: $cityName, ')
          ..write('neighborhoodId: $neighborhoodId, ')
          ..write('neighborhoodName: $neighborhoodName, ')
          ..write('primaryPhotoUrl: $primaryPhotoUrl, ')
          ..write('notes: $notes, ')
          ..write('hasReciprocityHistory: $hasReciprocityHistory, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    phoneNumber,
    phoneNumber2,
    gender,
    groupId,
    groupName,
    subGroupId,
    subGroupName,
    governorateId,
    governorateName,
    cityId,
    cityName,
    neighborhoodId,
    neighborhoodName,
    primaryPhotoUrl,
    notes,
    hasReciprocityHistory,
    updatedAt,
    isDeleted,
    isDirty,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.phoneNumber == this.phoneNumber &&
          other.phoneNumber2 == this.phoneNumber2 &&
          other.gender == this.gender &&
          other.groupId == this.groupId &&
          other.groupName == this.groupName &&
          other.subGroupId == this.subGroupId &&
          other.subGroupName == this.subGroupName &&
          other.governorateId == this.governorateId &&
          other.governorateName == this.governorateName &&
          other.cityId == this.cityId &&
          other.cityName == this.cityName &&
          other.neighborhoodId == this.neighborhoodId &&
          other.neighborhoodName == this.neighborhoodName &&
          other.primaryPhotoUrl == this.primaryPhotoUrl &&
          other.notes == this.notes &&
          other.hasReciprocityHistory == this.hasReciprocityHistory &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isDirty == this.isDirty);
}

class PersonsTableCompanion extends UpdateCompanion<PersonsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> phoneNumber;
  final Value<String?> phoneNumber2;
  final Value<String> gender;
  final Value<int> groupId;
  final Value<String> groupName;
  final Value<int?> subGroupId;
  final Value<String?> subGroupName;
  final Value<int> governorateId;
  final Value<String> governorateName;
  final Value<int?> cityId;
  final Value<String?> cityName;
  final Value<int?> neighborhoodId;
  final Value<String?> neighborhoodName;
  final Value<String?> primaryPhotoUrl;
  final Value<String?> notes;
  final Value<bool> hasReciprocityHistory;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isDirty;
  const PersonsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.phoneNumber2 = const Value.absent(),
    this.gender = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupName = const Value.absent(),
    this.subGroupId = const Value.absent(),
    this.subGroupName = const Value.absent(),
    this.governorateId = const Value.absent(),
    this.governorateName = const Value.absent(),
    this.cityId = const Value.absent(),
    this.cityName = const Value.absent(),
    this.neighborhoodId = const Value.absent(),
    this.neighborhoodName = const Value.absent(),
    this.primaryPhotoUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.hasReciprocityHistory = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isDirty = const Value.absent(),
  });
  PersonsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phoneNumber = const Value.absent(),
    this.phoneNumber2 = const Value.absent(),
    required String gender,
    required int groupId,
    required String groupName,
    this.subGroupId = const Value.absent(),
    this.subGroupName = const Value.absent(),
    required int governorateId,
    required String governorateName,
    this.cityId = const Value.absent(),
    this.cityName = const Value.absent(),
    this.neighborhoodId = const Value.absent(),
    this.neighborhoodName = const Value.absent(),
    this.primaryPhotoUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.hasReciprocityHistory = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isDirty = const Value.absent(),
  }) : name = Value(name),
       gender = Value(gender),
       groupId = Value(groupId),
       groupName = Value(groupName),
       governorateId = Value(governorateId),
       governorateName = Value(governorateName);
  static Insertable<PersonsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phoneNumber,
    Expression<String>? phoneNumber2,
    Expression<String>? gender,
    Expression<int>? groupId,
    Expression<String>? groupName,
    Expression<int>? subGroupId,
    Expression<String>? subGroupName,
    Expression<int>? governorateId,
    Expression<String>? governorateName,
    Expression<int>? cityId,
    Expression<String>? cityName,
    Expression<int>? neighborhoodId,
    Expression<String>? neighborhoodName,
    Expression<String>? primaryPhotoUrl,
    Expression<String>? notes,
    Expression<bool>? hasReciprocityHistory,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isDirty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (phoneNumber2 != null) 'phone_number2': phoneNumber2,
      if (gender != null) 'gender': gender,
      if (groupId != null) 'group_id': groupId,
      if (groupName != null) 'group_name': groupName,
      if (subGroupId != null) 'sub_group_id': subGroupId,
      if (subGroupName != null) 'sub_group_name': subGroupName,
      if (governorateId != null) 'governorate_id': governorateId,
      if (governorateName != null) 'governorate_name': governorateName,
      if (cityId != null) 'city_id': cityId,
      if (cityName != null) 'city_name': cityName,
      if (neighborhoodId != null) 'neighborhood_id': neighborhoodId,
      if (neighborhoodName != null) 'neighborhood_name': neighborhoodName,
      if (primaryPhotoUrl != null) 'primary_photo_url': primaryPhotoUrl,
      if (notes != null) 'notes': notes,
      if (hasReciprocityHistory != null)
        'has_reciprocity_history': hasReciprocityHistory,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isDirty != null) 'is_dirty': isDirty,
    });
  }

  PersonsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? phoneNumber,
    Value<String?>? phoneNumber2,
    Value<String>? gender,
    Value<int>? groupId,
    Value<String>? groupName,
    Value<int?>? subGroupId,
    Value<String?>? subGroupName,
    Value<int>? governorateId,
    Value<String>? governorateName,
    Value<int?>? cityId,
    Value<String?>? cityName,
    Value<int?>? neighborhoodId,
    Value<String?>? neighborhoodName,
    Value<String?>? primaryPhotoUrl,
    Value<String?>? notes,
    Value<bool>? hasReciprocityHistory,
    Value<DateTime?>? updatedAt,
    Value<bool>? isDeleted,
    Value<bool>? isDirty,
  }) {
    return PersonsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumber2: phoneNumber2 ?? this.phoneNumber2,
      gender: gender ?? this.gender,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      subGroupId: subGroupId ?? this.subGroupId,
      subGroupName: subGroupName ?? this.subGroupName,
      governorateId: governorateId ?? this.governorateId,
      governorateName: governorateName ?? this.governorateName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      primaryPhotoUrl: primaryPhotoUrl ?? this.primaryPhotoUrl,
      notes: notes ?? this.notes,
      hasReciprocityHistory:
          hasReciprocityHistory ?? this.hasReciprocityHistory,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (phoneNumber2.present) {
      map['phone_number2'] = Variable<String>(phoneNumber2.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (subGroupId.present) {
      map['sub_group_id'] = Variable<int>(subGroupId.value);
    }
    if (subGroupName.present) {
      map['sub_group_name'] = Variable<String>(subGroupName.value);
    }
    if (governorateId.present) {
      map['governorate_id'] = Variable<int>(governorateId.value);
    }
    if (governorateName.present) {
      map['governorate_name'] = Variable<String>(governorateName.value);
    }
    if (cityId.present) {
      map['city_id'] = Variable<int>(cityId.value);
    }
    if (cityName.present) {
      map['city_name'] = Variable<String>(cityName.value);
    }
    if (neighborhoodId.present) {
      map['neighborhood_id'] = Variable<int>(neighborhoodId.value);
    }
    if (neighborhoodName.present) {
      map['neighborhood_name'] = Variable<String>(neighborhoodName.value);
    }
    if (primaryPhotoUrl.present) {
      map['primary_photo_url'] = Variable<String>(primaryPhotoUrl.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (hasReciprocityHistory.present) {
      map['has_reciprocity_history'] = Variable<bool>(
        hasReciprocityHistory.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('phoneNumber2: $phoneNumber2, ')
          ..write('gender: $gender, ')
          ..write('groupId: $groupId, ')
          ..write('groupName: $groupName, ')
          ..write('subGroupId: $subGroupId, ')
          ..write('subGroupName: $subGroupName, ')
          ..write('governorateId: $governorateId, ')
          ..write('governorateName: $governorateName, ')
          ..write('cityId: $cityId, ')
          ..write('cityName: $cityName, ')
          ..write('neighborhoodId: $neighborhoodId, ')
          ..write('neighborhoodName: $neighborhoodName, ')
          ..write('primaryPhotoUrl: $primaryPhotoUrl, ')
          ..write('notes: $notes, ')
          ..write('hasReciprocityHistory: $hasReciprocityHistory, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }
}

class $GroupsTableTable extends GroupsTable
    with TableInfo<$GroupsTableTable, GroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameAr,
    updatedAt,
    isDeleted,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $GroupsTableTable createAlias(String alias) {
    return $GroupsTableTable(attachedDatabase, alias);
  }
}

class GroupsTableData extends DataClass implements Insertable<GroupsTableData> {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isDirty;
  const GroupsTableData({
    required this.id,
    required this.name,
    this.nameAr,
    this.updatedAt,
    required this.isDeleted,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  GroupsTableCompanion toCompanion(bool nullToAbsent) {
    return GroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
      isDirty: Value(isDirty),
    );
  }

  factory GroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nameAr': serializer.toJson<String?>(nameAr),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  GroupsTableData copyWith({
    int? id,
    String? name,
    Value<String?> nameAr = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isDeleted,
    bool? isDirty,
  }) => GroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    isDirty: isDirty ?? this.isDirty,
  );
  GroupsTableData copyWithCompanion(GroupsTableCompanion data) {
    return GroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameAr: $nameAr, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, nameAr, updatedAt, isDeleted, isDirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameAr == this.nameAr &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isDirty == this.isDirty);
}

class GroupsTableCompanion extends UpdateCompanion<GroupsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> nameAr;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isDirty;
  const GroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isDirty = const Value.absent(),
  });
  GroupsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.nameAr = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isDirty = const Value.absent(),
  }) : name = Value(name);
  static Insertable<GroupsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nameAr,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isDirty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameAr != null) 'name_ar': nameAr,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isDirty != null) 'is_dirty': isDirty,
    });
  }

  GroupsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? nameAr,
    Value<DateTime?>? updatedAt,
    Value<bool>? isDeleted,
    Value<bool>? isDirty,
  }) {
    return GroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameAr: $nameAr, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }
}

class $OutboxTableTable extends OutboxTable
    with TableInfo<$OutboxTableTable, OutboxTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    createdAt,
    retryCount,
    lastError,
    lastAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
    );
  }

  @override
  $OutboxTableTable createAlias(String alias) {
    return $OutboxTableTable(attachedDatabase, alias);
  }
}

class OutboxTableData extends DataClass implements Insertable<OutboxTableData> {
  final int id;
  final String entityType;
  final int entityId;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  /// When this row was last attempted (null = never attempted yet). Drives
  /// `SyncService`'s exponential backoff schedule — `retryCount` alone can't
  /// tell "due now" from "due in 4 more minutes" (design doc §5).
  final DateTime? lastAttemptAt;
  const OutboxTableData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
    this.lastAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  OutboxTableCompanion toCompanion(bool nullToAbsent) {
    return OutboxTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory OutboxTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxTableData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  OutboxTableData copyWith({
    int? id,
    String? entityType,
    int? entityId,
    String? operation,
    String? payloadJson,
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
  }) => OutboxTableData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
  );
  OutboxTableData copyWithCompanion(OutboxTableCompanion data) {
    return OutboxTableData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxTableData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    createdAt,
    retryCount,
    lastError,
    lastAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxTableData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class OutboxTableCompanion extends UpdateCompanion<OutboxTableData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime?> lastAttemptAt;
  const OutboxTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
  });
  OutboxTableCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required int entityId,
    required String operation,
    required String payloadJson,
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson);
  static Insertable<OutboxTableData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? lastAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
    });
  }

  OutboxTableCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<int>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<DateTime?>? lastAttemptAt,
  }) {
    return OutboxTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTableTable extends SyncStateTable
    with TableInfo<$SyncStateTableTable, SyncStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [collection, cursor, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collection};
  @override
  SyncStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateTableData(
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncStateTableTable createAlias(String alias) {
    return $SyncStateTableTable(attachedDatabase, alias);
  }
}

class SyncStateTableData extends DataClass
    implements Insertable<SyncStateTableData> {
  final String collection;
  final String? cursor;
  final DateTime? lastSyncedAt;
  const SyncStateTableData({
    required this.collection,
    this.cursor,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection'] = Variable<String>(collection);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncStateTableCompanion toCompanion(bool nullToAbsent) {
    return SyncStateTableCompanion(
      collection: Value(collection),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncStateTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateTableData(
      collection: serializer.fromJson<String>(json['collection']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collection': serializer.toJson<String>(collection),
      'cursor': serializer.toJson<String?>(cursor),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  SyncStateTableData copyWith({
    String? collection,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => SyncStateTableData(
    collection: collection ?? this.collection,
    cursor: cursor.present ? cursor.value : this.cursor,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncStateTableData copyWithCompanion(SyncStateTableCompanion data) {
    return SyncStateTableData(
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateTableData(')
          ..write('collection: $collection, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collection, cursor, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateTableData &&
          other.collection == this.collection &&
          other.cursor == this.cursor &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncStateTableCompanion extends UpdateCompanion<SyncStateTableData> {
  final Value<String> collection;
  final Value<String?> cursor;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncStateTableCompanion({
    this.collection = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateTableCompanion.insert({
    required String collection,
    this.cursor = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : collection = Value(collection);
  static Insertable<SyncStateTableData> custom({
    Expression<String>? collection,
    Expression<String>? cursor,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collection != null) 'collection': collection,
      if (cursor != null) 'cursor': cursor,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateTableCompanion copyWith({
    Value<String>? collection,
    Value<String?>? cursor,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncStateTableCompanion(
      collection: collection ?? this.collection,
      cursor: cursor ?? this.cursor,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateTableCompanion(')
          ..write('collection: $collection, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PersonsTableTable personsTable = $PersonsTableTable(this);
  late final $GroupsTableTable groupsTable = $GroupsTableTable(this);
  late final $OutboxTableTable outboxTable = $OutboxTableTable(this);
  late final $SyncStateTableTable syncStateTable = $SyncStateTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    personsTable,
    groupsTable,
    outboxTable,
    syncStateTable,
  ];
}

typedef $$PersonsTableTableCreateCompanionBuilder =
    PersonsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> phoneNumber,
      Value<String?> phoneNumber2,
      required String gender,
      required int groupId,
      required String groupName,
      Value<int?> subGroupId,
      Value<String?> subGroupName,
      required int governorateId,
      required String governorateName,
      Value<int?> cityId,
      Value<String?> cityName,
      Value<int?> neighborhoodId,
      Value<String?> neighborhoodName,
      Value<String?> primaryPhotoUrl,
      Value<String?> notes,
      Value<bool> hasReciprocityHistory,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isDirty,
    });
typedef $$PersonsTableTableUpdateCompanionBuilder =
    PersonsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> phoneNumber,
      Value<String?> phoneNumber2,
      Value<String> gender,
      Value<int> groupId,
      Value<String> groupName,
      Value<int?> subGroupId,
      Value<String?> subGroupName,
      Value<int> governorateId,
      Value<String> governorateName,
      Value<int?> cityId,
      Value<String?> cityName,
      Value<int?> neighborhoodId,
      Value<String?> neighborhoodName,
      Value<String?> primaryPhotoUrl,
      Value<String?> notes,
      Value<bool> hasReciprocityHistory,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isDirty,
    });

class $$PersonsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTableTable> {
  $$PersonsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber2 => $composableBuilder(
    column: $table.phoneNumber2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subGroupId => $composableBuilder(
    column: $table.subGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subGroupName => $composableBuilder(
    column: $table.subGroupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get governorateId => $composableBuilder(
    column: $table.governorateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get governorateName => $composableBuilder(
    column: $table.governorateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cityId => $composableBuilder(
    column: $table.cityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cityName => $composableBuilder(
    column: $table.cityName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get neighborhoodId => $composableBuilder(
    column: $table.neighborhoodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get neighborhoodName => $composableBuilder(
    column: $table.neighborhoodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryPhotoUrl => $composableBuilder(
    column: $table.primaryPhotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasReciprocityHistory => $composableBuilder(
    column: $table.hasReciprocityHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTableTable> {
  $$PersonsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber2 => $composableBuilder(
    column: $table.phoneNumber2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subGroupId => $composableBuilder(
    column: $table.subGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subGroupName => $composableBuilder(
    column: $table.subGroupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get governorateId => $composableBuilder(
    column: $table.governorateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get governorateName => $composableBuilder(
    column: $table.governorateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cityId => $composableBuilder(
    column: $table.cityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cityName => $composableBuilder(
    column: $table.cityName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get neighborhoodId => $composableBuilder(
    column: $table.neighborhoodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get neighborhoodName => $composableBuilder(
    column: $table.neighborhoodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryPhotoUrl => $composableBuilder(
    column: $table.primaryPhotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasReciprocityHistory => $composableBuilder(
    column: $table.hasReciprocityHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTableTable> {
  $$PersonsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneNumber2 => $composableBuilder(
    column: $table.phoneNumber2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<int> get subGroupId => $composableBuilder(
    column: $table.subGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subGroupName => $composableBuilder(
    column: $table.subGroupName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get governorateId => $composableBuilder(
    column: $table.governorateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get governorateName => $composableBuilder(
    column: $table.governorateName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cityId =>
      $composableBuilder(column: $table.cityId, builder: (column) => column);

  GeneratedColumn<String> get cityName =>
      $composableBuilder(column: $table.cityName, builder: (column) => column);

  GeneratedColumn<int> get neighborhoodId => $composableBuilder(
    column: $table.neighborhoodId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get neighborhoodName => $composableBuilder(
    column: $table.neighborhoodName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryPhotoUrl => $composableBuilder(
    column: $table.primaryPhotoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get hasReciprocityHistory => $composableBuilder(
    column: $table.hasReciprocityHistory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$PersonsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTableTable,
          PersonsTableData,
          $$PersonsTableTableFilterComposer,
          $$PersonsTableTableOrderingComposer,
          $$PersonsTableTableAnnotationComposer,
          $$PersonsTableTableCreateCompanionBuilder,
          $$PersonsTableTableUpdateCompanionBuilder,
          (
            PersonsTableData,
            BaseReferences<_$AppDatabase, $PersonsTableTable, PersonsTableData>,
          ),
          PersonsTableData,
          PrefetchHooks Function()
        > {
  $$PersonsTableTableTableManager(_$AppDatabase db, $PersonsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> phoneNumber2 = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<String> groupName = const Value.absent(),
                Value<int?> subGroupId = const Value.absent(),
                Value<String?> subGroupName = const Value.absent(),
                Value<int> governorateId = const Value.absent(),
                Value<String> governorateName = const Value.absent(),
                Value<int?> cityId = const Value.absent(),
                Value<String?> cityName = const Value.absent(),
                Value<int?> neighborhoodId = const Value.absent(),
                Value<String?> neighborhoodName = const Value.absent(),
                Value<String?> primaryPhotoUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> hasReciprocityHistory = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
              }) => PersonsTableCompanion(
                id: id,
                name: name,
                phoneNumber: phoneNumber,
                phoneNumber2: phoneNumber2,
                gender: gender,
                groupId: groupId,
                groupName: groupName,
                subGroupId: subGroupId,
                subGroupName: subGroupName,
                governorateId: governorateId,
                governorateName: governorateName,
                cityId: cityId,
                cityName: cityName,
                neighborhoodId: neighborhoodId,
                neighborhoodName: neighborhoodName,
                primaryPhotoUrl: primaryPhotoUrl,
                notes: notes,
                hasReciprocityHistory: hasReciprocityHistory,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isDirty: isDirty,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> phoneNumber2 = const Value.absent(),
                required String gender,
                required int groupId,
                required String groupName,
                Value<int?> subGroupId = const Value.absent(),
                Value<String?> subGroupName = const Value.absent(),
                required int governorateId,
                required String governorateName,
                Value<int?> cityId = const Value.absent(),
                Value<String?> cityName = const Value.absent(),
                Value<int?> neighborhoodId = const Value.absent(),
                Value<String?> neighborhoodName = const Value.absent(),
                Value<String?> primaryPhotoUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> hasReciprocityHistory = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
              }) => PersonsTableCompanion.insert(
                id: id,
                name: name,
                phoneNumber: phoneNumber,
                phoneNumber2: phoneNumber2,
                gender: gender,
                groupId: groupId,
                groupName: groupName,
                subGroupId: subGroupId,
                subGroupName: subGroupName,
                governorateId: governorateId,
                governorateName: governorateName,
                cityId: cityId,
                cityName: cityName,
                neighborhoodId: neighborhoodId,
                neighborhoodName: neighborhoodName,
                primaryPhotoUrl: primaryPhotoUrl,
                notes: notes,
                hasReciprocityHistory: hasReciprocityHistory,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isDirty: isDirty,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonsTableTable, PersonsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PersonsTableTable,
                    PersonsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTableTable,
      PersonsTableData,
      $$PersonsTableTableFilterComposer,
      $$PersonsTableTableOrderingComposer,
      $$PersonsTableTableAnnotationComposer,
      $$PersonsTableTableCreateCompanionBuilder,
      $$PersonsTableTableUpdateCompanionBuilder,
      (
        PersonsTableData,
        BaseReferences<_$AppDatabase, $PersonsTableTable, PersonsTableData>,
      ),
      PersonsTableData,
      PrefetchHooks Function()
    >;
typedef $$GroupsTableTableCreateCompanionBuilder =
    GroupsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> nameAr,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isDirty,
    });
typedef $$GroupsTableTableUpdateCompanionBuilder =
    GroupsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> nameAr,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isDirty,
    });

class $$GroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTableTable> {
  $$GroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTableTable> {
  $$GroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTableTable> {
  $$GroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$GroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTableTable,
          GroupsTableData,
          $$GroupsTableTableFilterComposer,
          $$GroupsTableTableOrderingComposer,
          $$GroupsTableTableAnnotationComposer,
          $$GroupsTableTableCreateCompanionBuilder,
          $$GroupsTableTableUpdateCompanionBuilder,
          (
            GroupsTableData,
            BaseReferences<_$AppDatabase, $GroupsTableTable, GroupsTableData>,
          ),
          GroupsTableData,
          PrefetchHooks Function()
        > {
  $$GroupsTableTableTableManager(_$AppDatabase db, $GroupsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
              }) => GroupsTableCompanion(
                id: id,
                name: name,
                nameAr: nameAr,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isDirty: isDirty,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> nameAr = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
              }) => GroupsTableCompanion.insert(
                id: id,
                name: name,
                nameAr: nameAr,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isDirty: isDirty,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupsTableTable, GroupsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GroupsTableTable,
                    GroupsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTableTable,
      GroupsTableData,
      $$GroupsTableTableFilterComposer,
      $$GroupsTableTableOrderingComposer,
      $$GroupsTableTableAnnotationComposer,
      $$GroupsTableTableCreateCompanionBuilder,
      $$GroupsTableTableUpdateCompanionBuilder,
      (
        GroupsTableData,
        BaseReferences<_$AppDatabase, $GroupsTableTable, GroupsTableData>,
      ),
      GroupsTableData,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableTableCreateCompanionBuilder =
    OutboxTableCompanion Function({
      Value<int> id,
      required String entityType,
      required int entityId,
      required String operation,
      required String payloadJson,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime?> lastAttemptAt,
    });
typedef $$OutboxTableTableUpdateCompanionBuilder =
    OutboxTableCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<int> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime?> lastAttemptAt,
    });

class $$OutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );
}

class $$OutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTableTable,
          OutboxTableData,
          $$OutboxTableTableFilterComposer,
          $$OutboxTableTableOrderingComposer,
          $$OutboxTableTableAnnotationComposer,
          $$OutboxTableTableCreateCompanionBuilder,
          $$OutboxTableTableUpdateCompanionBuilder,
          (
            OutboxTableData,
            BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxTableData>,
          ),
          OutboxTableData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableTableManager(_$AppDatabase db, $OutboxTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
              }) => OutboxTableCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required int entityId,
                required String operation,
                required String payloadJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
              }) => OutboxTableCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTableTable, OutboxTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OutboxTableTable,
                    OutboxTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTableTable,
      OutboxTableData,
      $$OutboxTableTableFilterComposer,
      $$OutboxTableTableOrderingComposer,
      $$OutboxTableTableAnnotationComposer,
      $$OutboxTableTableCreateCompanionBuilder,
      $$OutboxTableTableUpdateCompanionBuilder,
      (
        OutboxTableData,
        BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxTableData>,
      ),
      OutboxTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableTableCreateCompanionBuilder =
    SyncStateTableCompanion Function({
      required String collection,
      Value<String?> cursor,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncStateTableTableUpdateCompanionBuilder =
    SyncStateTableCompanion Function({
      Value<String> collection,
      Value<String?> cursor,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTableTable> {
  $$SyncStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTableTable,
          SyncStateTableData,
          $$SyncStateTableTableFilterComposer,
          $$SyncStateTableTableOrderingComposer,
          $$SyncStateTableTableAnnotationComposer,
          $$SyncStateTableTableCreateCompanionBuilder,
          $$SyncStateTableTableUpdateCompanionBuilder,
          (
            SyncStateTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncStateTableTable,
              SyncStateTableData
            >,
          ),
          SyncStateTableData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableTableManager(
    _$AppDatabase db,
    $SyncStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collection = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateTableCompanion(
                collection: collection,
                cursor: cursor,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collection,
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateTableCompanion.insert(
                collection: collection,
                cursor: cursor,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTableTable, SyncStateTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncStateTableTable,
                    SyncStateTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTableTable,
      SyncStateTableData,
      $$SyncStateTableTableFilterComposer,
      $$SyncStateTableTableOrderingComposer,
      $$SyncStateTableTableAnnotationComposer,
      $$SyncStateTableTableCreateCompanionBuilder,
      $$SyncStateTableTableUpdateCompanionBuilder,
      (
        SyncStateTableData,
        BaseReferences<_$AppDatabase, $SyncStateTableTable, SyncStateTableData>,
      ),
      SyncStateTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PersonsTableTableTableManager get personsTable =>
      $$PersonsTableTableTableManager(_db, _db.personsTable);
  $$GroupsTableTableTableManager get groupsTable =>
      $$GroupsTableTableTableManager(_db, _db.groupsTable);
  $$OutboxTableTableTableManager get outboxTable =>
      $$OutboxTableTableTableManager(_db, _db.outboxTable);
  $$SyncStateTableTableTableManager get syncStateTable =>
      $$SyncStateTableTableTableManager(_db, _db.syncStateTable);
}
