// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeLevelMeta = const VerificationMeta(
    'gradeLevel',
  );
  @override
  late final GeneratedColumn<int> gradeLevel = GeneratedColumn<int>(
    'grade_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brickBalanceMeta = const VerificationMeta(
    'brickBalance',
  );
  @override
  late final GeneratedColumn<int> brickBalance = GeneratedColumn<int>(
    'brick_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lifetimeBricksEarnedMeta =
      const VerificationMeta('lifetimeBricksEarned');
  @override
  late final GeneratedColumn<int> lifetimeBricksEarned = GeneratedColumn<int>(
    'lifetime_bricks_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _researchBalanceMeta = const VerificationMeta(
    'researchBalance',
  );
  @override
  late final GeneratedColumn<int> researchBalance = GeneratedColumn<int>(
    'research_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lifetimeResearchEarnedMeta =
      const VerificationMeta('lifetimeResearchEarned');
  @override
  late final GeneratedColumn<int> lifetimeResearchEarned = GeneratedColumn<int>(
    'lifetime_research_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarConfigMeta = const VerificationMeta(
    'avatarConfig',
  );
  @override
  late final GeneratedColumn<String> avatarConfig = GeneratedColumn<String>(
    'avatar_config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    gradeLevel,
    brickBalance,
    lifetimeBricksEarned,
    researchBalance,
    lifetimeResearchEarned,
    createdAt,
    avatarConfig,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
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
    if (data.containsKey('grade_level')) {
      context.handle(
        _gradeLevelMeta,
        gradeLevel.isAcceptableOrUnknown(data['grade_level']!, _gradeLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeLevelMeta);
    }
    if (data.containsKey('brick_balance')) {
      context.handle(
        _brickBalanceMeta,
        brickBalance.isAcceptableOrUnknown(
          data['brick_balance']!,
          _brickBalanceMeta,
        ),
      );
    }
    if (data.containsKey('lifetime_bricks_earned')) {
      context.handle(
        _lifetimeBricksEarnedMeta,
        lifetimeBricksEarned.isAcceptableOrUnknown(
          data['lifetime_bricks_earned']!,
          _lifetimeBricksEarnedMeta,
        ),
      );
    }
    if (data.containsKey('research_balance')) {
      context.handle(
        _researchBalanceMeta,
        researchBalance.isAcceptableOrUnknown(
          data['research_balance']!,
          _researchBalanceMeta,
        ),
      );
    }
    if (data.containsKey('lifetime_research_earned')) {
      context.handle(
        _lifetimeResearchEarnedMeta,
        lifetimeResearchEarned.isAcceptableOrUnknown(
          data['lifetime_research_earned']!,
          _lifetimeResearchEarnedMeta,
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
    if (data.containsKey('avatar_config')) {
      context.handle(
        _avatarConfigMeta,
        avatarConfig.isAcceptableOrUnknown(
          data['avatar_config']!,
          _avatarConfigMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade_level'],
      )!,
      brickBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brick_balance'],
      )!,
      lifetimeBricksEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lifetime_bricks_earned'],
      )!,
      researchBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}research_balance'],
      )!,
      lifetimeResearchEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lifetime_research_earned'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      avatarConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_config'],
      ),
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final int id;
  final String name;
  final int gradeLevel;

  /// 🧱 spending balance — decremented on placements, map unlocks, events.
  final int brickBalance;

  /// 🧱 lifetime earned — never decreases; available as a gate input on
  /// `BuildingType.unlockRule.minLifetimeBricks`.
  final int lifetimeBricksEarned;

  /// 🔬 spending balance — decremented when the player spends research to
  /// move a building type from "available" into `BuildingTypesResearched`.
  final int researchBalance;

  /// 🔬 lifetime earned — never decreases; bookkeeping.
  final int lifetimeResearchEarned;
  final DateTime createdAt;
  final String? avatarConfig;
  const Player({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.brickBalance,
    required this.lifetimeBricksEarned,
    required this.researchBalance,
    required this.lifetimeResearchEarned,
    required this.createdAt,
    this.avatarConfig,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['grade_level'] = Variable<int>(gradeLevel);
    map['brick_balance'] = Variable<int>(brickBalance);
    map['lifetime_bricks_earned'] = Variable<int>(lifetimeBricksEarned);
    map['research_balance'] = Variable<int>(researchBalance);
    map['lifetime_research_earned'] = Variable<int>(lifetimeResearchEarned);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || avatarConfig != null) {
      map['avatar_config'] = Variable<String>(avatarConfig);
    }
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      gradeLevel: Value(gradeLevel),
      brickBalance: Value(brickBalance),
      lifetimeBricksEarned: Value(lifetimeBricksEarned),
      researchBalance: Value(researchBalance),
      lifetimeResearchEarned: Value(lifetimeResearchEarned),
      createdAt: Value(createdAt),
      avatarConfig: avatarConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarConfig),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gradeLevel: serializer.fromJson<int>(json['gradeLevel']),
      brickBalance: serializer.fromJson<int>(json['brickBalance']),
      lifetimeBricksEarned: serializer.fromJson<int>(
        json['lifetimeBricksEarned'],
      ),
      researchBalance: serializer.fromJson<int>(json['researchBalance']),
      lifetimeResearchEarned: serializer.fromJson<int>(
        json['lifetimeResearchEarned'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      avatarConfig: serializer.fromJson<String?>(json['avatarConfig']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'gradeLevel': serializer.toJson<int>(gradeLevel),
      'brickBalance': serializer.toJson<int>(brickBalance),
      'lifetimeBricksEarned': serializer.toJson<int>(lifetimeBricksEarned),
      'researchBalance': serializer.toJson<int>(researchBalance),
      'lifetimeResearchEarned': serializer.toJson<int>(lifetimeResearchEarned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'avatarConfig': serializer.toJson<String?>(avatarConfig),
    };
  }

  Player copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    int? brickBalance,
    int? lifetimeBricksEarned,
    int? researchBalance,
    int? lifetimeResearchEarned,
    DateTime? createdAt,
    Value<String?> avatarConfig = const Value.absent(),
  }) => Player(
    id: id ?? this.id,
    name: name ?? this.name,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    brickBalance: brickBalance ?? this.brickBalance,
    lifetimeBricksEarned: lifetimeBricksEarned ?? this.lifetimeBricksEarned,
    researchBalance: researchBalance ?? this.researchBalance,
    lifetimeResearchEarned:
        lifetimeResearchEarned ?? this.lifetimeResearchEarned,
    createdAt: createdAt ?? this.createdAt,
    avatarConfig: avatarConfig.present ? avatarConfig.value : this.avatarConfig,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gradeLevel: data.gradeLevel.present
          ? data.gradeLevel.value
          : this.gradeLevel,
      brickBalance: data.brickBalance.present
          ? data.brickBalance.value
          : this.brickBalance,
      lifetimeBricksEarned: data.lifetimeBricksEarned.present
          ? data.lifetimeBricksEarned.value
          : this.lifetimeBricksEarned,
      researchBalance: data.researchBalance.present
          ? data.researchBalance.value
          : this.researchBalance,
      lifetimeResearchEarned: data.lifetimeResearchEarned.present
          ? data.lifetimeResearchEarned.value
          : this.lifetimeResearchEarned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      avatarConfig: data.avatarConfig.present
          ? data.avatarConfig.value
          : this.avatarConfig,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('brickBalance: $brickBalance, ')
          ..write('lifetimeBricksEarned: $lifetimeBricksEarned, ')
          ..write('researchBalance: $researchBalance, ')
          ..write('lifetimeResearchEarned: $lifetimeResearchEarned, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarConfig: $avatarConfig')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    gradeLevel,
    brickBalance,
    lifetimeBricksEarned,
    researchBalance,
    lifetimeResearchEarned,
    createdAt,
    avatarConfig,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.name == this.name &&
          other.gradeLevel == this.gradeLevel &&
          other.brickBalance == this.brickBalance &&
          other.lifetimeBricksEarned == this.lifetimeBricksEarned &&
          other.researchBalance == this.researchBalance &&
          other.lifetimeResearchEarned == this.lifetimeResearchEarned &&
          other.createdAt == this.createdAt &&
          other.avatarConfig == this.avatarConfig);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> gradeLevel;
  final Value<int> brickBalance;
  final Value<int> lifetimeBricksEarned;
  final Value<int> researchBalance;
  final Value<int> lifetimeResearchEarned;
  final Value<DateTime> createdAt;
  final Value<String?> avatarConfig;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.brickBalance = const Value.absent(),
    this.lifetimeBricksEarned = const Value.absent(),
    this.researchBalance = const Value.absent(),
    this.lifetimeResearchEarned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarConfig = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int gradeLevel,
    this.brickBalance = const Value.absent(),
    this.lifetimeBricksEarned = const Value.absent(),
    this.researchBalance = const Value.absent(),
    this.lifetimeResearchEarned = const Value.absent(),
    required DateTime createdAt,
    this.avatarConfig = const Value.absent(),
  }) : name = Value(name),
       gradeLevel = Value(gradeLevel),
       createdAt = Value(createdAt);
  static Insertable<Player> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? gradeLevel,
    Expression<int>? brickBalance,
    Expression<int>? lifetimeBricksEarned,
    Expression<int>? researchBalance,
    Expression<int>? lifetimeResearchEarned,
    Expression<DateTime>? createdAt,
    Expression<String>? avatarConfig,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (brickBalance != null) 'brick_balance': brickBalance,
      if (lifetimeBricksEarned != null)
        'lifetime_bricks_earned': lifetimeBricksEarned,
      if (researchBalance != null) 'research_balance': researchBalance,
      if (lifetimeResearchEarned != null)
        'lifetime_research_earned': lifetimeResearchEarned,
      if (createdAt != null) 'created_at': createdAt,
      if (avatarConfig != null) 'avatar_config': avatarConfig,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? gradeLevel,
    Value<int>? brickBalance,
    Value<int>? lifetimeBricksEarned,
    Value<int>? researchBalance,
    Value<int>? lifetimeResearchEarned,
    Value<DateTime>? createdAt,
    Value<String?>? avatarConfig,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      brickBalance: brickBalance ?? this.brickBalance,
      lifetimeBricksEarned: lifetimeBricksEarned ?? this.lifetimeBricksEarned,
      researchBalance: researchBalance ?? this.researchBalance,
      lifetimeResearchEarned:
          lifetimeResearchEarned ?? this.lifetimeResearchEarned,
      createdAt: createdAt ?? this.createdAt,
      avatarConfig: avatarConfig ?? this.avatarConfig,
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
    if (gradeLevel.present) {
      map['grade_level'] = Variable<int>(gradeLevel.value);
    }
    if (brickBalance.present) {
      map['brick_balance'] = Variable<int>(brickBalance.value);
    }
    if (lifetimeBricksEarned.present) {
      map['lifetime_bricks_earned'] = Variable<int>(lifetimeBricksEarned.value);
    }
    if (researchBalance.present) {
      map['research_balance'] = Variable<int>(researchBalance.value);
    }
    if (lifetimeResearchEarned.present) {
      map['lifetime_research_earned'] = Variable<int>(
        lifetimeResearchEarned.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (avatarConfig.present) {
      map['avatar_config'] = Variable<String>(avatarConfig.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('brickBalance: $brickBalance, ')
          ..write('lifetimeBricksEarned: $lifetimeBricksEarned, ')
          ..write('researchBalance: $researchBalance, ')
          ..write('lifetimeResearchEarned: $lifetimeResearchEarned, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarConfig: $avatarConfig')
          ..write(')'))
        .toString();
  }
}

class $ConceptProficienciesTable extends ConceptProficiencies
    with TableInfo<$ConceptProficienciesTable, ConceptProficiency> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConceptProficienciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _conceptIdMeta = const VerificationMeta(
    'conceptId',
  );
  @override
  late final GeneratedColumn<String> conceptId = GeneratedColumn<String>(
    'concept_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proficiencyMeta = const VerificationMeta(
    'proficiency',
  );
  @override
  late final GeneratedColumn<double> proficiency = GeneratedColumn<double>(
    'proficiency',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsAnsweredMeta = const VerificationMeta(
    'questionsAnswered',
  );
  @override
  late final GeneratedColumn<int> questionsAnswered = GeneratedColumn<int>(
    'questions_answered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _questionsCorrectMeta = const VerificationMeta(
    'questionsCorrect',
  );
  @override
  late final GeneratedColumn<int> questionsCorrect = GeneratedColumn<int>(
    'questions_correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    playerId,
    conceptId,
    proficiency,
    questionsAnswered,
    questionsCorrect,
    lastUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'concept_proficiencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConceptProficiency> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('concept_id')) {
      context.handle(
        _conceptIdMeta,
        conceptId.isAcceptableOrUnknown(data['concept_id']!, _conceptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptIdMeta);
    }
    if (data.containsKey('proficiency')) {
      context.handle(
        _proficiencyMeta,
        proficiency.isAcceptableOrUnknown(
          data['proficiency']!,
          _proficiencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proficiencyMeta);
    }
    if (data.containsKey('questions_answered')) {
      context.handle(
        _questionsAnsweredMeta,
        questionsAnswered.isAcceptableOrUnknown(
          data['questions_answered']!,
          _questionsAnsweredMeta,
        ),
      );
    }
    if (data.containsKey('questions_correct')) {
      context.handle(
        _questionsCorrectMeta,
        questionsCorrect.isAcceptableOrUnknown(
          data['questions_correct']!,
          _questionsCorrectMeta,
        ),
      );
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, conceptId};
  @override
  ConceptProficiency map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConceptProficiency(
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      conceptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_id'],
      )!,
      proficiency: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}proficiency'],
      )!,
      questionsAnswered: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}questions_answered'],
      )!,
      questionsCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}questions_correct'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $ConceptProficienciesTable createAlias(String alias) {
    return $ConceptProficienciesTable(attachedDatabase, alias);
  }
}

class ConceptProficiency extends DataClass
    implements Insertable<ConceptProficiency> {
  final int playerId;
  final String conceptId;
  final double proficiency;
  final int questionsAnswered;
  final int questionsCorrect;
  final DateTime lastUpdatedAt;
  const ConceptProficiency({
    required this.playerId,
    required this.conceptId,
    required this.proficiency,
    required this.questionsAnswered,
    required this.questionsCorrect,
    required this.lastUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['concept_id'] = Variable<String>(conceptId);
    map['proficiency'] = Variable<double>(proficiency);
    map['questions_answered'] = Variable<int>(questionsAnswered);
    map['questions_correct'] = Variable<int>(questionsCorrect);
    map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt);
    return map;
  }

  ConceptProficienciesCompanion toCompanion(bool nullToAbsent) {
    return ConceptProficienciesCompanion(
      playerId: Value(playerId),
      conceptId: Value(conceptId),
      proficiency: Value(proficiency),
      questionsAnswered: Value(questionsAnswered),
      questionsCorrect: Value(questionsCorrect),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory ConceptProficiency.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConceptProficiency(
      playerId: serializer.fromJson<int>(json['playerId']),
      conceptId: serializer.fromJson<String>(json['conceptId']),
      proficiency: serializer.fromJson<double>(json['proficiency']),
      questionsAnswered: serializer.fromJson<int>(json['questionsAnswered']),
      questionsCorrect: serializer.fromJson<int>(json['questionsCorrect']),
      lastUpdatedAt: serializer.fromJson<DateTime>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'conceptId': serializer.toJson<String>(conceptId),
      'proficiency': serializer.toJson<double>(proficiency),
      'questionsAnswered': serializer.toJson<int>(questionsAnswered),
      'questionsCorrect': serializer.toJson<int>(questionsCorrect),
      'lastUpdatedAt': serializer.toJson<DateTime>(lastUpdatedAt),
    };
  }

  ConceptProficiency copyWith({
    int? playerId,
    String? conceptId,
    double? proficiency,
    int? questionsAnswered,
    int? questionsCorrect,
    DateTime? lastUpdatedAt,
  }) => ConceptProficiency(
    playerId: playerId ?? this.playerId,
    conceptId: conceptId ?? this.conceptId,
    proficiency: proficiency ?? this.proficiency,
    questionsAnswered: questionsAnswered ?? this.questionsAnswered,
    questionsCorrect: questionsCorrect ?? this.questionsCorrect,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
  ConceptProficiency copyWithCompanion(ConceptProficienciesCompanion data) {
    return ConceptProficiency(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      conceptId: data.conceptId.present ? data.conceptId.value : this.conceptId,
      proficiency: data.proficiency.present
          ? data.proficiency.value
          : this.proficiency,
      questionsAnswered: data.questionsAnswered.present
          ? data.questionsAnswered.value
          : this.questionsAnswered,
      questionsCorrect: data.questionsCorrect.present
          ? data.questionsCorrect.value
          : this.questionsCorrect,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConceptProficiency(')
          ..write('playerId: $playerId, ')
          ..write('conceptId: $conceptId, ')
          ..write('proficiency: $proficiency, ')
          ..write('questionsAnswered: $questionsAnswered, ')
          ..write('questionsCorrect: $questionsCorrect, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    conceptId,
    proficiency,
    questionsAnswered,
    questionsCorrect,
    lastUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConceptProficiency &&
          other.playerId == this.playerId &&
          other.conceptId == this.conceptId &&
          other.proficiency == this.proficiency &&
          other.questionsAnswered == this.questionsAnswered &&
          other.questionsCorrect == this.questionsCorrect &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class ConceptProficienciesCompanion
    extends UpdateCompanion<ConceptProficiency> {
  final Value<int> playerId;
  final Value<String> conceptId;
  final Value<double> proficiency;
  final Value<int> questionsAnswered;
  final Value<int> questionsCorrect;
  final Value<DateTime> lastUpdatedAt;
  final Value<int> rowid;
  const ConceptProficienciesCompanion({
    this.playerId = const Value.absent(),
    this.conceptId = const Value.absent(),
    this.proficiency = const Value.absent(),
    this.questionsAnswered = const Value.absent(),
    this.questionsCorrect = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConceptProficienciesCompanion.insert({
    required int playerId,
    required String conceptId,
    required double proficiency,
    this.questionsAnswered = const Value.absent(),
    this.questionsCorrect = const Value.absent(),
    required DateTime lastUpdatedAt,
    this.rowid = const Value.absent(),
  }) : playerId = Value(playerId),
       conceptId = Value(conceptId),
       proficiency = Value(proficiency),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<ConceptProficiency> custom({
    Expression<int>? playerId,
    Expression<String>? conceptId,
    Expression<double>? proficiency,
    Expression<int>? questionsAnswered,
    Expression<int>? questionsCorrect,
    Expression<DateTime>? lastUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (conceptId != null) 'concept_id': conceptId,
      if (proficiency != null) 'proficiency': proficiency,
      if (questionsAnswered != null) 'questions_answered': questionsAnswered,
      if (questionsCorrect != null) 'questions_correct': questionsCorrect,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConceptProficienciesCompanion copyWith({
    Value<int>? playerId,
    Value<String>? conceptId,
    Value<double>? proficiency,
    Value<int>? questionsAnswered,
    Value<int>? questionsCorrect,
    Value<DateTime>? lastUpdatedAt,
    Value<int>? rowid,
  }) {
    return ConceptProficienciesCompanion(
      playerId: playerId ?? this.playerId,
      conceptId: conceptId ?? this.conceptId,
      proficiency: proficiency ?? this.proficiency,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (conceptId.present) {
      map['concept_id'] = Variable<String>(conceptId.value);
    }
    if (proficiency.present) {
      map['proficiency'] = Variable<double>(proficiency.value);
    }
    if (questionsAnswered.present) {
      map['questions_answered'] = Variable<int>(questionsAnswered.value);
    }
    if (questionsCorrect.present) {
      map['questions_correct'] = Variable<int>(questionsCorrect.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConceptProficienciesCompanion(')
          ..write('playerId: $playerId, ')
          ..write('conceptId: $conceptId, ')
          ..write('proficiency: $proficiency, ')
          ..write('questionsAnswered: $questionsAnswered, ')
          ..write('questionsCorrect: $questionsCorrect, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntroducedConceptsTable extends IntroducedConcepts
    with TableInfo<$IntroducedConceptsTable, IntroducedConcept> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntroducedConceptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _conceptIdMeta = const VerificationMeta(
    'conceptId',
  );
  @override
  late final GeneratedColumn<String> conceptId = GeneratedColumn<String>(
    'concept_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _introducedAtMeta = const VerificationMeta(
    'introducedAt',
  );
  @override
  late final GeneratedColumn<DateTime> introducedAt = GeneratedColumn<DateTime>(
    'introduced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playerId, conceptId, introducedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'introduced_concepts';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntroducedConcept> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('concept_id')) {
      context.handle(
        _conceptIdMeta,
        conceptId.isAcceptableOrUnknown(data['concept_id']!, _conceptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptIdMeta);
    }
    if (data.containsKey('introduced_at')) {
      context.handle(
        _introducedAtMeta,
        introducedAt.isAcceptableOrUnknown(
          data['introduced_at']!,
          _introducedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_introducedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, conceptId};
  @override
  IntroducedConcept map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntroducedConcept(
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      conceptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_id'],
      )!,
      introducedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}introduced_at'],
      )!,
    );
  }

  @override
  $IntroducedConceptsTable createAlias(String alias) {
    return $IntroducedConceptsTable(attachedDatabase, alias);
  }
}

class IntroducedConcept extends DataClass
    implements Insertable<IntroducedConcept> {
  final int playerId;
  final String conceptId;
  final DateTime introducedAt;
  const IntroducedConcept({
    required this.playerId,
    required this.conceptId,
    required this.introducedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['concept_id'] = Variable<String>(conceptId);
    map['introduced_at'] = Variable<DateTime>(introducedAt);
    return map;
  }

  IntroducedConceptsCompanion toCompanion(bool nullToAbsent) {
    return IntroducedConceptsCompanion(
      playerId: Value(playerId),
      conceptId: Value(conceptId),
      introducedAt: Value(introducedAt),
    );
  }

  factory IntroducedConcept.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntroducedConcept(
      playerId: serializer.fromJson<int>(json['playerId']),
      conceptId: serializer.fromJson<String>(json['conceptId']),
      introducedAt: serializer.fromJson<DateTime>(json['introducedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'conceptId': serializer.toJson<String>(conceptId),
      'introducedAt': serializer.toJson<DateTime>(introducedAt),
    };
  }

  IntroducedConcept copyWith({
    int? playerId,
    String? conceptId,
    DateTime? introducedAt,
  }) => IntroducedConcept(
    playerId: playerId ?? this.playerId,
    conceptId: conceptId ?? this.conceptId,
    introducedAt: introducedAt ?? this.introducedAt,
  );
  IntroducedConcept copyWithCompanion(IntroducedConceptsCompanion data) {
    return IntroducedConcept(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      conceptId: data.conceptId.present ? data.conceptId.value : this.conceptId,
      introducedAt: data.introducedAt.present
          ? data.introducedAt.value
          : this.introducedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntroducedConcept(')
          ..write('playerId: $playerId, ')
          ..write('conceptId: $conceptId, ')
          ..write('introducedAt: $introducedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, conceptId, introducedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntroducedConcept &&
          other.playerId == this.playerId &&
          other.conceptId == this.conceptId &&
          other.introducedAt == this.introducedAt);
}

class IntroducedConceptsCompanion extends UpdateCompanion<IntroducedConcept> {
  final Value<int> playerId;
  final Value<String> conceptId;
  final Value<DateTime> introducedAt;
  final Value<int> rowid;
  const IntroducedConceptsCompanion({
    this.playerId = const Value.absent(),
    this.conceptId = const Value.absent(),
    this.introducedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntroducedConceptsCompanion.insert({
    required int playerId,
    required String conceptId,
    required DateTime introducedAt,
    this.rowid = const Value.absent(),
  }) : playerId = Value(playerId),
       conceptId = Value(conceptId),
       introducedAt = Value(introducedAt);
  static Insertable<IntroducedConcept> custom({
    Expression<int>? playerId,
    Expression<String>? conceptId,
    Expression<DateTime>? introducedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (conceptId != null) 'concept_id': conceptId,
      if (introducedAt != null) 'introduced_at': introducedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntroducedConceptsCompanion copyWith({
    Value<int>? playerId,
    Value<String>? conceptId,
    Value<DateTime>? introducedAt,
    Value<int>? rowid,
  }) {
    return IntroducedConceptsCompanion(
      playerId: playerId ?? this.playerId,
      conceptId: conceptId ?? this.conceptId,
      introducedAt: introducedAt ?? this.introducedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (conceptId.present) {
      map['concept_id'] = Variable<String>(conceptId.value);
    }
    if (introducedAt.present) {
      map['introduced_at'] = Variable<DateTime>(introducedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntroducedConceptsCompanion(')
          ..write('playerId: $playerId, ')
          ..write('conceptId: $conceptId, ')
          ..write('introducedAt: $introducedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConceptsTable extends Concepts
    with TableInfo<$ConceptsTable, CatalogConcept> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConceptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _shortLabelMeta = const VerificationMeta(
    'shortLabel',
  );
  @override
  late final GeneratedColumn<String> shortLabel = GeneratedColumn<String>(
    'short_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryGradeMeta = const VerificationMeta(
    'primaryGrade',
  );
  @override
  late final GeneratedColumn<int> primaryGrade = GeneratedColumn<int>(
    'primary_grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prereqIdsCsvMeta = const VerificationMeta(
    'prereqIdsCsv',
  );
  @override
  late final GeneratedColumn<String> prereqIdsCsv = GeneratedColumn<String>(
    'prereq_ids_csv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceStrategyMeta = const VerificationMeta(
    'sourceStrategy',
  );
  @override
  late final GeneratedColumn<String> sourceStrategy = GeneratedColumn<String>(
    'source_strategy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diagramRequirementMeta =
      const VerificationMeta('diagramRequirement');
  @override
  late final GeneratedColumn<String> diagramRequirement =
      GeneratedColumn<String>(
        'diagram_requirement',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _categoryRowOrderMeta = const VerificationMeta(
    'categoryRowOrder',
  );
  @override
  late final GeneratedColumn<int> categoryRowOrder = GeneratedColumn<int>(
    'category_row_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    shortLabel,
    categoryId,
    primaryGrade,
    prereqIdsCsv,
    sourceStrategy,
    diagramRequirement,
    categoryRowOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'concepts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogConcept> instance, {
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
    if (data.containsKey('short_label')) {
      context.handle(
        _shortLabelMeta,
        shortLabel.isAcceptableOrUnknown(data['short_label']!, _shortLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_shortLabelMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('primary_grade')) {
      context.handle(
        _primaryGradeMeta,
        primaryGrade.isAcceptableOrUnknown(
          data['primary_grade']!,
          _primaryGradeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryGradeMeta);
    }
    if (data.containsKey('prereq_ids_csv')) {
      context.handle(
        _prereqIdsCsvMeta,
        prereqIdsCsv.isAcceptableOrUnknown(
          data['prereq_ids_csv']!,
          _prereqIdsCsvMeta,
        ),
      );
    }
    if (data.containsKey('source_strategy')) {
      context.handle(
        _sourceStrategyMeta,
        sourceStrategy.isAcceptableOrUnknown(
          data['source_strategy']!,
          _sourceStrategyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceStrategyMeta);
    }
    if (data.containsKey('diagram_requirement')) {
      context.handle(
        _diagramRequirementMeta,
        diagramRequirement.isAcceptableOrUnknown(
          data['diagram_requirement']!,
          _diagramRequirementMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_diagramRequirementMeta);
    }
    if (data.containsKey('category_row_order')) {
      context.handle(
        _categoryRowOrderMeta,
        categoryRowOrder.isAcceptableOrUnknown(
          data['category_row_order']!,
          _categoryRowOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryRowOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogConcept map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogConcept(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_label'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      primaryGrade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}primary_grade'],
      )!,
      prereqIdsCsv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prereq_ids_csv'],
      )!,
      sourceStrategy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_strategy'],
      )!,
      diagramRequirement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagram_requirement'],
      )!,
      categoryRowOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_row_order'],
      )!,
    );
  }

  @override
  $ConceptsTable createAlias(String alias) {
    return $ConceptsTable(attachedDatabase, alias);
  }
}

class CatalogConcept extends DataClass implements Insertable<CatalogConcept> {
  final String id;
  final String name;
  final String shortLabel;
  final String categoryId;
  final int primaryGrade;

  /// Comma-separated list of prereq concept IDs. Empty string = root node.
  final String prereqIdsCsv;
  final String sourceStrategy;
  final String diagramRequirement;
  final int categoryRowOrder;
  const CatalogConcept({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.categoryId,
    required this.primaryGrade,
    required this.prereqIdsCsv,
    required this.sourceStrategy,
    required this.diagramRequirement,
    required this.categoryRowOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['short_label'] = Variable<String>(shortLabel);
    map['category_id'] = Variable<String>(categoryId);
    map['primary_grade'] = Variable<int>(primaryGrade);
    map['prereq_ids_csv'] = Variable<String>(prereqIdsCsv);
    map['source_strategy'] = Variable<String>(sourceStrategy);
    map['diagram_requirement'] = Variable<String>(diagramRequirement);
    map['category_row_order'] = Variable<int>(categoryRowOrder);
    return map;
  }

  ConceptsCompanion toCompanion(bool nullToAbsent) {
    return ConceptsCompanion(
      id: Value(id),
      name: Value(name),
      shortLabel: Value(shortLabel),
      categoryId: Value(categoryId),
      primaryGrade: Value(primaryGrade),
      prereqIdsCsv: Value(prereqIdsCsv),
      sourceStrategy: Value(sourceStrategy),
      diagramRequirement: Value(diagramRequirement),
      categoryRowOrder: Value(categoryRowOrder),
    );
  }

  factory CatalogConcept.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogConcept(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      shortLabel: serializer.fromJson<String>(json['shortLabel']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      primaryGrade: serializer.fromJson<int>(json['primaryGrade']),
      prereqIdsCsv: serializer.fromJson<String>(json['prereqIdsCsv']),
      sourceStrategy: serializer.fromJson<String>(json['sourceStrategy']),
      diagramRequirement: serializer.fromJson<String>(
        json['diagramRequirement'],
      ),
      categoryRowOrder: serializer.fromJson<int>(json['categoryRowOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'shortLabel': serializer.toJson<String>(shortLabel),
      'categoryId': serializer.toJson<String>(categoryId),
      'primaryGrade': serializer.toJson<int>(primaryGrade),
      'prereqIdsCsv': serializer.toJson<String>(prereqIdsCsv),
      'sourceStrategy': serializer.toJson<String>(sourceStrategy),
      'diagramRequirement': serializer.toJson<String>(diagramRequirement),
      'categoryRowOrder': serializer.toJson<int>(categoryRowOrder),
    };
  }

  CatalogConcept copyWith({
    String? id,
    String? name,
    String? shortLabel,
    String? categoryId,
    int? primaryGrade,
    String? prereqIdsCsv,
    String? sourceStrategy,
    String? diagramRequirement,
    int? categoryRowOrder,
  }) => CatalogConcept(
    id: id ?? this.id,
    name: name ?? this.name,
    shortLabel: shortLabel ?? this.shortLabel,
    categoryId: categoryId ?? this.categoryId,
    primaryGrade: primaryGrade ?? this.primaryGrade,
    prereqIdsCsv: prereqIdsCsv ?? this.prereqIdsCsv,
    sourceStrategy: sourceStrategy ?? this.sourceStrategy,
    diagramRequirement: diagramRequirement ?? this.diagramRequirement,
    categoryRowOrder: categoryRowOrder ?? this.categoryRowOrder,
  );
  CatalogConcept copyWithCompanion(ConceptsCompanion data) {
    return CatalogConcept(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      shortLabel: data.shortLabel.present
          ? data.shortLabel.value
          : this.shortLabel,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      primaryGrade: data.primaryGrade.present
          ? data.primaryGrade.value
          : this.primaryGrade,
      prereqIdsCsv: data.prereqIdsCsv.present
          ? data.prereqIdsCsv.value
          : this.prereqIdsCsv,
      sourceStrategy: data.sourceStrategy.present
          ? data.sourceStrategy.value
          : this.sourceStrategy,
      diagramRequirement: data.diagramRequirement.present
          ? data.diagramRequirement.value
          : this.diagramRequirement,
      categoryRowOrder: data.categoryRowOrder.present
          ? data.categoryRowOrder.value
          : this.categoryRowOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogConcept(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortLabel: $shortLabel, ')
          ..write('categoryId: $categoryId, ')
          ..write('primaryGrade: $primaryGrade, ')
          ..write('prereqIdsCsv: $prereqIdsCsv, ')
          ..write('sourceStrategy: $sourceStrategy, ')
          ..write('diagramRequirement: $diagramRequirement, ')
          ..write('categoryRowOrder: $categoryRowOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    shortLabel,
    categoryId,
    primaryGrade,
    prereqIdsCsv,
    sourceStrategy,
    diagramRequirement,
    categoryRowOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogConcept &&
          other.id == this.id &&
          other.name == this.name &&
          other.shortLabel == this.shortLabel &&
          other.categoryId == this.categoryId &&
          other.primaryGrade == this.primaryGrade &&
          other.prereqIdsCsv == this.prereqIdsCsv &&
          other.sourceStrategy == this.sourceStrategy &&
          other.diagramRequirement == this.diagramRequirement &&
          other.categoryRowOrder == this.categoryRowOrder);
}

class ConceptsCompanion extends UpdateCompanion<CatalogConcept> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> shortLabel;
  final Value<String> categoryId;
  final Value<int> primaryGrade;
  final Value<String> prereqIdsCsv;
  final Value<String> sourceStrategy;
  final Value<String> diagramRequirement;
  final Value<int> categoryRowOrder;
  final Value<int> rowid;
  const ConceptsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.shortLabel = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.primaryGrade = const Value.absent(),
    this.prereqIdsCsv = const Value.absent(),
    this.sourceStrategy = const Value.absent(),
    this.diagramRequirement = const Value.absent(),
    this.categoryRowOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConceptsCompanion.insert({
    required String id,
    required String name,
    required String shortLabel,
    required String categoryId,
    required int primaryGrade,
    this.prereqIdsCsv = const Value.absent(),
    required String sourceStrategy,
    required String diagramRequirement,
    required int categoryRowOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       shortLabel = Value(shortLabel),
       categoryId = Value(categoryId),
       primaryGrade = Value(primaryGrade),
       sourceStrategy = Value(sourceStrategy),
       diagramRequirement = Value(diagramRequirement),
       categoryRowOrder = Value(categoryRowOrder);
  static Insertable<CatalogConcept> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? shortLabel,
    Expression<String>? categoryId,
    Expression<int>? primaryGrade,
    Expression<String>? prereqIdsCsv,
    Expression<String>? sourceStrategy,
    Expression<String>? diagramRequirement,
    Expression<int>? categoryRowOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (shortLabel != null) 'short_label': shortLabel,
      if (categoryId != null) 'category_id': categoryId,
      if (primaryGrade != null) 'primary_grade': primaryGrade,
      if (prereqIdsCsv != null) 'prereq_ids_csv': prereqIdsCsv,
      if (sourceStrategy != null) 'source_strategy': sourceStrategy,
      if (diagramRequirement != null) 'diagram_requirement': diagramRequirement,
      if (categoryRowOrder != null) 'category_row_order': categoryRowOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConceptsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? shortLabel,
    Value<String>? categoryId,
    Value<int>? primaryGrade,
    Value<String>? prereqIdsCsv,
    Value<String>? sourceStrategy,
    Value<String>? diagramRequirement,
    Value<int>? categoryRowOrder,
    Value<int>? rowid,
  }) {
    return ConceptsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      shortLabel: shortLabel ?? this.shortLabel,
      categoryId: categoryId ?? this.categoryId,
      primaryGrade: primaryGrade ?? this.primaryGrade,
      prereqIdsCsv: prereqIdsCsv ?? this.prereqIdsCsv,
      sourceStrategy: sourceStrategy ?? this.sourceStrategy,
      diagramRequirement: diagramRequirement ?? this.diagramRequirement,
      categoryRowOrder: categoryRowOrder ?? this.categoryRowOrder,
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
    if (shortLabel.present) {
      map['short_label'] = Variable<String>(shortLabel.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (primaryGrade.present) {
      map['primary_grade'] = Variable<int>(primaryGrade.value);
    }
    if (prereqIdsCsv.present) {
      map['prereq_ids_csv'] = Variable<String>(prereqIdsCsv.value);
    }
    if (sourceStrategy.present) {
      map['source_strategy'] = Variable<String>(sourceStrategy.value);
    }
    if (diagramRequirement.present) {
      map['diagram_requirement'] = Variable<String>(diagramRequirement.value);
    }
    if (categoryRowOrder.present) {
      map['category_row_order'] = Variable<int>(categoryRowOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConceptsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortLabel: $shortLabel, ')
          ..write('categoryId: $categoryId, ')
          ..write('primaryGrade: $primaryGrade, ')
          ..write('prereqIdsCsv: $prereqIdsCsv, ')
          ..write('sourceStrategy: $sourceStrategy, ')
          ..write('diagramRequirement: $diagramRequirement, ')
          ..write('categoryRowOrder: $categoryRowOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DatasetQuestionsTable extends DatasetQuestions
    with TableInfo<$DatasetQuestionsTable, DatasetQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptIdMeta = const VerificationMeta(
    'conceptId',
  );
  @override
  late final GeneratedColumn<String> conceptId = GeneratedColumn<String>(
    'concept_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctAnswerMeta = const VerificationMeta(
    'correctAnswer',
  );
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
    'correct_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distractorsJsonMeta = const VerificationMeta(
    'distractorsJson',
  );
  @override
  late final GeneratedColumn<String> distractorsJson = GeneratedColumn<String>(
    'distractors_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationJsonMeta = const VerificationMeta(
    'explanationJson',
  );
  @override
  late final GeneratedColumn<String> explanationJson = GeneratedColumn<String>(
    'explanation_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceModuleMeta = const VerificationMeta(
    'sourceModule',
  );
  @override
  late final GeneratedColumn<String> sourceModule = GeneratedColumn<String>(
    'source_module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _licenseMeta = const VerificationMeta(
    'license',
  );
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
    'license',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerFormatMeta = const VerificationMeta(
    'answerFormat',
  );
  @override
  late final GeneratedColumn<String> answerFormat = GeneratedColumn<String>(
    'answer_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('integer'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conceptId,
    prompt,
    correctAnswer,
    distractorsJson,
    explanationJson,
    source,
    sourceModule,
    license,
    answerFormat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DatasetQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('concept_id')) {
      context.handle(
        _conceptIdMeta,
        conceptId.isAcceptableOrUnknown(data['concept_id']!, _conceptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptIdMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
        _correctAnswerMeta,
        correctAnswer.isAcceptableOrUnknown(
          data['correct_answer']!,
          _correctAnswerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctAnswerMeta);
    }
    if (data.containsKey('distractors_json')) {
      context.handle(
        _distractorsJsonMeta,
        distractorsJson.isAcceptableOrUnknown(
          data['distractors_json']!,
          _distractorsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distractorsJsonMeta);
    }
    if (data.containsKey('explanation_json')) {
      context.handle(
        _explanationJsonMeta,
        explanationJson.isAcceptableOrUnknown(
          data['explanation_json']!,
          _explanationJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationJsonMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_module')) {
      context.handle(
        _sourceModuleMeta,
        sourceModule.isAcceptableOrUnknown(
          data['source_module']!,
          _sourceModuleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceModuleMeta);
    }
    if (data.containsKey('license')) {
      context.handle(
        _licenseMeta,
        license.isAcceptableOrUnknown(data['license']!, _licenseMeta),
      );
    } else if (isInserting) {
      context.missing(_licenseMeta);
    }
    if (data.containsKey('answer_format')) {
      context.handle(
        _answerFormatMeta,
        answerFormat.isAcceptableOrUnknown(
          data['answer_format']!,
          _answerFormatMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conceptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_id'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      correctAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_answer'],
      )!,
      distractorsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distractors_json'],
      )!,
      explanationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_json'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceModule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_module'],
      )!,
      license: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license'],
      )!,
      answerFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_format'],
      )!,
    );
  }

  @override
  $DatasetQuestionsTable createAlias(String alias) {
    return $DatasetQuestionsTable(attachedDatabase, alias);
  }
}

class DatasetQuestionRow extends DataClass
    implements Insertable<DatasetQuestionRow> {
  final String id;
  final String conceptId;
  final String prompt;
  final String correctAnswer;

  /// JSON-encoded `List<String>` of exactly three wrong answers.
  final String distractorsJson;

  /// JSON-encoded `List<String>` of 1–4 explanation lines.
  final String explanationJson;
  final String source;
  final String sourceModule;
  final String license;

  /// `AnswerFormat` enum name (e.g. `"integer"`, `"commaList"`). Carried
  /// into `DatasetQuestion.answerFormat` (and thence into the runtime
  /// `GeneratedQuestion`) at read time.
  final String answerFormat;
  const DatasetQuestionRow({
    required this.id,
    required this.conceptId,
    required this.prompt,
    required this.correctAnswer,
    required this.distractorsJson,
    required this.explanationJson,
    required this.source,
    required this.sourceModule,
    required this.license,
    required this.answerFormat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['concept_id'] = Variable<String>(conceptId);
    map['prompt'] = Variable<String>(prompt);
    map['correct_answer'] = Variable<String>(correctAnswer);
    map['distractors_json'] = Variable<String>(distractorsJson);
    map['explanation_json'] = Variable<String>(explanationJson);
    map['source'] = Variable<String>(source);
    map['source_module'] = Variable<String>(sourceModule);
    map['license'] = Variable<String>(license);
    map['answer_format'] = Variable<String>(answerFormat);
    return map;
  }

  DatasetQuestionsCompanion toCompanion(bool nullToAbsent) {
    return DatasetQuestionsCompanion(
      id: Value(id),
      conceptId: Value(conceptId),
      prompt: Value(prompt),
      correctAnswer: Value(correctAnswer),
      distractorsJson: Value(distractorsJson),
      explanationJson: Value(explanationJson),
      source: Value(source),
      sourceModule: Value(sourceModule),
      license: Value(license),
      answerFormat: Value(answerFormat),
    );
  }

  factory DatasetQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetQuestionRow(
      id: serializer.fromJson<String>(json['id']),
      conceptId: serializer.fromJson<String>(json['conceptId']),
      prompt: serializer.fromJson<String>(json['prompt']),
      correctAnswer: serializer.fromJson<String>(json['correctAnswer']),
      distractorsJson: serializer.fromJson<String>(json['distractorsJson']),
      explanationJson: serializer.fromJson<String>(json['explanationJson']),
      source: serializer.fromJson<String>(json['source']),
      sourceModule: serializer.fromJson<String>(json['sourceModule']),
      license: serializer.fromJson<String>(json['license']),
      answerFormat: serializer.fromJson<String>(json['answerFormat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conceptId': serializer.toJson<String>(conceptId),
      'prompt': serializer.toJson<String>(prompt),
      'correctAnswer': serializer.toJson<String>(correctAnswer),
      'distractorsJson': serializer.toJson<String>(distractorsJson),
      'explanationJson': serializer.toJson<String>(explanationJson),
      'source': serializer.toJson<String>(source),
      'sourceModule': serializer.toJson<String>(sourceModule),
      'license': serializer.toJson<String>(license),
      'answerFormat': serializer.toJson<String>(answerFormat),
    };
  }

  DatasetQuestionRow copyWith({
    String? id,
    String? conceptId,
    String? prompt,
    String? correctAnswer,
    String? distractorsJson,
    String? explanationJson,
    String? source,
    String? sourceModule,
    String? license,
    String? answerFormat,
  }) => DatasetQuestionRow(
    id: id ?? this.id,
    conceptId: conceptId ?? this.conceptId,
    prompt: prompt ?? this.prompt,
    correctAnswer: correctAnswer ?? this.correctAnswer,
    distractorsJson: distractorsJson ?? this.distractorsJson,
    explanationJson: explanationJson ?? this.explanationJson,
    source: source ?? this.source,
    sourceModule: sourceModule ?? this.sourceModule,
    license: license ?? this.license,
    answerFormat: answerFormat ?? this.answerFormat,
  );
  DatasetQuestionRow copyWithCompanion(DatasetQuestionsCompanion data) {
    return DatasetQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      conceptId: data.conceptId.present ? data.conceptId.value : this.conceptId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      distractorsJson: data.distractorsJson.present
          ? data.distractorsJson.value
          : this.distractorsJson,
      explanationJson: data.explanationJson.present
          ? data.explanationJson.value
          : this.explanationJson,
      source: data.source.present ? data.source.value : this.source,
      sourceModule: data.sourceModule.present
          ? data.sourceModule.value
          : this.sourceModule,
      license: data.license.present ? data.license.value : this.license,
      answerFormat: data.answerFormat.present
          ? data.answerFormat.value
          : this.answerFormat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetQuestionRow(')
          ..write('id: $id, ')
          ..write('conceptId: $conceptId, ')
          ..write('prompt: $prompt, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('distractorsJson: $distractorsJson, ')
          ..write('explanationJson: $explanationJson, ')
          ..write('source: $source, ')
          ..write('sourceModule: $sourceModule, ')
          ..write('license: $license, ')
          ..write('answerFormat: $answerFormat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conceptId,
    prompt,
    correctAnswer,
    distractorsJson,
    explanationJson,
    source,
    sourceModule,
    license,
    answerFormat,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetQuestionRow &&
          other.id == this.id &&
          other.conceptId == this.conceptId &&
          other.prompt == this.prompt &&
          other.correctAnswer == this.correctAnswer &&
          other.distractorsJson == this.distractorsJson &&
          other.explanationJson == this.explanationJson &&
          other.source == this.source &&
          other.sourceModule == this.sourceModule &&
          other.license == this.license &&
          other.answerFormat == this.answerFormat);
}

class DatasetQuestionsCompanion extends UpdateCompanion<DatasetQuestionRow> {
  final Value<String> id;
  final Value<String> conceptId;
  final Value<String> prompt;
  final Value<String> correctAnswer;
  final Value<String> distractorsJson;
  final Value<String> explanationJson;
  final Value<String> source;
  final Value<String> sourceModule;
  final Value<String> license;
  final Value<String> answerFormat;
  final Value<int> rowid;
  const DatasetQuestionsCompanion({
    this.id = const Value.absent(),
    this.conceptId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.distractorsJson = const Value.absent(),
    this.explanationJson = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceModule = const Value.absent(),
    this.license = const Value.absent(),
    this.answerFormat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatasetQuestionsCompanion.insert({
    required String id,
    required String conceptId,
    required String prompt,
    required String correctAnswer,
    required String distractorsJson,
    required String explanationJson,
    required String source,
    required String sourceModule,
    required String license,
    this.answerFormat = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conceptId = Value(conceptId),
       prompt = Value(prompt),
       correctAnswer = Value(correctAnswer),
       distractorsJson = Value(distractorsJson),
       explanationJson = Value(explanationJson),
       source = Value(source),
       sourceModule = Value(sourceModule),
       license = Value(license);
  static Insertable<DatasetQuestionRow> custom({
    Expression<String>? id,
    Expression<String>? conceptId,
    Expression<String>? prompt,
    Expression<String>? correctAnswer,
    Expression<String>? distractorsJson,
    Expression<String>? explanationJson,
    Expression<String>? source,
    Expression<String>? sourceModule,
    Expression<String>? license,
    Expression<String>? answerFormat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conceptId != null) 'concept_id': conceptId,
      if (prompt != null) 'prompt': prompt,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (distractorsJson != null) 'distractors_json': distractorsJson,
      if (explanationJson != null) 'explanation_json': explanationJson,
      if (source != null) 'source': source,
      if (sourceModule != null) 'source_module': sourceModule,
      if (license != null) 'license': license,
      if (answerFormat != null) 'answer_format': answerFormat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatasetQuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? conceptId,
    Value<String>? prompt,
    Value<String>? correctAnswer,
    Value<String>? distractorsJson,
    Value<String>? explanationJson,
    Value<String>? source,
    Value<String>? sourceModule,
    Value<String>? license,
    Value<String>? answerFormat,
    Value<int>? rowid,
  }) {
    return DatasetQuestionsCompanion(
      id: id ?? this.id,
      conceptId: conceptId ?? this.conceptId,
      prompt: prompt ?? this.prompt,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      distractorsJson: distractorsJson ?? this.distractorsJson,
      explanationJson: explanationJson ?? this.explanationJson,
      source: source ?? this.source,
      sourceModule: sourceModule ?? this.sourceModule,
      license: license ?? this.license,
      answerFormat: answerFormat ?? this.answerFormat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conceptId.present) {
      map['concept_id'] = Variable<String>(conceptId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (distractorsJson.present) {
      map['distractors_json'] = Variable<String>(distractorsJson.value);
    }
    if (explanationJson.present) {
      map['explanation_json'] = Variable<String>(explanationJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceModule.present) {
      map['source_module'] = Variable<String>(sourceModule.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (answerFormat.present) {
      map['answer_format'] = Variable<String>(answerFormat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('conceptId: $conceptId, ')
          ..write('prompt: $prompt, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('distractorsJson: $distractorsJson, ')
          ..write('explanationJson: $explanationJson, ')
          ..write('source: $source, ')
          ..write('sourceModule: $sourceModule, ')
          ..write('license: $license, ')
          ..write('answerFormat: $answerFormat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CitiesTable extends Cities with TableInfo<$CitiesTable, City> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CitiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _cityMapIdMeta = const VerificationMeta(
    'cityMapId',
  );
  @override
  late final GeneratedColumn<String> cityMapId = GeneratedColumn<String>(
    'city_map_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridWidthMeta = const VerificationMeta(
    'gridWidth',
  );
  @override
  late final GeneratedColumn<int> gridWidth = GeneratedColumn<int>(
    'grid_width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridHeightMeta = const VerificationMeta(
    'gridHeight',
  );
  @override
  late final GeneratedColumn<int> gridHeight = GeneratedColumn<int>(
    'grid_height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _populationMeta = const VerificationMeta(
    'population',
  );
  @override
  late final GeneratedColumn<int> population = GeneratedColumn<int>(
    'population',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playerId,
    cityMapId,
    gridWidth,
    gridHeight,
    population,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cities';
  @override
  VerificationContext validateIntegrity(
    Insertable<City> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('city_map_id')) {
      context.handle(
        _cityMapIdMeta,
        cityMapId.isAcceptableOrUnknown(data['city_map_id']!, _cityMapIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMapIdMeta);
    }
    if (data.containsKey('grid_width')) {
      context.handle(
        _gridWidthMeta,
        gridWidth.isAcceptableOrUnknown(data['grid_width']!, _gridWidthMeta),
      );
    } else if (isInserting) {
      context.missing(_gridWidthMeta);
    }
    if (data.containsKey('grid_height')) {
      context.handle(
        _gridHeightMeta,
        gridHeight.isAcceptableOrUnknown(data['grid_height']!, _gridHeightMeta),
      );
    } else if (isInserting) {
      context.missing(_gridHeightMeta);
    }
    if (data.containsKey('population')) {
      context.handle(
        _populationMeta,
        population.isAcceptableOrUnknown(data['population']!, _populationMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  City map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return City(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      cityMapId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city_map_id'],
      )!,
      gridWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_width'],
      )!,
      gridHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_height'],
      )!,
      population: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}population'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CitiesTable createAlias(String alias) {
    return $CitiesTable(attachedDatabase, alias);
  }
}

class City extends DataClass implements Insertable<City> {
  final int id;
  final int playerId;
  final String cityMapId;
  final int gridWidth;
  final int gridHeight;
  final int population;
  final DateTime createdAt;
  const City({
    required this.id,
    required this.playerId,
    required this.cityMapId,
    required this.gridWidth,
    required this.gridHeight,
    required this.population,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['city_map_id'] = Variable<String>(cityMapId);
    map['grid_width'] = Variable<int>(gridWidth);
    map['grid_height'] = Variable<int>(gridHeight);
    map['population'] = Variable<int>(population);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CitiesCompanion toCompanion(bool nullToAbsent) {
    return CitiesCompanion(
      id: Value(id),
      playerId: Value(playerId),
      cityMapId: Value(cityMapId),
      gridWidth: Value(gridWidth),
      gridHeight: Value(gridHeight),
      population: Value(population),
      createdAt: Value(createdAt),
    );
  }

  factory City.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return City(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      cityMapId: serializer.fromJson<String>(json['cityMapId']),
      gridWidth: serializer.fromJson<int>(json['gridWidth']),
      gridHeight: serializer.fromJson<int>(json['gridHeight']),
      population: serializer.fromJson<int>(json['population']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'cityMapId': serializer.toJson<String>(cityMapId),
      'gridWidth': serializer.toJson<int>(gridWidth),
      'gridHeight': serializer.toJson<int>(gridHeight),
      'population': serializer.toJson<int>(population),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  City copyWith({
    int? id,
    int? playerId,
    String? cityMapId,
    int? gridWidth,
    int? gridHeight,
    int? population,
    DateTime? createdAt,
  }) => City(
    id: id ?? this.id,
    playerId: playerId ?? this.playerId,
    cityMapId: cityMapId ?? this.cityMapId,
    gridWidth: gridWidth ?? this.gridWidth,
    gridHeight: gridHeight ?? this.gridHeight,
    population: population ?? this.population,
    createdAt: createdAt ?? this.createdAt,
  );
  City copyWithCompanion(CitiesCompanion data) {
    return City(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      cityMapId: data.cityMapId.present ? data.cityMapId.value : this.cityMapId,
      gridWidth: data.gridWidth.present ? data.gridWidth.value : this.gridWidth,
      gridHeight: data.gridHeight.present
          ? data.gridHeight.value
          : this.gridHeight,
      population: data.population.present
          ? data.population.value
          : this.population,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('City(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('cityMapId: $cityMapId, ')
          ..write('gridWidth: $gridWidth, ')
          ..write('gridHeight: $gridHeight, ')
          ..write('population: $population, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playerId,
    cityMapId,
    gridWidth,
    gridHeight,
    population,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is City &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.cityMapId == this.cityMapId &&
          other.gridWidth == this.gridWidth &&
          other.gridHeight == this.gridHeight &&
          other.population == this.population &&
          other.createdAt == this.createdAt);
}

class CitiesCompanion extends UpdateCompanion<City> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> cityMapId;
  final Value<int> gridWidth;
  final Value<int> gridHeight;
  final Value<int> population;
  final Value<DateTime> createdAt;
  const CitiesCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.cityMapId = const Value.absent(),
    this.gridWidth = const Value.absent(),
    this.gridHeight = const Value.absent(),
    this.population = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CitiesCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String cityMapId,
    required int gridWidth,
    required int gridHeight,
    this.population = const Value.absent(),
    required DateTime createdAt,
  }) : playerId = Value(playerId),
       cityMapId = Value(cityMapId),
       gridWidth = Value(gridWidth),
       gridHeight = Value(gridHeight),
       createdAt = Value(createdAt);
  static Insertable<City> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? cityMapId,
    Expression<int>? gridWidth,
    Expression<int>? gridHeight,
    Expression<int>? population,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (cityMapId != null) 'city_map_id': cityMapId,
      if (gridWidth != null) 'grid_width': gridWidth,
      if (gridHeight != null) 'grid_height': gridHeight,
      if (population != null) 'population': population,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CitiesCompanion copyWith({
    Value<int>? id,
    Value<int>? playerId,
    Value<String>? cityMapId,
    Value<int>? gridWidth,
    Value<int>? gridHeight,
    Value<int>? population,
    Value<DateTime>? createdAt,
  }) {
    return CitiesCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      cityMapId: cityMapId ?? this.cityMapId,
      gridWidth: gridWidth ?? this.gridWidth,
      gridHeight: gridHeight ?? this.gridHeight,
      population: population ?? this.population,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (cityMapId.present) {
      map['city_map_id'] = Variable<String>(cityMapId.value);
    }
    if (gridWidth.present) {
      map['grid_width'] = Variable<int>(gridWidth.value);
    }
    if (gridHeight.present) {
      map['grid_height'] = Variable<int>(gridHeight.value);
    }
    if (population.present) {
      map['population'] = Variable<int>(population.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CitiesCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('cityMapId: $cityMapId, ')
          ..write('gridWidth: $gridWidth, ')
          ..write('gridHeight: $gridHeight, ')
          ..write('population: $population, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BuildingPlacementsTable extends BuildingPlacements
    with TableInfo<$BuildingPlacementsTable, BuildingPlacement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildingPlacementsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<int> cityId = GeneratedColumn<int>(
    'city_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cities (id)',
    ),
  );
  static const VerificationMeta _buildingTypeIdMeta = const VerificationMeta(
    'buildingTypeId',
  );
  @override
  late final GeneratedColumn<String> buildingTypeId = GeneratedColumn<String>(
    'building_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentTierMeta = const VerificationMeta(
    'currentTier',
  );
  @override
  late final GeneratedColumn<int> currentTier = GeneratedColumn<int>(
    'current_tier',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gridXMeta = const VerificationMeta('gridX');
  @override
  late final GeneratedColumn<int> gridX = GeneratedColumn<int>(
    'grid_x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridYMeta = const VerificationMeta('gridY');
  @override
  late final GeneratedColumn<int> gridY = GeneratedColumn<int>(
    'grid_y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placedAtRoundMeta = const VerificationMeta(
    'placedAtRound',
  );
  @override
  late final GeneratedColumn<int> placedAtRound = GeneratedColumn<int>(
    'placed_at_round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cityId,
    buildingTypeId,
    currentTier,
    gridX,
    gridY,
    placedAtRound,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'building_placements';
  @override
  VerificationContext validateIntegrity(
    Insertable<BuildingPlacement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('city_id')) {
      context.handle(
        _cityIdMeta,
        cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cityIdMeta);
    }
    if (data.containsKey('building_type_id')) {
      context.handle(
        _buildingTypeIdMeta,
        buildingTypeId.isAcceptableOrUnknown(
          data['building_type_id']!,
          _buildingTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buildingTypeIdMeta);
    }
    if (data.containsKey('current_tier')) {
      context.handle(
        _currentTierMeta,
        currentTier.isAcceptableOrUnknown(
          data['current_tier']!,
          _currentTierMeta,
        ),
      );
    }
    if (data.containsKey('grid_x')) {
      context.handle(
        _gridXMeta,
        gridX.isAcceptableOrUnknown(data['grid_x']!, _gridXMeta),
      );
    } else if (isInserting) {
      context.missing(_gridXMeta);
    }
    if (data.containsKey('grid_y')) {
      context.handle(
        _gridYMeta,
        gridY.isAcceptableOrUnknown(data['grid_y']!, _gridYMeta),
      );
    } else if (isInserting) {
      context.missing(_gridYMeta);
    }
    if (data.containsKey('placed_at_round')) {
      context.handle(
        _placedAtRoundMeta,
        placedAtRound.isAcceptableOrUnknown(
          data['placed_at_round']!,
          _placedAtRoundMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_placedAtRoundMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BuildingPlacement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuildingPlacement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}city_id'],
      )!,
      buildingTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}building_type_id'],
      )!,
      currentTier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_tier'],
      )!,
      gridX: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_x'],
      )!,
      gridY: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_y'],
      )!,
      placedAtRound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}placed_at_round'],
      )!,
    );
  }

  @override
  $BuildingPlacementsTable createAlias(String alias) {
    return $BuildingPlacementsTable(attachedDatabase, alias);
  }
}

class BuildingPlacement extends DataClass
    implements Insertable<BuildingPlacement> {
  final int id;
  final int cityId;
  final String buildingTypeId;
  final int currentTier;
  final int gridX;
  final int gridY;
  final int placedAtRound;
  const BuildingPlacement({
    required this.id,
    required this.cityId,
    required this.buildingTypeId,
    required this.currentTier,
    required this.gridX,
    required this.gridY,
    required this.placedAtRound,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['city_id'] = Variable<int>(cityId);
    map['building_type_id'] = Variable<String>(buildingTypeId);
    map['current_tier'] = Variable<int>(currentTier);
    map['grid_x'] = Variable<int>(gridX);
    map['grid_y'] = Variable<int>(gridY);
    map['placed_at_round'] = Variable<int>(placedAtRound);
    return map;
  }

  BuildingPlacementsCompanion toCompanion(bool nullToAbsent) {
    return BuildingPlacementsCompanion(
      id: Value(id),
      cityId: Value(cityId),
      buildingTypeId: Value(buildingTypeId),
      currentTier: Value(currentTier),
      gridX: Value(gridX),
      gridY: Value(gridY),
      placedAtRound: Value(placedAtRound),
    );
  }

  factory BuildingPlacement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuildingPlacement(
      id: serializer.fromJson<int>(json['id']),
      cityId: serializer.fromJson<int>(json['cityId']),
      buildingTypeId: serializer.fromJson<String>(json['buildingTypeId']),
      currentTier: serializer.fromJson<int>(json['currentTier']),
      gridX: serializer.fromJson<int>(json['gridX']),
      gridY: serializer.fromJson<int>(json['gridY']),
      placedAtRound: serializer.fromJson<int>(json['placedAtRound']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cityId': serializer.toJson<int>(cityId),
      'buildingTypeId': serializer.toJson<String>(buildingTypeId),
      'currentTier': serializer.toJson<int>(currentTier),
      'gridX': serializer.toJson<int>(gridX),
      'gridY': serializer.toJson<int>(gridY),
      'placedAtRound': serializer.toJson<int>(placedAtRound),
    };
  }

  BuildingPlacement copyWith({
    int? id,
    int? cityId,
    String? buildingTypeId,
    int? currentTier,
    int? gridX,
    int? gridY,
    int? placedAtRound,
  }) => BuildingPlacement(
    id: id ?? this.id,
    cityId: cityId ?? this.cityId,
    buildingTypeId: buildingTypeId ?? this.buildingTypeId,
    currentTier: currentTier ?? this.currentTier,
    gridX: gridX ?? this.gridX,
    gridY: gridY ?? this.gridY,
    placedAtRound: placedAtRound ?? this.placedAtRound,
  );
  BuildingPlacement copyWithCompanion(BuildingPlacementsCompanion data) {
    return BuildingPlacement(
      id: data.id.present ? data.id.value : this.id,
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      buildingTypeId: data.buildingTypeId.present
          ? data.buildingTypeId.value
          : this.buildingTypeId,
      currentTier: data.currentTier.present
          ? data.currentTier.value
          : this.currentTier,
      gridX: data.gridX.present ? data.gridX.value : this.gridX,
      gridY: data.gridY.present ? data.gridY.value : this.gridY,
      placedAtRound: data.placedAtRound.present
          ? data.placedAtRound.value
          : this.placedAtRound,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuildingPlacement(')
          ..write('id: $id, ')
          ..write('cityId: $cityId, ')
          ..write('buildingTypeId: $buildingTypeId, ')
          ..write('currentTier: $currentTier, ')
          ..write('gridX: $gridX, ')
          ..write('gridY: $gridY, ')
          ..write('placedAtRound: $placedAtRound')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cityId,
    buildingTypeId,
    currentTier,
    gridX,
    gridY,
    placedAtRound,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildingPlacement &&
          other.id == this.id &&
          other.cityId == this.cityId &&
          other.buildingTypeId == this.buildingTypeId &&
          other.currentTier == this.currentTier &&
          other.gridX == this.gridX &&
          other.gridY == this.gridY &&
          other.placedAtRound == this.placedAtRound);
}

class BuildingPlacementsCompanion extends UpdateCompanion<BuildingPlacement> {
  final Value<int> id;
  final Value<int> cityId;
  final Value<String> buildingTypeId;
  final Value<int> currentTier;
  final Value<int> gridX;
  final Value<int> gridY;
  final Value<int> placedAtRound;
  const BuildingPlacementsCompanion({
    this.id = const Value.absent(),
    this.cityId = const Value.absent(),
    this.buildingTypeId = const Value.absent(),
    this.currentTier = const Value.absent(),
    this.gridX = const Value.absent(),
    this.gridY = const Value.absent(),
    this.placedAtRound = const Value.absent(),
  });
  BuildingPlacementsCompanion.insert({
    this.id = const Value.absent(),
    required int cityId,
    required String buildingTypeId,
    this.currentTier = const Value.absent(),
    required int gridX,
    required int gridY,
    required int placedAtRound,
  }) : cityId = Value(cityId),
       buildingTypeId = Value(buildingTypeId),
       gridX = Value(gridX),
       gridY = Value(gridY),
       placedAtRound = Value(placedAtRound);
  static Insertable<BuildingPlacement> custom({
    Expression<int>? id,
    Expression<int>? cityId,
    Expression<String>? buildingTypeId,
    Expression<int>? currentTier,
    Expression<int>? gridX,
    Expression<int>? gridY,
    Expression<int>? placedAtRound,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cityId != null) 'city_id': cityId,
      if (buildingTypeId != null) 'building_type_id': buildingTypeId,
      if (currentTier != null) 'current_tier': currentTier,
      if (gridX != null) 'grid_x': gridX,
      if (gridY != null) 'grid_y': gridY,
      if (placedAtRound != null) 'placed_at_round': placedAtRound,
    });
  }

  BuildingPlacementsCompanion copyWith({
    Value<int>? id,
    Value<int>? cityId,
    Value<String>? buildingTypeId,
    Value<int>? currentTier,
    Value<int>? gridX,
    Value<int>? gridY,
    Value<int>? placedAtRound,
  }) {
    return BuildingPlacementsCompanion(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      buildingTypeId: buildingTypeId ?? this.buildingTypeId,
      currentTier: currentTier ?? this.currentTier,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      placedAtRound: placedAtRound ?? this.placedAtRound,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cityId.present) {
      map['city_id'] = Variable<int>(cityId.value);
    }
    if (buildingTypeId.present) {
      map['building_type_id'] = Variable<String>(buildingTypeId.value);
    }
    if (currentTier.present) {
      map['current_tier'] = Variable<int>(currentTier.value);
    }
    if (gridX.present) {
      map['grid_x'] = Variable<int>(gridX.value);
    }
    if (gridY.present) {
      map['grid_y'] = Variable<int>(gridY.value);
    }
    if (placedAtRound.present) {
      map['placed_at_round'] = Variable<int>(placedAtRound.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildingPlacementsCompanion(')
          ..write('id: $id, ')
          ..write('cityId: $cityId, ')
          ..write('buildingTypeId: $buildingTypeId, ')
          ..write('currentTier: $currentTier, ')
          ..write('gridX: $gridX, ')
          ..write('gridY: $gridY, ')
          ..write('placedAtRound: $placedAtRound')
          ..write(')'))
        .toString();
  }
}

class $BuildingTypesResearchedTable extends BuildingTypesResearched
    with TableInfo<$BuildingTypesResearchedTable, BuildingTypesResearchedData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildingTypesResearchedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _buildingTypeIdMeta = const VerificationMeta(
    'buildingTypeId',
  );
  @override
  late final GeneratedColumn<String> buildingTypeId = GeneratedColumn<String>(
    'building_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _researchedAtMeta = const VerificationMeta(
    'researchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> researchedAt = GeneratedColumn<DateTime>(
    'researched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playerId,
    buildingTypeId,
    researchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'building_types_researched';
  @override
  VerificationContext validateIntegrity(
    Insertable<BuildingTypesResearchedData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('building_type_id')) {
      context.handle(
        _buildingTypeIdMeta,
        buildingTypeId.isAcceptableOrUnknown(
          data['building_type_id']!,
          _buildingTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buildingTypeIdMeta);
    }
    if (data.containsKey('researched_at')) {
      context.handle(
        _researchedAtMeta,
        researchedAt.isAcceptableOrUnknown(
          data['researched_at']!,
          _researchedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_researchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, buildingTypeId};
  @override
  BuildingTypesResearchedData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuildingTypesResearchedData(
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      buildingTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}building_type_id'],
      )!,
      researchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}researched_at'],
      )!,
    );
  }

  @override
  $BuildingTypesResearchedTable createAlias(String alias) {
    return $BuildingTypesResearchedTable(attachedDatabase, alias);
  }
}

class BuildingTypesResearchedData extends DataClass
    implements Insertable<BuildingTypesResearchedData> {
  final int playerId;
  final String buildingTypeId;
  final DateTime researchedAt;
  const BuildingTypesResearchedData({
    required this.playerId,
    required this.buildingTypeId,
    required this.researchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['building_type_id'] = Variable<String>(buildingTypeId);
    map['researched_at'] = Variable<DateTime>(researchedAt);
    return map;
  }

  BuildingTypesResearchedCompanion toCompanion(bool nullToAbsent) {
    return BuildingTypesResearchedCompanion(
      playerId: Value(playerId),
      buildingTypeId: Value(buildingTypeId),
      researchedAt: Value(researchedAt),
    );
  }

  factory BuildingTypesResearchedData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuildingTypesResearchedData(
      playerId: serializer.fromJson<int>(json['playerId']),
      buildingTypeId: serializer.fromJson<String>(json['buildingTypeId']),
      researchedAt: serializer.fromJson<DateTime>(json['researchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'buildingTypeId': serializer.toJson<String>(buildingTypeId),
      'researchedAt': serializer.toJson<DateTime>(researchedAt),
    };
  }

  BuildingTypesResearchedData copyWith({
    int? playerId,
    String? buildingTypeId,
    DateTime? researchedAt,
  }) => BuildingTypesResearchedData(
    playerId: playerId ?? this.playerId,
    buildingTypeId: buildingTypeId ?? this.buildingTypeId,
    researchedAt: researchedAt ?? this.researchedAt,
  );
  BuildingTypesResearchedData copyWithCompanion(
    BuildingTypesResearchedCompanion data,
  ) {
    return BuildingTypesResearchedData(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      buildingTypeId: data.buildingTypeId.present
          ? data.buildingTypeId.value
          : this.buildingTypeId,
      researchedAt: data.researchedAt.present
          ? data.researchedAt.value
          : this.researchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuildingTypesResearchedData(')
          ..write('playerId: $playerId, ')
          ..write('buildingTypeId: $buildingTypeId, ')
          ..write('researchedAt: $researchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, buildingTypeId, researchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildingTypesResearchedData &&
          other.playerId == this.playerId &&
          other.buildingTypeId == this.buildingTypeId &&
          other.researchedAt == this.researchedAt);
}

class BuildingTypesResearchedCompanion
    extends UpdateCompanion<BuildingTypesResearchedData> {
  final Value<int> playerId;
  final Value<String> buildingTypeId;
  final Value<DateTime> researchedAt;
  final Value<int> rowid;
  const BuildingTypesResearchedCompanion({
    this.playerId = const Value.absent(),
    this.buildingTypeId = const Value.absent(),
    this.researchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildingTypesResearchedCompanion.insert({
    required int playerId,
    required String buildingTypeId,
    required DateTime researchedAt,
    this.rowid = const Value.absent(),
  }) : playerId = Value(playerId),
       buildingTypeId = Value(buildingTypeId),
       researchedAt = Value(researchedAt);
  static Insertable<BuildingTypesResearchedData> custom({
    Expression<int>? playerId,
    Expression<String>? buildingTypeId,
    Expression<DateTime>? researchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (buildingTypeId != null) 'building_type_id': buildingTypeId,
      if (researchedAt != null) 'researched_at': researchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildingTypesResearchedCompanion copyWith({
    Value<int>? playerId,
    Value<String>? buildingTypeId,
    Value<DateTime>? researchedAt,
    Value<int>? rowid,
  }) {
    return BuildingTypesResearchedCompanion(
      playerId: playerId ?? this.playerId,
      buildingTypeId: buildingTypeId ?? this.buildingTypeId,
      researchedAt: researchedAt ?? this.researchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (buildingTypeId.present) {
      map['building_type_id'] = Variable<String>(buildingTypeId.value);
    }
    if (researchedAt.present) {
      map['researched_at'] = Variable<DateTime>(researchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildingTypesResearchedCompanion(')
          ..write('playerId: $playerId, ')
          ..write('buildingTypeId: $buildingTypeId, ')
          ..write('researchedAt: $researchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConceptBandMilestonesTable extends ConceptBandMilestones
    with TableInfo<$ConceptBandMilestonesTable, ConceptBandMilestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConceptBandMilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _conceptIdMeta = const VerificationMeta(
    'conceptId',
  );
  @override
  late final GeneratedColumn<String> conceptId = GeneratedColumn<String>(
    'concept_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bandIndexMeta = const VerificationMeta(
    'bandIndex',
  );
  @override
  late final GeneratedColumn<int> bandIndex = GeneratedColumn<int>(
    'band_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _awardedAtMeta = const VerificationMeta(
    'awardedAt',
  );
  @override
  late final GeneratedColumn<DateTime> awardedAt = GeneratedColumn<DateTime>(
    'awarded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playerId,
    conceptId,
    bandIndex,
    awardedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'concept_band_milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConceptBandMilestone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('concept_id')) {
      context.handle(
        _conceptIdMeta,
        conceptId.isAcceptableOrUnknown(data['concept_id']!, _conceptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptIdMeta);
    }
    if (data.containsKey('band_index')) {
      context.handle(
        _bandIndexMeta,
        bandIndex.isAcceptableOrUnknown(data['band_index']!, _bandIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_bandIndexMeta);
    }
    if (data.containsKey('awarded_at')) {
      context.handle(
        _awardedAtMeta,
        awardedAt.isAcceptableOrUnknown(data['awarded_at']!, _awardedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_awardedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, conceptId, bandIndex};
  @override
  ConceptBandMilestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConceptBandMilestone(
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      conceptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_id'],
      )!,
      bandIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}band_index'],
      )!,
      awardedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}awarded_at'],
      )!,
    );
  }

  @override
  $ConceptBandMilestonesTable createAlias(String alias) {
    return $ConceptBandMilestonesTable(attachedDatabase, alias);
  }
}

class ConceptBandMilestone extends DataClass
    implements Insertable<ConceptBandMilestone> {
  final int playerId;
  final String conceptId;
  final int bandIndex;
  final DateTime awardedAt;
  const ConceptBandMilestone({
    required this.playerId,
    required this.conceptId,
    required this.bandIndex,
    required this.awardedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['concept_id'] = Variable<String>(conceptId);
    map['band_index'] = Variable<int>(bandIndex);
    map['awarded_at'] = Variable<DateTime>(awardedAt);
    return map;
  }

  ConceptBandMilestonesCompanion toCompanion(bool nullToAbsent) {
    return ConceptBandMilestonesCompanion(
      playerId: Value(playerId),
      conceptId: Value(conceptId),
      bandIndex: Value(bandIndex),
      awardedAt: Value(awardedAt),
    );
  }

  factory ConceptBandMilestone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConceptBandMilestone(
      playerId: serializer.fromJson<int>(json['playerId']),
      conceptId: serializer.fromJson<String>(json['conceptId']),
      bandIndex: serializer.fromJson<int>(json['bandIndex']),
      awardedAt: serializer.fromJson<DateTime>(json['awardedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'conceptId': serializer.toJson<String>(conceptId),
      'bandIndex': serializer.toJson<int>(bandIndex),
      'awardedAt': serializer.toJson<DateTime>(awardedAt),
    };
  }

  ConceptBandMilestone copyWith({
    int? playerId,
    String? conceptId,
    int? bandIndex,
    DateTime? awardedAt,
  }) => ConceptBandMilestone(
    playerId: playerId ?? this.playerId,
    conceptId: conceptId ?? this.conceptId,
    bandIndex: bandIndex ?? this.bandIndex,
    awardedAt: awardedAt ?? this.awardedAt,
  );
  ConceptBandMilestone copyWithCompanion(ConceptBandMilestonesCompanion data) {
    return ConceptBandMilestone(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      conceptId: data.conceptId.present ? data.conceptId.value : this.conceptId,
      bandIndex: data.bandIndex.present ? data.bandIndex.value : this.bandIndex,
      awardedAt: data.awardedAt.present ? data.awardedAt.value : this.awardedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConceptBandMilestone(')
          ..write('playerId: $playerId, ')
          ..write('conceptId: $conceptId, ')
          ..write('bandIndex: $bandIndex, ')
          ..write('awardedAt: $awardedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, conceptId, bandIndex, awardedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConceptBandMilestone &&
          other.playerId == this.playerId &&
          other.conceptId == this.conceptId &&
          other.bandIndex == this.bandIndex &&
          other.awardedAt == this.awardedAt);
}

class ConceptBandMilestonesCompanion
    extends UpdateCompanion<ConceptBandMilestone> {
  final Value<int> playerId;
  final Value<String> conceptId;
  final Value<int> bandIndex;
  final Value<DateTime> awardedAt;
  final Value<int> rowid;
  const ConceptBandMilestonesCompanion({
    this.playerId = const Value.absent(),
    this.conceptId = const Value.absent(),
    this.bandIndex = const Value.absent(),
    this.awardedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConceptBandMilestonesCompanion.insert({
    required int playerId,
    required String conceptId,
    required int bandIndex,
    required DateTime awardedAt,
    this.rowid = const Value.absent(),
  }) : playerId = Value(playerId),
       conceptId = Value(conceptId),
       bandIndex = Value(bandIndex),
       awardedAt = Value(awardedAt);
  static Insertable<ConceptBandMilestone> custom({
    Expression<int>? playerId,
    Expression<String>? conceptId,
    Expression<int>? bandIndex,
    Expression<DateTime>? awardedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (conceptId != null) 'concept_id': conceptId,
      if (bandIndex != null) 'band_index': bandIndex,
      if (awardedAt != null) 'awarded_at': awardedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConceptBandMilestonesCompanion copyWith({
    Value<int>? playerId,
    Value<String>? conceptId,
    Value<int>? bandIndex,
    Value<DateTime>? awardedAt,
    Value<int>? rowid,
  }) {
    return ConceptBandMilestonesCompanion(
      playerId: playerId ?? this.playerId,
      conceptId: conceptId ?? this.conceptId,
      bandIndex: bandIndex ?? this.bandIndex,
      awardedAt: awardedAt ?? this.awardedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (conceptId.present) {
      map['concept_id'] = Variable<String>(conceptId.value);
    }
    if (bandIndex.present) {
      map['band_index'] = Variable<int>(bandIndex.value);
    }
    if (awardedAt.present) {
      map['awarded_at'] = Variable<DateTime>(awardedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConceptBandMilestonesCompanion(')
          ..write('playerId: $playerId, ')
          ..write('conceptId: $conceptId, ')
          ..write('bandIndex: $bandIndex, ')
          ..write('awardedAt: $awardedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoryBeatStatesTable extends StoryBeatStates
    with TableInfo<$StoryBeatStatesTable, StoryBeatState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryBeatStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _beatIdMeta = const VerificationMeta('beatId');
  @override
  late final GeneratedColumn<String> beatId = GeneratedColumn<String>(
    'beat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFiredAtRoundMeta = const VerificationMeta(
    'lastFiredAtRound',
  );
  @override
  late final GeneratedColumn<int> lastFiredAtRound = GeneratedColumn<int>(
    'last_fired_at_round',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fireCountMeta = const VerificationMeta(
    'fireCount',
  );
  @override
  late final GeneratedColumn<int> fireCount = GeneratedColumn<int>(
    'fire_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lifetimeBricksAtLastFireMeta =
      const VerificationMeta('lifetimeBricksAtLastFire');
  @override
  late final GeneratedColumn<int> lifetimeBricksAtLastFire =
      GeneratedColumn<int>(
        'lifetime_bricks_at_last_fire',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    playerId,
    beatId,
    state,
    lastFiredAtRound,
    fireCount,
    lifetimeBricksAtLastFire,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_beat_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryBeatState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('beat_id')) {
      context.handle(
        _beatIdMeta,
        beatId.isAcceptableOrUnknown(data['beat_id']!, _beatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_beatIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('last_fired_at_round')) {
      context.handle(
        _lastFiredAtRoundMeta,
        lastFiredAtRound.isAcceptableOrUnknown(
          data['last_fired_at_round']!,
          _lastFiredAtRoundMeta,
        ),
      );
    }
    if (data.containsKey('fire_count')) {
      context.handle(
        _fireCountMeta,
        fireCount.isAcceptableOrUnknown(data['fire_count']!, _fireCountMeta),
      );
    }
    if (data.containsKey('lifetime_bricks_at_last_fire')) {
      context.handle(
        _lifetimeBricksAtLastFireMeta,
        lifetimeBricksAtLastFire.isAcceptableOrUnknown(
          data['lifetime_bricks_at_last_fire']!,
          _lifetimeBricksAtLastFireMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, beatId};
  @override
  StoryBeatState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryBeatState(
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      beatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beat_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      lastFiredAtRound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_fired_at_round'],
      ),
      fireCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fire_count'],
      )!,
      lifetimeBricksAtLastFire: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lifetime_bricks_at_last_fire'],
      ),
    );
  }

  @override
  $StoryBeatStatesTable createAlias(String alias) {
    return $StoryBeatStatesTable(attachedDatabase, alias);
  }
}

class StoryBeatState extends DataClass implements Insertable<StoryBeatState> {
  final int playerId;
  final String beatId;
  final String state;
  final int? lastFiredAtRound;
  final int fireCount;
  final int? lifetimeBricksAtLastFire;
  const StoryBeatState({
    required this.playerId,
    required this.beatId,
    required this.state,
    this.lastFiredAtRound,
    required this.fireCount,
    this.lifetimeBricksAtLastFire,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['beat_id'] = Variable<String>(beatId);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || lastFiredAtRound != null) {
      map['last_fired_at_round'] = Variable<int>(lastFiredAtRound);
    }
    map['fire_count'] = Variable<int>(fireCount);
    if (!nullToAbsent || lifetimeBricksAtLastFire != null) {
      map['lifetime_bricks_at_last_fire'] = Variable<int>(
        lifetimeBricksAtLastFire,
      );
    }
    return map;
  }

  StoryBeatStatesCompanion toCompanion(bool nullToAbsent) {
    return StoryBeatStatesCompanion(
      playerId: Value(playerId),
      beatId: Value(beatId),
      state: Value(state),
      lastFiredAtRound: lastFiredAtRound == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFiredAtRound),
      fireCount: Value(fireCount),
      lifetimeBricksAtLastFire: lifetimeBricksAtLastFire == null && nullToAbsent
          ? const Value.absent()
          : Value(lifetimeBricksAtLastFire),
    );
  }

  factory StoryBeatState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryBeatState(
      playerId: serializer.fromJson<int>(json['playerId']),
      beatId: serializer.fromJson<String>(json['beatId']),
      state: serializer.fromJson<String>(json['state']),
      lastFiredAtRound: serializer.fromJson<int?>(json['lastFiredAtRound']),
      fireCount: serializer.fromJson<int>(json['fireCount']),
      lifetimeBricksAtLastFire: serializer.fromJson<int?>(
        json['lifetimeBricksAtLastFire'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'beatId': serializer.toJson<String>(beatId),
      'state': serializer.toJson<String>(state),
      'lastFiredAtRound': serializer.toJson<int?>(lastFiredAtRound),
      'fireCount': serializer.toJson<int>(fireCount),
      'lifetimeBricksAtLastFire': serializer.toJson<int?>(
        lifetimeBricksAtLastFire,
      ),
    };
  }

  StoryBeatState copyWith({
    int? playerId,
    String? beatId,
    String? state,
    Value<int?> lastFiredAtRound = const Value.absent(),
    int? fireCount,
    Value<int?> lifetimeBricksAtLastFire = const Value.absent(),
  }) => StoryBeatState(
    playerId: playerId ?? this.playerId,
    beatId: beatId ?? this.beatId,
    state: state ?? this.state,
    lastFiredAtRound: lastFiredAtRound.present
        ? lastFiredAtRound.value
        : this.lastFiredAtRound,
    fireCount: fireCount ?? this.fireCount,
    lifetimeBricksAtLastFire: lifetimeBricksAtLastFire.present
        ? lifetimeBricksAtLastFire.value
        : this.lifetimeBricksAtLastFire,
  );
  StoryBeatState copyWithCompanion(StoryBeatStatesCompanion data) {
    return StoryBeatState(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      beatId: data.beatId.present ? data.beatId.value : this.beatId,
      state: data.state.present ? data.state.value : this.state,
      lastFiredAtRound: data.lastFiredAtRound.present
          ? data.lastFiredAtRound.value
          : this.lastFiredAtRound,
      fireCount: data.fireCount.present ? data.fireCount.value : this.fireCount,
      lifetimeBricksAtLastFire: data.lifetimeBricksAtLastFire.present
          ? data.lifetimeBricksAtLastFire.value
          : this.lifetimeBricksAtLastFire,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryBeatState(')
          ..write('playerId: $playerId, ')
          ..write('beatId: $beatId, ')
          ..write('state: $state, ')
          ..write('lastFiredAtRound: $lastFiredAtRound, ')
          ..write('fireCount: $fireCount, ')
          ..write('lifetimeBricksAtLastFire: $lifetimeBricksAtLastFire')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    beatId,
    state,
    lastFiredAtRound,
    fireCount,
    lifetimeBricksAtLastFire,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryBeatState &&
          other.playerId == this.playerId &&
          other.beatId == this.beatId &&
          other.state == this.state &&
          other.lastFiredAtRound == this.lastFiredAtRound &&
          other.fireCount == this.fireCount &&
          other.lifetimeBricksAtLastFire == this.lifetimeBricksAtLastFire);
}

class StoryBeatStatesCompanion extends UpdateCompanion<StoryBeatState> {
  final Value<int> playerId;
  final Value<String> beatId;
  final Value<String> state;
  final Value<int?> lastFiredAtRound;
  final Value<int> fireCount;
  final Value<int?> lifetimeBricksAtLastFire;
  final Value<int> rowid;
  const StoryBeatStatesCompanion({
    this.playerId = const Value.absent(),
    this.beatId = const Value.absent(),
    this.state = const Value.absent(),
    this.lastFiredAtRound = const Value.absent(),
    this.fireCount = const Value.absent(),
    this.lifetimeBricksAtLastFire = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoryBeatStatesCompanion.insert({
    required int playerId,
    required String beatId,
    required String state,
    this.lastFiredAtRound = const Value.absent(),
    this.fireCount = const Value.absent(),
    this.lifetimeBricksAtLastFire = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playerId = Value(playerId),
       beatId = Value(beatId),
       state = Value(state);
  static Insertable<StoryBeatState> custom({
    Expression<int>? playerId,
    Expression<String>? beatId,
    Expression<String>? state,
    Expression<int>? lastFiredAtRound,
    Expression<int>? fireCount,
    Expression<int>? lifetimeBricksAtLastFire,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (beatId != null) 'beat_id': beatId,
      if (state != null) 'state': state,
      if (lastFiredAtRound != null) 'last_fired_at_round': lastFiredAtRound,
      if (fireCount != null) 'fire_count': fireCount,
      if (lifetimeBricksAtLastFire != null)
        'lifetime_bricks_at_last_fire': lifetimeBricksAtLastFire,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoryBeatStatesCompanion copyWith({
    Value<int>? playerId,
    Value<String>? beatId,
    Value<String>? state,
    Value<int?>? lastFiredAtRound,
    Value<int>? fireCount,
    Value<int?>? lifetimeBricksAtLastFire,
    Value<int>? rowid,
  }) {
    return StoryBeatStatesCompanion(
      playerId: playerId ?? this.playerId,
      beatId: beatId ?? this.beatId,
      state: state ?? this.state,
      lastFiredAtRound: lastFiredAtRound ?? this.lastFiredAtRound,
      fireCount: fireCount ?? this.fireCount,
      lifetimeBricksAtLastFire:
          lifetimeBricksAtLastFire ?? this.lifetimeBricksAtLastFire,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (beatId.present) {
      map['beat_id'] = Variable<String>(beatId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (lastFiredAtRound.present) {
      map['last_fired_at_round'] = Variable<int>(lastFiredAtRound.value);
    }
    if (fireCount.present) {
      map['fire_count'] = Variable<int>(fireCount.value);
    }
    if (lifetimeBricksAtLastFire.present) {
      map['lifetime_bricks_at_last_fire'] = Variable<int>(
        lifetimeBricksAtLastFire.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryBeatStatesCompanion(')
          ..write('playerId: $playerId, ')
          ..write('beatId: $beatId, ')
          ..write('state: $state, ')
          ..write('lastFiredAtRound: $lastFiredAtRound, ')
          ..write('fireCount: $fireCount, ')
          ..write('lifetimeBricksAtLastFire: $lifetimeBricksAtLastFire, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $ConceptProficienciesTable conceptProficiencies =
      $ConceptProficienciesTable(this);
  late final $IntroducedConceptsTable introducedConcepts =
      $IntroducedConceptsTable(this);
  late final $ConceptsTable concepts = $ConceptsTable(this);
  late final $DatasetQuestionsTable datasetQuestions = $DatasetQuestionsTable(
    this,
  );
  late final $CitiesTable cities = $CitiesTable(this);
  late final $BuildingPlacementsTable buildingPlacements =
      $BuildingPlacementsTable(this);
  late final $BuildingTypesResearchedTable buildingTypesResearched =
      $BuildingTypesResearchedTable(this);
  late final $ConceptBandMilestonesTable conceptBandMilestones =
      $ConceptBandMilestonesTable(this);
  late final $StoryBeatStatesTable storyBeatStates = $StoryBeatStatesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    players,
    conceptProficiencies,
    introducedConcepts,
    concepts,
    datasetQuestions,
    cities,
    buildingPlacements,
    buildingTypesResearched,
    conceptBandMilestones,
    storyBeatStates,
  ];
}

typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      required String name,
      required int gradeLevel,
      Value<int> brickBalance,
      Value<int> lifetimeBricksEarned,
      Value<int> researchBalance,
      Value<int> lifetimeResearchEarned,
      required DateTime createdAt,
      Value<String?> avatarConfig,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> gradeLevel,
      Value<int> brickBalance,
      Value<int> lifetimeBricksEarned,
      Value<int> researchBalance,
      Value<int> lifetimeResearchEarned,
      Value<DateTime> createdAt,
      Value<String?> avatarConfig,
    });

final class $$PlayersTableReferences
    extends BaseReferences<_$AppDatabase, $PlayersTable, Player> {
  $$PlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ConceptProficienciesTable,
    List<ConceptProficiency>
  >
  _conceptProficienciesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conceptProficiencies,
        aliasName: $_aliasNameGenerator(
          db.players.id,
          db.conceptProficiencies.playerId,
        ),
      );

  $$ConceptProficienciesTableProcessedTableManager
  get conceptProficienciesRefs {
    final manager = $$ConceptProficienciesTableTableManager(
      $_db,
      $_db.conceptProficiencies,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conceptProficienciesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IntroducedConceptsTable, List<IntroducedConcept>>
  _introducedConceptsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.introducedConcepts,
        aliasName: $_aliasNameGenerator(
          db.players.id,
          db.introducedConcepts.playerId,
        ),
      );

  $$IntroducedConceptsTableProcessedTableManager get introducedConceptsRefs {
    final manager = $$IntroducedConceptsTableTableManager(
      $_db,
      $_db.introducedConcepts,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _introducedConceptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CitiesTable, List<City>> _citiesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cities,
    aliasName: $_aliasNameGenerator(db.players.id, db.cities.playerId),
  );

  $$CitiesTableProcessedTableManager get citiesRefs {
    final manager = $$CitiesTableTableManager(
      $_db,
      $_db.cities,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_citiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $BuildingTypesResearchedTable,
    List<BuildingTypesResearchedData>
  >
  _buildingTypesResearchedRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.buildingTypesResearched,
        aliasName: $_aliasNameGenerator(
          db.players.id,
          db.buildingTypesResearched.playerId,
        ),
      );

  $$BuildingTypesResearchedTableProcessedTableManager
  get buildingTypesResearchedRefs {
    final manager = $$BuildingTypesResearchedTableTableManager(
      $_db,
      $_db.buildingTypesResearched,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _buildingTypesResearchedRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConceptBandMilestonesTable,
    List<ConceptBandMilestone>
  >
  _conceptBandMilestonesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conceptBandMilestones,
        aliasName: $_aliasNameGenerator(
          db.players.id,
          db.conceptBandMilestones.playerId,
        ),
      );

  $$ConceptBandMilestonesTableProcessedTableManager
  get conceptBandMilestonesRefs {
    final manager = $$ConceptBandMilestonesTableTableManager(
      $_db,
      $_db.conceptBandMilestones,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conceptBandMilestonesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoryBeatStatesTable, List<StoryBeatState>>
  _storyBeatStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyBeatStates,
    aliasName: $_aliasNameGenerator(db.players.id, db.storyBeatStates.playerId),
  );

  $$StoryBeatStatesTableProcessedTableManager get storyBeatStatesRefs {
    final manager = $$StoryBeatStatesTableTableManager(
      $_db,
      $_db.storyBeatStates,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _storyBeatStatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
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

  ColumnFilters<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get brickBalance => $composableBuilder(
    column: $table.brickBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lifetimeBricksEarned => $composableBuilder(
    column: $table.lifetimeBricksEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get researchBalance => $composableBuilder(
    column: $table.researchBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lifetimeResearchEarned => $composableBuilder(
    column: $table.lifetimeResearchEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarConfig => $composableBuilder(
    column: $table.avatarConfig,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> conceptProficienciesRefs(
    Expression<bool> Function($$ConceptProficienciesTableFilterComposer f) f,
  ) {
    final $$ConceptProficienciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conceptProficiencies,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConceptProficienciesTableFilterComposer(
            $db: $db,
            $table: $db.conceptProficiencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> introducedConceptsRefs(
    Expression<bool> Function($$IntroducedConceptsTableFilterComposer f) f,
  ) {
    final $$IntroducedConceptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.introducedConcepts,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntroducedConceptsTableFilterComposer(
            $db: $db,
            $table: $db.introducedConcepts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> citiesRefs(
    Expression<bool> Function($$CitiesTableFilterComposer f) f,
  ) {
    final $$CitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cities,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CitiesTableFilterComposer(
            $db: $db,
            $table: $db.cities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> buildingTypesResearchedRefs(
    Expression<bool> Function($$BuildingTypesResearchedTableFilterComposer f) f,
  ) {
    final $$BuildingTypesResearchedTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.buildingTypesResearched,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BuildingTypesResearchedTableFilterComposer(
                $db: $db,
                $table: $db.buildingTypesResearched,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> conceptBandMilestonesRefs(
    Expression<bool> Function($$ConceptBandMilestonesTableFilterComposer f) f,
  ) {
    final $$ConceptBandMilestonesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conceptBandMilestones,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConceptBandMilestonesTableFilterComposer(
                $db: $db,
                $table: $db.conceptBandMilestones,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> storyBeatStatesRefs(
    Expression<bool> Function($$StoryBeatStatesTableFilterComposer f) f,
  ) {
    final $$StoryBeatStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyBeatStates,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryBeatStatesTableFilterComposer(
            $db: $db,
            $table: $db.storyBeatStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
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

  ColumnOrderings<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get brickBalance => $composableBuilder(
    column: $table.brickBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lifetimeBricksEarned => $composableBuilder(
    column: $table.lifetimeBricksEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get researchBalance => $composableBuilder(
    column: $table.researchBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lifetimeResearchEarned => $composableBuilder(
    column: $table.lifetimeResearchEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarConfig => $composableBuilder(
    column: $table.avatarConfig,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
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

  GeneratedColumn<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get brickBalance => $composableBuilder(
    column: $table.brickBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lifetimeBricksEarned => $composableBuilder(
    column: $table.lifetimeBricksEarned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get researchBalance => $composableBuilder(
    column: $table.researchBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lifetimeResearchEarned => $composableBuilder(
    column: $table.lifetimeResearchEarned,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get avatarConfig => $composableBuilder(
    column: $table.avatarConfig,
    builder: (column) => column,
  );

  Expression<T> conceptProficienciesRefs<T extends Object>(
    Expression<T> Function($$ConceptProficienciesTableAnnotationComposer a) f,
  ) {
    final $$ConceptProficienciesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conceptProficiencies,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConceptProficienciesTableAnnotationComposer(
                $db: $db,
                $table: $db.conceptProficiencies,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> introducedConceptsRefs<T extends Object>(
    Expression<T> Function($$IntroducedConceptsTableAnnotationComposer a) f,
  ) {
    final $$IntroducedConceptsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.introducedConcepts,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IntroducedConceptsTableAnnotationComposer(
                $db: $db,
                $table: $db.introducedConcepts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> citiesRefs<T extends Object>(
    Expression<T> Function($$CitiesTableAnnotationComposer a) f,
  ) {
    final $$CitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cities,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.cities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> buildingTypesResearchedRefs<T extends Object>(
    Expression<T> Function($$BuildingTypesResearchedTableAnnotationComposer a)
    f,
  ) {
    final $$BuildingTypesResearchedTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.buildingTypesResearched,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BuildingTypesResearchedTableAnnotationComposer(
                $db: $db,
                $table: $db.buildingTypesResearched,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> conceptBandMilestonesRefs<T extends Object>(
    Expression<T> Function($$ConceptBandMilestonesTableAnnotationComposer a) f,
  ) {
    final $$ConceptBandMilestonesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conceptBandMilestones,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConceptBandMilestonesTableAnnotationComposer(
                $db: $db,
                $table: $db.conceptBandMilestones,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> storyBeatStatesRefs<T extends Object>(
    Expression<T> Function($$StoryBeatStatesTableAnnotationComposer a) f,
  ) {
    final $$StoryBeatStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyBeatStates,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryBeatStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.storyBeatStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, $$PlayersTableReferences),
          Player,
          PrefetchHooks Function({
            bool conceptProficienciesRefs,
            bool introducedConceptsRefs,
            bool citiesRefs,
            bool buildingTypesResearchedRefs,
            bool conceptBandMilestonesRefs,
            bool storyBeatStatesRefs,
          })
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> gradeLevel = const Value.absent(),
                Value<int> brickBalance = const Value.absent(),
                Value<int> lifetimeBricksEarned = const Value.absent(),
                Value<int> researchBalance = const Value.absent(),
                Value<int> lifetimeResearchEarned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> avatarConfig = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                brickBalance: brickBalance,
                lifetimeBricksEarned: lifetimeBricksEarned,
                researchBalance: researchBalance,
                lifetimeResearchEarned: lifetimeResearchEarned,
                createdAt: createdAt,
                avatarConfig: avatarConfig,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int gradeLevel,
                Value<int> brickBalance = const Value.absent(),
                Value<int> lifetimeBricksEarned = const Value.absent(),
                Value<int> researchBalance = const Value.absent(),
                Value<int> lifetimeResearchEarned = const Value.absent(),
                required DateTime createdAt,
                Value<String?> avatarConfig = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                brickBalance: brickBalance,
                lifetimeBricksEarned: lifetimeBricksEarned,
                researchBalance: researchBalance,
                lifetimeResearchEarned: lifetimeResearchEarned,
                createdAt: createdAt,
                avatarConfig: avatarConfig,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                conceptProficienciesRefs = false,
                introducedConceptsRefs = false,
                citiesRefs = false,
                buildingTypesResearchedRefs = false,
                conceptBandMilestonesRefs = false,
                storyBeatStatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (conceptProficienciesRefs) db.conceptProficiencies,
                    if (introducedConceptsRefs) db.introducedConcepts,
                    if (citiesRefs) db.cities,
                    if (buildingTypesResearchedRefs) db.buildingTypesResearched,
                    if (conceptBandMilestonesRefs) db.conceptBandMilestones,
                    if (storyBeatStatesRefs) db.storyBeatStates,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (conceptProficienciesRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          ConceptProficiency
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._conceptProficienciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).conceptProficienciesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (introducedConceptsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          IntroducedConcept
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._introducedConceptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).introducedConceptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (citiesRefs)
                        await $_getPrefetchedData<Player, $PlayersTable, City>(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._citiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).citiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (buildingTypesResearchedRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          BuildingTypesResearchedData
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._buildingTypesResearchedRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).buildingTypesResearchedRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conceptBandMilestonesRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          ConceptBandMilestone
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._conceptBandMilestonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).conceptBandMilestonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storyBeatStatesRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          StoryBeatState
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._storyBeatStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).storyBeatStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
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

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, $$PlayersTableReferences),
      Player,
      PrefetchHooks Function({
        bool conceptProficienciesRefs,
        bool introducedConceptsRefs,
        bool citiesRefs,
        bool buildingTypesResearchedRefs,
        bool conceptBandMilestonesRefs,
        bool storyBeatStatesRefs,
      })
    >;
typedef $$ConceptProficienciesTableCreateCompanionBuilder =
    ConceptProficienciesCompanion Function({
      required int playerId,
      required String conceptId,
      required double proficiency,
      Value<int> questionsAnswered,
      Value<int> questionsCorrect,
      required DateTime lastUpdatedAt,
      Value<int> rowid,
    });
typedef $$ConceptProficienciesTableUpdateCompanionBuilder =
    ConceptProficienciesCompanion Function({
      Value<int> playerId,
      Value<String> conceptId,
      Value<double> proficiency,
      Value<int> questionsAnswered,
      Value<int> questionsCorrect,
      Value<DateTime> lastUpdatedAt,
      Value<int> rowid,
    });

final class $$ConceptProficienciesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConceptProficienciesTable,
          ConceptProficiency
        > {
  $$ConceptProficienciesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias(
        $_aliasNameGenerator(db.conceptProficiencies.playerId, db.players.id),
      );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConceptProficienciesTableFilterComposer
    extends Composer<_$AppDatabase, $ConceptProficienciesTable> {
  $$ConceptProficienciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proficiency => $composableBuilder(
    column: $table.proficiency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionsAnswered => $composableBuilder(
    column: $table.questionsAnswered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConceptProficienciesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConceptProficienciesTable> {
  $$ConceptProficienciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proficiency => $composableBuilder(
    column: $table.proficiency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionsAnswered => $composableBuilder(
    column: $table.questionsAnswered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConceptProficienciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConceptProficienciesTable> {
  $$ConceptProficienciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conceptId =>
      $composableBuilder(column: $table.conceptId, builder: (column) => column);

  GeneratedColumn<double> get proficiency => $composableBuilder(
    column: $table.proficiency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionsAnswered => $composableBuilder(
    column: $table.questionsAnswered,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConceptProficienciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConceptProficienciesTable,
          ConceptProficiency,
          $$ConceptProficienciesTableFilterComposer,
          $$ConceptProficienciesTableOrderingComposer,
          $$ConceptProficienciesTableAnnotationComposer,
          $$ConceptProficienciesTableCreateCompanionBuilder,
          $$ConceptProficienciesTableUpdateCompanionBuilder,
          (ConceptProficiency, $$ConceptProficienciesTableReferences),
          ConceptProficiency,
          PrefetchHooks Function({bool playerId})
        > {
  $$ConceptProficienciesTableTableManager(
    _$AppDatabase db,
    $ConceptProficienciesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConceptProficienciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConceptProficienciesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConceptProficienciesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> playerId = const Value.absent(),
                Value<String> conceptId = const Value.absent(),
                Value<double> proficiency = const Value.absent(),
                Value<int> questionsAnswered = const Value.absent(),
                Value<int> questionsCorrect = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConceptProficienciesCompanion(
                playerId: playerId,
                conceptId: conceptId,
                proficiency: proficiency,
                questionsAnswered: questionsAnswered,
                questionsCorrect: questionsCorrect,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playerId,
                required String conceptId,
                required double proficiency,
                Value<int> questionsAnswered = const Value.absent(),
                Value<int> questionsCorrect = const Value.absent(),
                required DateTime lastUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConceptProficienciesCompanion.insert(
                playerId: playerId,
                conceptId: conceptId,
                proficiency: proficiency,
                questionsAnswered: questionsAnswered,
                questionsCorrect: questionsCorrect,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConceptProficienciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false}) {
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
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$ConceptProficienciesTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$ConceptProficienciesTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ConceptProficienciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConceptProficienciesTable,
      ConceptProficiency,
      $$ConceptProficienciesTableFilterComposer,
      $$ConceptProficienciesTableOrderingComposer,
      $$ConceptProficienciesTableAnnotationComposer,
      $$ConceptProficienciesTableCreateCompanionBuilder,
      $$ConceptProficienciesTableUpdateCompanionBuilder,
      (ConceptProficiency, $$ConceptProficienciesTableReferences),
      ConceptProficiency,
      PrefetchHooks Function({bool playerId})
    >;
typedef $$IntroducedConceptsTableCreateCompanionBuilder =
    IntroducedConceptsCompanion Function({
      required int playerId,
      required String conceptId,
      required DateTime introducedAt,
      Value<int> rowid,
    });
typedef $$IntroducedConceptsTableUpdateCompanionBuilder =
    IntroducedConceptsCompanion Function({
      Value<int> playerId,
      Value<String> conceptId,
      Value<DateTime> introducedAt,
      Value<int> rowid,
    });

final class $$IntroducedConceptsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IntroducedConceptsTable,
          IntroducedConcept
        > {
  $$IntroducedConceptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias(
        $_aliasNameGenerator(db.introducedConcepts.playerId, db.players.id),
      );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntroducedConceptsTableFilterComposer
    extends Composer<_$AppDatabase, $IntroducedConceptsTable> {
  $$IntroducedConceptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntroducedConceptsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntroducedConceptsTable> {
  $$IntroducedConceptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntroducedConceptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntroducedConceptsTable> {
  $$IntroducedConceptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conceptId =>
      $composableBuilder(column: $table.conceptId, builder: (column) => column);

  GeneratedColumn<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => column,
  );

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntroducedConceptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntroducedConceptsTable,
          IntroducedConcept,
          $$IntroducedConceptsTableFilterComposer,
          $$IntroducedConceptsTableOrderingComposer,
          $$IntroducedConceptsTableAnnotationComposer,
          $$IntroducedConceptsTableCreateCompanionBuilder,
          $$IntroducedConceptsTableUpdateCompanionBuilder,
          (IntroducedConcept, $$IntroducedConceptsTableReferences),
          IntroducedConcept,
          PrefetchHooks Function({bool playerId})
        > {
  $$IntroducedConceptsTableTableManager(
    _$AppDatabase db,
    $IntroducedConceptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntroducedConceptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntroducedConceptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntroducedConceptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> playerId = const Value.absent(),
                Value<String> conceptId = const Value.absent(),
                Value<DateTime> introducedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntroducedConceptsCompanion(
                playerId: playerId,
                conceptId: conceptId,
                introducedAt: introducedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playerId,
                required String conceptId,
                required DateTime introducedAt,
                Value<int> rowid = const Value.absent(),
              }) => IntroducedConceptsCompanion.insert(
                playerId: playerId,
                conceptId: conceptId,
                introducedAt: introducedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntroducedConceptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false}) {
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
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$IntroducedConceptsTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$IntroducedConceptsTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$IntroducedConceptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntroducedConceptsTable,
      IntroducedConcept,
      $$IntroducedConceptsTableFilterComposer,
      $$IntroducedConceptsTableOrderingComposer,
      $$IntroducedConceptsTableAnnotationComposer,
      $$IntroducedConceptsTableCreateCompanionBuilder,
      $$IntroducedConceptsTableUpdateCompanionBuilder,
      (IntroducedConcept, $$IntroducedConceptsTableReferences),
      IntroducedConcept,
      PrefetchHooks Function({bool playerId})
    >;
typedef $$ConceptsTableCreateCompanionBuilder =
    ConceptsCompanion Function({
      required String id,
      required String name,
      required String shortLabel,
      required String categoryId,
      required int primaryGrade,
      Value<String> prereqIdsCsv,
      required String sourceStrategy,
      required String diagramRequirement,
      required int categoryRowOrder,
      Value<int> rowid,
    });
typedef $$ConceptsTableUpdateCompanionBuilder =
    ConceptsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> shortLabel,
      Value<String> categoryId,
      Value<int> primaryGrade,
      Value<String> prereqIdsCsv,
      Value<String> sourceStrategy,
      Value<String> diagramRequirement,
      Value<int> categoryRowOrder,
      Value<int> rowid,
    });

class $$ConceptsTableFilterComposer
    extends Composer<_$AppDatabase, $ConceptsTable> {
  $$ConceptsTableFilterComposer({
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

  ColumnFilters<String> get shortLabel => $composableBuilder(
    column: $table.shortLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get primaryGrade => $composableBuilder(
    column: $table.primaryGrade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prereqIdsCsv => $composableBuilder(
    column: $table.prereqIdsCsv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceStrategy => $composableBuilder(
    column: $table.sourceStrategy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagramRequirement => $composableBuilder(
    column: $table.diagramRequirement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryRowOrder => $composableBuilder(
    column: $table.categoryRowOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConceptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConceptsTable> {
  $$ConceptsTableOrderingComposer({
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

  ColumnOrderings<String> get shortLabel => $composableBuilder(
    column: $table.shortLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get primaryGrade => $composableBuilder(
    column: $table.primaryGrade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prereqIdsCsv => $composableBuilder(
    column: $table.prereqIdsCsv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceStrategy => $composableBuilder(
    column: $table.sourceStrategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagramRequirement => $composableBuilder(
    column: $table.diagramRequirement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryRowOrder => $composableBuilder(
    column: $table.categoryRowOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConceptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConceptsTable> {
  $$ConceptsTableAnnotationComposer({
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

  GeneratedColumn<String> get shortLabel => $composableBuilder(
    column: $table.shortLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get primaryGrade => $composableBuilder(
    column: $table.primaryGrade,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prereqIdsCsv => $composableBuilder(
    column: $table.prereqIdsCsv,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceStrategy => $composableBuilder(
    column: $table.sourceStrategy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get diagramRequirement => $composableBuilder(
    column: $table.diagramRequirement,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryRowOrder => $composableBuilder(
    column: $table.categoryRowOrder,
    builder: (column) => column,
  );
}

class $$ConceptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConceptsTable,
          CatalogConcept,
          $$ConceptsTableFilterComposer,
          $$ConceptsTableOrderingComposer,
          $$ConceptsTableAnnotationComposer,
          $$ConceptsTableCreateCompanionBuilder,
          $$ConceptsTableUpdateCompanionBuilder,
          (
            CatalogConcept,
            BaseReferences<_$AppDatabase, $ConceptsTable, CatalogConcept>,
          ),
          CatalogConcept,
          PrefetchHooks Function()
        > {
  $$ConceptsTableTableManager(_$AppDatabase db, $ConceptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConceptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConceptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConceptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> shortLabel = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> primaryGrade = const Value.absent(),
                Value<String> prereqIdsCsv = const Value.absent(),
                Value<String> sourceStrategy = const Value.absent(),
                Value<String> diagramRequirement = const Value.absent(),
                Value<int> categoryRowOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConceptsCompanion(
                id: id,
                name: name,
                shortLabel: shortLabel,
                categoryId: categoryId,
                primaryGrade: primaryGrade,
                prereqIdsCsv: prereqIdsCsv,
                sourceStrategy: sourceStrategy,
                diagramRequirement: diagramRequirement,
                categoryRowOrder: categoryRowOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String shortLabel,
                required String categoryId,
                required int primaryGrade,
                Value<String> prereqIdsCsv = const Value.absent(),
                required String sourceStrategy,
                required String diagramRequirement,
                required int categoryRowOrder,
                Value<int> rowid = const Value.absent(),
              }) => ConceptsCompanion.insert(
                id: id,
                name: name,
                shortLabel: shortLabel,
                categoryId: categoryId,
                primaryGrade: primaryGrade,
                prereqIdsCsv: prereqIdsCsv,
                sourceStrategy: sourceStrategy,
                diagramRequirement: diagramRequirement,
                categoryRowOrder: categoryRowOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConceptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConceptsTable,
      CatalogConcept,
      $$ConceptsTableFilterComposer,
      $$ConceptsTableOrderingComposer,
      $$ConceptsTableAnnotationComposer,
      $$ConceptsTableCreateCompanionBuilder,
      $$ConceptsTableUpdateCompanionBuilder,
      (
        CatalogConcept,
        BaseReferences<_$AppDatabase, $ConceptsTable, CatalogConcept>,
      ),
      CatalogConcept,
      PrefetchHooks Function()
    >;
typedef $$DatasetQuestionsTableCreateCompanionBuilder =
    DatasetQuestionsCompanion Function({
      required String id,
      required String conceptId,
      required String prompt,
      required String correctAnswer,
      required String distractorsJson,
      required String explanationJson,
      required String source,
      required String sourceModule,
      required String license,
      Value<String> answerFormat,
      Value<int> rowid,
    });
typedef $$DatasetQuestionsTableUpdateCompanionBuilder =
    DatasetQuestionsCompanion Function({
      Value<String> id,
      Value<String> conceptId,
      Value<String> prompt,
      Value<String> correctAnswer,
      Value<String> distractorsJson,
      Value<String> explanationJson,
      Value<String> source,
      Value<String> sourceModule,
      Value<String> license,
      Value<String> answerFormat,
      Value<int> rowid,
    });

class $$DatasetQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetQuestionsTable> {
  $$DatasetQuestionsTableFilterComposer({
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

  ColumnFilters<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distractorsJson => $composableBuilder(
    column: $table.distractorsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationJson => $composableBuilder(
    column: $table.explanationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceModule => $composableBuilder(
    column: $table.sourceModule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerFormat => $composableBuilder(
    column: $table.answerFormat,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DatasetQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetQuestionsTable> {
  $$DatasetQuestionsTableOrderingComposer({
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

  ColumnOrderings<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distractorsJson => $composableBuilder(
    column: $table.distractorsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationJson => $composableBuilder(
    column: $table.explanationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceModule => $composableBuilder(
    column: $table.sourceModule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerFormat => $composableBuilder(
    column: $table.answerFormat,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DatasetQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetQuestionsTable> {
  $$DatasetQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conceptId =>
      $composableBuilder(column: $table.conceptId, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get distractorsJson => $composableBuilder(
    column: $table.distractorsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationJson => $composableBuilder(
    column: $table.explanationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceModule => $composableBuilder(
    column: $table.sourceModule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get license =>
      $composableBuilder(column: $table.license, builder: (column) => column);

  GeneratedColumn<String> get answerFormat => $composableBuilder(
    column: $table.answerFormat,
    builder: (column) => column,
  );
}

class $$DatasetQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DatasetQuestionsTable,
          DatasetQuestionRow,
          $$DatasetQuestionsTableFilterComposer,
          $$DatasetQuestionsTableOrderingComposer,
          $$DatasetQuestionsTableAnnotationComposer,
          $$DatasetQuestionsTableCreateCompanionBuilder,
          $$DatasetQuestionsTableUpdateCompanionBuilder,
          (
            DatasetQuestionRow,
            BaseReferences<
              _$AppDatabase,
              $DatasetQuestionsTable,
              DatasetQuestionRow
            >,
          ),
          DatasetQuestionRow,
          PrefetchHooks Function()
        > {
  $$DatasetQuestionsTableTableManager(
    _$AppDatabase db,
    $DatasetQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conceptId = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> correctAnswer = const Value.absent(),
                Value<String> distractorsJson = const Value.absent(),
                Value<String> explanationJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> sourceModule = const Value.absent(),
                Value<String> license = const Value.absent(),
                Value<String> answerFormat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DatasetQuestionsCompanion(
                id: id,
                conceptId: conceptId,
                prompt: prompt,
                correctAnswer: correctAnswer,
                distractorsJson: distractorsJson,
                explanationJson: explanationJson,
                source: source,
                sourceModule: sourceModule,
                license: license,
                answerFormat: answerFormat,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conceptId,
                required String prompt,
                required String correctAnswer,
                required String distractorsJson,
                required String explanationJson,
                required String source,
                required String sourceModule,
                required String license,
                Value<String> answerFormat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DatasetQuestionsCompanion.insert(
                id: id,
                conceptId: conceptId,
                prompt: prompt,
                correctAnswer: correctAnswer,
                distractorsJson: distractorsJson,
                explanationJson: explanationJson,
                source: source,
                sourceModule: sourceModule,
                license: license,
                answerFormat: answerFormat,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DatasetQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DatasetQuestionsTable,
      DatasetQuestionRow,
      $$DatasetQuestionsTableFilterComposer,
      $$DatasetQuestionsTableOrderingComposer,
      $$DatasetQuestionsTableAnnotationComposer,
      $$DatasetQuestionsTableCreateCompanionBuilder,
      $$DatasetQuestionsTableUpdateCompanionBuilder,
      (
        DatasetQuestionRow,
        BaseReferences<
          _$AppDatabase,
          $DatasetQuestionsTable,
          DatasetQuestionRow
        >,
      ),
      DatasetQuestionRow,
      PrefetchHooks Function()
    >;
typedef $$CitiesTableCreateCompanionBuilder =
    CitiesCompanion Function({
      Value<int> id,
      required int playerId,
      required String cityMapId,
      required int gridWidth,
      required int gridHeight,
      Value<int> population,
      required DateTime createdAt,
    });
typedef $$CitiesTableUpdateCompanionBuilder =
    CitiesCompanion Function({
      Value<int> id,
      Value<int> playerId,
      Value<String> cityMapId,
      Value<int> gridWidth,
      Value<int> gridHeight,
      Value<int> population,
      Value<DateTime> createdAt,
    });

final class $$CitiesTableReferences
    extends BaseReferences<_$AppDatabase, $CitiesTable, City> {
  $$CitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlayersTable _playerIdTable(_$AppDatabase db) => db.players
      .createAlias($_aliasNameGenerator(db.cities.playerId, db.players.id));

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BuildingPlacementsTable, List<BuildingPlacement>>
  _buildingPlacementsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.buildingPlacements,
        aliasName: $_aliasNameGenerator(
          db.cities.id,
          db.buildingPlacements.cityId,
        ),
      );

  $$BuildingPlacementsTableProcessedTableManager get buildingPlacementsRefs {
    final manager = $$BuildingPlacementsTableTableManager(
      $_db,
      $_db.buildingPlacements,
    ).filter((f) => f.cityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _buildingPlacementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CitiesTableFilterComposer
    extends Composer<_$AppDatabase, $CitiesTable> {
  $$CitiesTableFilterComposer({
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

  ColumnFilters<String> get cityMapId => $composableBuilder(
    column: $table.cityMapId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridWidth => $composableBuilder(
    column: $table.gridWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridHeight => $composableBuilder(
    column: $table.gridHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get population => $composableBuilder(
    column: $table.population,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> buildingPlacementsRefs(
    Expression<bool> Function($$BuildingPlacementsTableFilterComposer f) f,
  ) {
    final $$BuildingPlacementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.buildingPlacements,
      getReferencedColumn: (t) => t.cityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildingPlacementsTableFilterComposer(
            $db: $db,
            $table: $db.buildingPlacements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $CitiesTable> {
  $$CitiesTableOrderingComposer({
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

  ColumnOrderings<String> get cityMapId => $composableBuilder(
    column: $table.cityMapId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridWidth => $composableBuilder(
    column: $table.gridWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridHeight => $composableBuilder(
    column: $table.gridHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get population => $composableBuilder(
    column: $table.population,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CitiesTable> {
  $$CitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cityMapId =>
      $composableBuilder(column: $table.cityMapId, builder: (column) => column);

  GeneratedColumn<int> get gridWidth =>
      $composableBuilder(column: $table.gridWidth, builder: (column) => column);

  GeneratedColumn<int> get gridHeight => $composableBuilder(
    column: $table.gridHeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get population => $composableBuilder(
    column: $table.population,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> buildingPlacementsRefs<T extends Object>(
    Expression<T> Function($$BuildingPlacementsTableAnnotationComposer a) f,
  ) {
    final $$BuildingPlacementsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.buildingPlacements,
          getReferencedColumn: (t) => t.cityId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BuildingPlacementsTableAnnotationComposer(
                $db: $db,
                $table: $db.buildingPlacements,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CitiesTable,
          City,
          $$CitiesTableFilterComposer,
          $$CitiesTableOrderingComposer,
          $$CitiesTableAnnotationComposer,
          $$CitiesTableCreateCompanionBuilder,
          $$CitiesTableUpdateCompanionBuilder,
          (City, $$CitiesTableReferences),
          City,
          PrefetchHooks Function({bool playerId, bool buildingPlacementsRefs})
        > {
  $$CitiesTableTableManager(_$AppDatabase db, $CitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<String> cityMapId = const Value.absent(),
                Value<int> gridWidth = const Value.absent(),
                Value<int> gridHeight = const Value.absent(),
                Value<int> population = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CitiesCompanion(
                id: id,
                playerId: playerId,
                cityMapId: cityMapId,
                gridWidth: gridWidth,
                gridHeight: gridHeight,
                population: population,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playerId,
                required String cityMapId,
                required int gridWidth,
                required int gridHeight,
                Value<int> population = const Value.absent(),
                required DateTime createdAt,
              }) => CitiesCompanion.insert(
                id: id,
                playerId: playerId,
                cityMapId: cityMapId,
                gridWidth: gridWidth,
                gridHeight: gridHeight,
                population: population,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CitiesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({playerId = false, buildingPlacementsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (buildingPlacementsRefs) db.buildingPlacements,
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
                        if (playerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.playerId,
                                    referencedTable: $$CitiesTableReferences
                                        ._playerIdTable(db),
                                    referencedColumn: $$CitiesTableReferences
                                        ._playerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (buildingPlacementsRefs)
                        await $_getPrefetchedData<
                          City,
                          $CitiesTable,
                          BuildingPlacement
                        >(
                          currentTable: table,
                          referencedTable: $$CitiesTableReferences
                              ._buildingPlacementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).buildingPlacementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cityId == item.id,
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

typedef $$CitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CitiesTable,
      City,
      $$CitiesTableFilterComposer,
      $$CitiesTableOrderingComposer,
      $$CitiesTableAnnotationComposer,
      $$CitiesTableCreateCompanionBuilder,
      $$CitiesTableUpdateCompanionBuilder,
      (City, $$CitiesTableReferences),
      City,
      PrefetchHooks Function({bool playerId, bool buildingPlacementsRefs})
    >;
typedef $$BuildingPlacementsTableCreateCompanionBuilder =
    BuildingPlacementsCompanion Function({
      Value<int> id,
      required int cityId,
      required String buildingTypeId,
      Value<int> currentTier,
      required int gridX,
      required int gridY,
      required int placedAtRound,
    });
typedef $$BuildingPlacementsTableUpdateCompanionBuilder =
    BuildingPlacementsCompanion Function({
      Value<int> id,
      Value<int> cityId,
      Value<String> buildingTypeId,
      Value<int> currentTier,
      Value<int> gridX,
      Value<int> gridY,
      Value<int> placedAtRound,
    });

final class $$BuildingPlacementsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BuildingPlacementsTable,
          BuildingPlacement
        > {
  $$BuildingPlacementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CitiesTable _cityIdTable(_$AppDatabase db) => db.cities.createAlias(
    $_aliasNameGenerator(db.buildingPlacements.cityId, db.cities.id),
  );

  $$CitiesTableProcessedTableManager get cityId {
    final $_column = $_itemColumn<int>('city_id')!;

    final manager = $$CitiesTableTableManager(
      $_db,
      $_db.cities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BuildingPlacementsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildingPlacementsTable> {
  $$BuildingPlacementsTableFilterComposer({
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

  ColumnFilters<String> get buildingTypeId => $composableBuilder(
    column: $table.buildingTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentTier => $composableBuilder(
    column: $table.currentTier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridX => $composableBuilder(
    column: $table.gridX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridY => $composableBuilder(
    column: $table.gridY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get placedAtRound => $composableBuilder(
    column: $table.placedAtRound,
    builder: (column) => ColumnFilters(column),
  );

  $$CitiesTableFilterComposer get cityId {
    final $$CitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cityId,
      referencedTable: $db.cities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CitiesTableFilterComposer(
            $db: $db,
            $table: $db.cities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildingPlacementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildingPlacementsTable> {
  $$BuildingPlacementsTableOrderingComposer({
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

  ColumnOrderings<String> get buildingTypeId => $composableBuilder(
    column: $table.buildingTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentTier => $composableBuilder(
    column: $table.currentTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridX => $composableBuilder(
    column: $table.gridX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridY => $composableBuilder(
    column: $table.gridY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get placedAtRound => $composableBuilder(
    column: $table.placedAtRound,
    builder: (column) => ColumnOrderings(column),
  );

  $$CitiesTableOrderingComposer get cityId {
    final $$CitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cityId,
      referencedTable: $db.cities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CitiesTableOrderingComposer(
            $db: $db,
            $table: $db.cities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildingPlacementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildingPlacementsTable> {
  $$BuildingPlacementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get buildingTypeId => $composableBuilder(
    column: $table.buildingTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentTier => $composableBuilder(
    column: $table.currentTier,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gridX =>
      $composableBuilder(column: $table.gridX, builder: (column) => column);

  GeneratedColumn<int> get gridY =>
      $composableBuilder(column: $table.gridY, builder: (column) => column);

  GeneratedColumn<int> get placedAtRound => $composableBuilder(
    column: $table.placedAtRound,
    builder: (column) => column,
  );

  $$CitiesTableAnnotationComposer get cityId {
    final $$CitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cityId,
      referencedTable: $db.cities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.cities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildingPlacementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildingPlacementsTable,
          BuildingPlacement,
          $$BuildingPlacementsTableFilterComposer,
          $$BuildingPlacementsTableOrderingComposer,
          $$BuildingPlacementsTableAnnotationComposer,
          $$BuildingPlacementsTableCreateCompanionBuilder,
          $$BuildingPlacementsTableUpdateCompanionBuilder,
          (BuildingPlacement, $$BuildingPlacementsTableReferences),
          BuildingPlacement,
          PrefetchHooks Function({bool cityId})
        > {
  $$BuildingPlacementsTableTableManager(
    _$AppDatabase db,
    $BuildingPlacementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildingPlacementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildingPlacementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildingPlacementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cityId = const Value.absent(),
                Value<String> buildingTypeId = const Value.absent(),
                Value<int> currentTier = const Value.absent(),
                Value<int> gridX = const Value.absent(),
                Value<int> gridY = const Value.absent(),
                Value<int> placedAtRound = const Value.absent(),
              }) => BuildingPlacementsCompanion(
                id: id,
                cityId: cityId,
                buildingTypeId: buildingTypeId,
                currentTier: currentTier,
                gridX: gridX,
                gridY: gridY,
                placedAtRound: placedAtRound,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cityId,
                required String buildingTypeId,
                Value<int> currentTier = const Value.absent(),
                required int gridX,
                required int gridY,
                required int placedAtRound,
              }) => BuildingPlacementsCompanion.insert(
                id: id,
                cityId: cityId,
                buildingTypeId: buildingTypeId,
                currentTier: currentTier,
                gridX: gridX,
                gridY: gridY,
                placedAtRound: placedAtRound,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BuildingPlacementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cityId = false}) {
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
                    if (cityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cityId,
                                referencedTable:
                                    $$BuildingPlacementsTableReferences
                                        ._cityIdTable(db),
                                referencedColumn:
                                    $$BuildingPlacementsTableReferences
                                        ._cityIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$BuildingPlacementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildingPlacementsTable,
      BuildingPlacement,
      $$BuildingPlacementsTableFilterComposer,
      $$BuildingPlacementsTableOrderingComposer,
      $$BuildingPlacementsTableAnnotationComposer,
      $$BuildingPlacementsTableCreateCompanionBuilder,
      $$BuildingPlacementsTableUpdateCompanionBuilder,
      (BuildingPlacement, $$BuildingPlacementsTableReferences),
      BuildingPlacement,
      PrefetchHooks Function({bool cityId})
    >;
typedef $$BuildingTypesResearchedTableCreateCompanionBuilder =
    BuildingTypesResearchedCompanion Function({
      required int playerId,
      required String buildingTypeId,
      required DateTime researchedAt,
      Value<int> rowid,
    });
typedef $$BuildingTypesResearchedTableUpdateCompanionBuilder =
    BuildingTypesResearchedCompanion Function({
      Value<int> playerId,
      Value<String> buildingTypeId,
      Value<DateTime> researchedAt,
      Value<int> rowid,
    });

final class $$BuildingTypesResearchedTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BuildingTypesResearchedTable,
          BuildingTypesResearchedData
        > {
  $$BuildingTypesResearchedTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias(
        $_aliasNameGenerator(
          db.buildingTypesResearched.playerId,
          db.players.id,
        ),
      );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BuildingTypesResearchedTableFilterComposer
    extends Composer<_$AppDatabase, $BuildingTypesResearchedTable> {
  $$BuildingTypesResearchedTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get buildingTypeId => $composableBuilder(
    column: $table.buildingTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get researchedAt => $composableBuilder(
    column: $table.researchedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildingTypesResearchedTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildingTypesResearchedTable> {
  $$BuildingTypesResearchedTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get buildingTypeId => $composableBuilder(
    column: $table.buildingTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get researchedAt => $composableBuilder(
    column: $table.researchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildingTypesResearchedTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildingTypesResearchedTable> {
  $$BuildingTypesResearchedTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get buildingTypeId => $composableBuilder(
    column: $table.buildingTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get researchedAt => $composableBuilder(
    column: $table.researchedAt,
    builder: (column) => column,
  );

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildingTypesResearchedTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildingTypesResearchedTable,
          BuildingTypesResearchedData,
          $$BuildingTypesResearchedTableFilterComposer,
          $$BuildingTypesResearchedTableOrderingComposer,
          $$BuildingTypesResearchedTableAnnotationComposer,
          $$BuildingTypesResearchedTableCreateCompanionBuilder,
          $$BuildingTypesResearchedTableUpdateCompanionBuilder,
          (
            BuildingTypesResearchedData,
            $$BuildingTypesResearchedTableReferences,
          ),
          BuildingTypesResearchedData,
          PrefetchHooks Function({bool playerId})
        > {
  $$BuildingTypesResearchedTableTableManager(
    _$AppDatabase db,
    $BuildingTypesResearchedTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildingTypesResearchedTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BuildingTypesResearchedTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BuildingTypesResearchedTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> playerId = const Value.absent(),
                Value<String> buildingTypeId = const Value.absent(),
                Value<DateTime> researchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuildingTypesResearchedCompanion(
                playerId: playerId,
                buildingTypeId: buildingTypeId,
                researchedAt: researchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playerId,
                required String buildingTypeId,
                required DateTime researchedAt,
                Value<int> rowid = const Value.absent(),
              }) => BuildingTypesResearchedCompanion.insert(
                playerId: playerId,
                buildingTypeId: buildingTypeId,
                researchedAt: researchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BuildingTypesResearchedTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false}) {
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
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$BuildingTypesResearchedTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$BuildingTypesResearchedTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$BuildingTypesResearchedTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildingTypesResearchedTable,
      BuildingTypesResearchedData,
      $$BuildingTypesResearchedTableFilterComposer,
      $$BuildingTypesResearchedTableOrderingComposer,
      $$BuildingTypesResearchedTableAnnotationComposer,
      $$BuildingTypesResearchedTableCreateCompanionBuilder,
      $$BuildingTypesResearchedTableUpdateCompanionBuilder,
      (BuildingTypesResearchedData, $$BuildingTypesResearchedTableReferences),
      BuildingTypesResearchedData,
      PrefetchHooks Function({bool playerId})
    >;
typedef $$ConceptBandMilestonesTableCreateCompanionBuilder =
    ConceptBandMilestonesCompanion Function({
      required int playerId,
      required String conceptId,
      required int bandIndex,
      required DateTime awardedAt,
      Value<int> rowid,
    });
typedef $$ConceptBandMilestonesTableUpdateCompanionBuilder =
    ConceptBandMilestonesCompanion Function({
      Value<int> playerId,
      Value<String> conceptId,
      Value<int> bandIndex,
      Value<DateTime> awardedAt,
      Value<int> rowid,
    });

final class $$ConceptBandMilestonesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConceptBandMilestonesTable,
          ConceptBandMilestone
        > {
  $$ConceptBandMilestonesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias(
        $_aliasNameGenerator(db.conceptBandMilestones.playerId, db.players.id),
      );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConceptBandMilestonesTableFilterComposer
    extends Composer<_$AppDatabase, $ConceptBandMilestonesTable> {
  $$ConceptBandMilestonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bandIndex => $composableBuilder(
    column: $table.bandIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get awardedAt => $composableBuilder(
    column: $table.awardedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConceptBandMilestonesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConceptBandMilestonesTable> {
  $$ConceptBandMilestonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conceptId => $composableBuilder(
    column: $table.conceptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bandIndex => $composableBuilder(
    column: $table.bandIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get awardedAt => $composableBuilder(
    column: $table.awardedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConceptBandMilestonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConceptBandMilestonesTable> {
  $$ConceptBandMilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conceptId =>
      $composableBuilder(column: $table.conceptId, builder: (column) => column);

  GeneratedColumn<int> get bandIndex =>
      $composableBuilder(column: $table.bandIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get awardedAt =>
      $composableBuilder(column: $table.awardedAt, builder: (column) => column);

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConceptBandMilestonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConceptBandMilestonesTable,
          ConceptBandMilestone,
          $$ConceptBandMilestonesTableFilterComposer,
          $$ConceptBandMilestonesTableOrderingComposer,
          $$ConceptBandMilestonesTableAnnotationComposer,
          $$ConceptBandMilestonesTableCreateCompanionBuilder,
          $$ConceptBandMilestonesTableUpdateCompanionBuilder,
          (ConceptBandMilestone, $$ConceptBandMilestonesTableReferences),
          ConceptBandMilestone,
          PrefetchHooks Function({bool playerId})
        > {
  $$ConceptBandMilestonesTableTableManager(
    _$AppDatabase db,
    $ConceptBandMilestonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConceptBandMilestonesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ConceptBandMilestonesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConceptBandMilestonesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> playerId = const Value.absent(),
                Value<String> conceptId = const Value.absent(),
                Value<int> bandIndex = const Value.absent(),
                Value<DateTime> awardedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConceptBandMilestonesCompanion(
                playerId: playerId,
                conceptId: conceptId,
                bandIndex: bandIndex,
                awardedAt: awardedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playerId,
                required String conceptId,
                required int bandIndex,
                required DateTime awardedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConceptBandMilestonesCompanion.insert(
                playerId: playerId,
                conceptId: conceptId,
                bandIndex: bandIndex,
                awardedAt: awardedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConceptBandMilestonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false}) {
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
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$ConceptBandMilestonesTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$ConceptBandMilestonesTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ConceptBandMilestonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConceptBandMilestonesTable,
      ConceptBandMilestone,
      $$ConceptBandMilestonesTableFilterComposer,
      $$ConceptBandMilestonesTableOrderingComposer,
      $$ConceptBandMilestonesTableAnnotationComposer,
      $$ConceptBandMilestonesTableCreateCompanionBuilder,
      $$ConceptBandMilestonesTableUpdateCompanionBuilder,
      (ConceptBandMilestone, $$ConceptBandMilestonesTableReferences),
      ConceptBandMilestone,
      PrefetchHooks Function({bool playerId})
    >;
typedef $$StoryBeatStatesTableCreateCompanionBuilder =
    StoryBeatStatesCompanion Function({
      required int playerId,
      required String beatId,
      required String state,
      Value<int?> lastFiredAtRound,
      Value<int> fireCount,
      Value<int?> lifetimeBricksAtLastFire,
      Value<int> rowid,
    });
typedef $$StoryBeatStatesTableUpdateCompanionBuilder =
    StoryBeatStatesCompanion Function({
      Value<int> playerId,
      Value<String> beatId,
      Value<String> state,
      Value<int?> lastFiredAtRound,
      Value<int> fireCount,
      Value<int?> lifetimeBricksAtLastFire,
      Value<int> rowid,
    });

final class $$StoryBeatStatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $StoryBeatStatesTable, StoryBeatState> {
  $$StoryBeatStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias(
        $_aliasNameGenerator(db.storyBeatStates.playerId, db.players.id),
      );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoryBeatStatesTableFilterComposer
    extends Composer<_$AppDatabase, $StoryBeatStatesTable> {
  $$StoryBeatStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get beatId => $composableBuilder(
    column: $table.beatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFiredAtRound => $composableBuilder(
    column: $table.lastFiredAtRound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fireCount => $composableBuilder(
    column: $table.fireCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lifetimeBricksAtLastFire => $composableBuilder(
    column: $table.lifetimeBricksAtLastFire,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryBeatStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryBeatStatesTable> {
  $$StoryBeatStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get beatId => $composableBuilder(
    column: $table.beatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFiredAtRound => $composableBuilder(
    column: $table.lastFiredAtRound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fireCount => $composableBuilder(
    column: $table.fireCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lifetimeBricksAtLastFire => $composableBuilder(
    column: $table.lifetimeBricksAtLastFire,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryBeatStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryBeatStatesTable> {
  $$StoryBeatStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get beatId =>
      $composableBuilder(column: $table.beatId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get lastFiredAtRound => $composableBuilder(
    column: $table.lastFiredAtRound,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fireCount =>
      $composableBuilder(column: $table.fireCount, builder: (column) => column);

  GeneratedColumn<int> get lifetimeBricksAtLastFire => $composableBuilder(
    column: $table.lifetimeBricksAtLastFire,
    builder: (column) => column,
  );

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryBeatStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoryBeatStatesTable,
          StoryBeatState,
          $$StoryBeatStatesTableFilterComposer,
          $$StoryBeatStatesTableOrderingComposer,
          $$StoryBeatStatesTableAnnotationComposer,
          $$StoryBeatStatesTableCreateCompanionBuilder,
          $$StoryBeatStatesTableUpdateCompanionBuilder,
          (StoryBeatState, $$StoryBeatStatesTableReferences),
          StoryBeatState,
          PrefetchHooks Function({bool playerId})
        > {
  $$StoryBeatStatesTableTableManager(
    _$AppDatabase db,
    $StoryBeatStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryBeatStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryBeatStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryBeatStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playerId = const Value.absent(),
                Value<String> beatId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int?> lastFiredAtRound = const Value.absent(),
                Value<int> fireCount = const Value.absent(),
                Value<int?> lifetimeBricksAtLastFire = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoryBeatStatesCompanion(
                playerId: playerId,
                beatId: beatId,
                state: state,
                lastFiredAtRound: lastFiredAtRound,
                fireCount: fireCount,
                lifetimeBricksAtLastFire: lifetimeBricksAtLastFire,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playerId,
                required String beatId,
                required String state,
                Value<int?> lastFiredAtRound = const Value.absent(),
                Value<int> fireCount = const Value.absent(),
                Value<int?> lifetimeBricksAtLastFire = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoryBeatStatesCompanion.insert(
                playerId: playerId,
                beatId: beatId,
                state: state,
                lastFiredAtRound: lastFiredAtRound,
                fireCount: fireCount,
                lifetimeBricksAtLastFire: lifetimeBricksAtLastFire,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoryBeatStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false}) {
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
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$StoryBeatStatesTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$StoryBeatStatesTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$StoryBeatStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoryBeatStatesTable,
      StoryBeatState,
      $$StoryBeatStatesTableFilterComposer,
      $$StoryBeatStatesTableOrderingComposer,
      $$StoryBeatStatesTableAnnotationComposer,
      $$StoryBeatStatesTableCreateCompanionBuilder,
      $$StoryBeatStatesTableUpdateCompanionBuilder,
      (StoryBeatState, $$StoryBeatStatesTableReferences),
      StoryBeatState,
      PrefetchHooks Function({bool playerId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$ConceptProficienciesTableTableManager get conceptProficiencies =>
      $$ConceptProficienciesTableTableManager(_db, _db.conceptProficiencies);
  $$IntroducedConceptsTableTableManager get introducedConcepts =>
      $$IntroducedConceptsTableTableManager(_db, _db.introducedConcepts);
  $$ConceptsTableTableManager get concepts =>
      $$ConceptsTableTableManager(_db, _db.concepts);
  $$DatasetQuestionsTableTableManager get datasetQuestions =>
      $$DatasetQuestionsTableTableManager(_db, _db.datasetQuestions);
  $$CitiesTableTableManager get cities =>
      $$CitiesTableTableManager(_db, _db.cities);
  $$BuildingPlacementsTableTableManager get buildingPlacements =>
      $$BuildingPlacementsTableTableManager(_db, _db.buildingPlacements);
  $$BuildingTypesResearchedTableTableManager get buildingTypesResearched =>
      $$BuildingTypesResearchedTableTableManager(
        _db,
        _db.buildingTypesResearched,
      );
  $$ConceptBandMilestonesTableTableManager get conceptBandMilestones =>
      $$ConceptBandMilestonesTableTableManager(_db, _db.conceptBandMilestones);
  $$StoryBeatStatesTableTableManager get storyBeatStates =>
      $$StoryBeatStatesTableTableManager(_db, _db.storyBeatStates);
}
