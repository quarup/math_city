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
  static const VerificationMeta _currentStarsMeta = const VerificationMeta(
    'currentStars',
  );
  @override
  late final GeneratedColumn<int> currentStars = GeneratedColumn<int>(
    'current_stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lifetimeStarsEarnedMeta =
      const VerificationMeta('lifetimeStarsEarned');
  @override
  late final GeneratedColumn<int> lifetimeStarsEarned = GeneratedColumn<int>(
    'lifetime_stars_earned',
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
    currentStars,
    lifetimeStarsEarned,
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
    if (data.containsKey('current_stars')) {
      context.handle(
        _currentStarsMeta,
        currentStars.isAcceptableOrUnknown(
          data['current_stars']!,
          _currentStarsMeta,
        ),
      );
    }
    if (data.containsKey('lifetime_stars_earned')) {
      context.handle(
        _lifetimeStarsEarnedMeta,
        lifetimeStarsEarned.isAcceptableOrUnknown(
          data['lifetime_stars_earned']!,
          _lifetimeStarsEarnedMeta,
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
      currentStars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_stars'],
      )!,
      lifetimeStarsEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lifetime_stars_earned'],
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
  final int currentStars;
  final int lifetimeStarsEarned;
  final DateTime createdAt;
  final String? avatarConfig;
  const Player({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.currentStars,
    required this.lifetimeStarsEarned,
    required this.createdAt,
    this.avatarConfig,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['grade_level'] = Variable<int>(gradeLevel);
    map['current_stars'] = Variable<int>(currentStars);
    map['lifetime_stars_earned'] = Variable<int>(lifetimeStarsEarned);
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
      currentStars: Value(currentStars),
      lifetimeStarsEarned: Value(lifetimeStarsEarned),
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
      currentStars: serializer.fromJson<int>(json['currentStars']),
      lifetimeStarsEarned: serializer.fromJson<int>(
        json['lifetimeStarsEarned'],
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
      'currentStars': serializer.toJson<int>(currentStars),
      'lifetimeStarsEarned': serializer.toJson<int>(lifetimeStarsEarned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'avatarConfig': serializer.toJson<String?>(avatarConfig),
    };
  }

  Player copyWith({
    int? id,
    String? name,
    int? gradeLevel,
    int? currentStars,
    int? lifetimeStarsEarned,
    DateTime? createdAt,
    Value<String?> avatarConfig = const Value.absent(),
  }) => Player(
    id: id ?? this.id,
    name: name ?? this.name,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    currentStars: currentStars ?? this.currentStars,
    lifetimeStarsEarned: lifetimeStarsEarned ?? this.lifetimeStarsEarned,
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
      currentStars: data.currentStars.present
          ? data.currentStars.value
          : this.currentStars,
      lifetimeStarsEarned: data.lifetimeStarsEarned.present
          ? data.lifetimeStarsEarned.value
          : this.lifetimeStarsEarned,
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
          ..write('currentStars: $currentStars, ')
          ..write('lifetimeStarsEarned: $lifetimeStarsEarned, ')
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
    currentStars,
    lifetimeStarsEarned,
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
          other.currentStars == this.currentStars &&
          other.lifetimeStarsEarned == this.lifetimeStarsEarned &&
          other.createdAt == this.createdAt &&
          other.avatarConfig == this.avatarConfig);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> gradeLevel;
  final Value<int> currentStars;
  final Value<int> lifetimeStarsEarned;
  final Value<DateTime> createdAt;
  final Value<String?> avatarConfig;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.currentStars = const Value.absent(),
    this.lifetimeStarsEarned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarConfig = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int gradeLevel,
    this.currentStars = const Value.absent(),
    this.lifetimeStarsEarned = const Value.absent(),
    required DateTime createdAt,
    this.avatarConfig = const Value.absent(),
  }) : name = Value(name),
       gradeLevel = Value(gradeLevel),
       createdAt = Value(createdAt);
  static Insertable<Player> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? gradeLevel,
    Expression<int>? currentStars,
    Expression<int>? lifetimeStarsEarned,
    Expression<DateTime>? createdAt,
    Expression<String>? avatarConfig,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (currentStars != null) 'current_stars': currentStars,
      if (lifetimeStarsEarned != null)
        'lifetime_stars_earned': lifetimeStarsEarned,
      if (createdAt != null) 'created_at': createdAt,
      if (avatarConfig != null) 'avatar_config': avatarConfig,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? gradeLevel,
    Value<int>? currentStars,
    Value<int>? lifetimeStarsEarned,
    Value<DateTime>? createdAt,
    Value<String?>? avatarConfig,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      currentStars: currentStars ?? this.currentStars,
      lifetimeStarsEarned: lifetimeStarsEarned ?? this.lifetimeStarsEarned,
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
    if (currentStars.present) {
      map['current_stars'] = Variable<int>(currentStars.value);
    }
    if (lifetimeStarsEarned.present) {
      map['lifetime_stars_earned'] = Variable<int>(lifetimeStarsEarned.value);
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
          ..write('currentStars: $currentStars, ')
          ..write('lifetimeStarsEarned: $lifetimeStarsEarned, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $ConceptProficienciesTable conceptProficiencies =
      $ConceptProficienciesTable(this);
  late final $IntroducedConceptsTable introducedConcepts =
      $IntroducedConceptsTable(this);
  late final $ConceptsTable concepts = $ConceptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    players,
    conceptProficiencies,
    introducedConcepts,
    concepts,
  ];
}

typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      required String name,
      required int gradeLevel,
      Value<int> currentStars,
      Value<int> lifetimeStarsEarned,
      required DateTime createdAt,
      Value<String?> avatarConfig,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> gradeLevel,
      Value<int> currentStars,
      Value<int> lifetimeStarsEarned,
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

  ColumnFilters<int> get currentStars => $composableBuilder(
    column: $table.currentStars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lifetimeStarsEarned => $composableBuilder(
    column: $table.lifetimeStarsEarned,
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

  ColumnOrderings<int> get currentStars => $composableBuilder(
    column: $table.currentStars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lifetimeStarsEarned => $composableBuilder(
    column: $table.lifetimeStarsEarned,
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

  GeneratedColumn<int> get currentStars => $composableBuilder(
    column: $table.currentStars,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lifetimeStarsEarned => $composableBuilder(
    column: $table.lifetimeStarsEarned,
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
                Value<int> currentStars = const Value.absent(),
                Value<int> lifetimeStarsEarned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> avatarConfig = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                currentStars: currentStars,
                lifetimeStarsEarned: lifetimeStarsEarned,
                createdAt: createdAt,
                avatarConfig: avatarConfig,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int gradeLevel,
                Value<int> currentStars = const Value.absent(),
                Value<int> lifetimeStarsEarned = const Value.absent(),
                required DateTime createdAt,
                Value<String?> avatarConfig = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                name: name,
                gradeLevel: gradeLevel,
                currentStars: currentStars,
                lifetimeStarsEarned: lifetimeStarsEarned,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (conceptProficienciesRefs) db.conceptProficiencies,
                    if (introducedConceptsRefs) db.introducedConcepts,
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
}
