import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:math_city/domain/avatar/adventurer_catalog.dart';

@immutable
class AdventurerConfig {
  const AdventurerConfig({
    this.hairIndex = 0,
    this.hairColorIndex = 0,
    this.skinColorIndex = 0,
    this.eyesIndex = 0,
    this.mouthIndex = 0,
    this.glassesIndex = 0,
    this.earringsIndex = 0,
    this.blush = false,
    this.freckles = false,
  });

  factory AdventurerConfig.fromJsonString(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return AdventurerConfig(
      hairIndex: (m['h'] as int?) ?? 0,
      hairColorIndex: (m['hc'] as int?) ?? 0,
      skinColorIndex: (m['s'] as int?) ?? 0,
      eyesIndex: (m['e'] as int?) ?? 0,
      mouthIndex: (m['m'] as int?) ?? 0,
      glassesIndex: (m['g'] as int?) ?? 0,
      earringsIndex: (m['er'] as int?) ?? 0,
      blush: (m['bl'] as bool?) ?? false,
      freckles: (m['fr'] as bool?) ?? false,
    );
  }

  /// Builds a random config with DiceBear Adventurer's default odds.
  ///
  /// Used to seed the avatar editor and the new-player lineup so the
  /// default look varies. Hair, hair colour, skin, eyes and mouth are
  /// uniform over the curated catalog. The optional slots follow the
  /// upstream style's schema defaults (`@dicebear/adventurer`):
  /// `glassesProbability` 10, `earringsProbability` 10 and
  /// `featuresProbability` 5, where a feature is one cheek mark (blush or
  /// freckles here). Most faces are therefore plain, which is what the
  /// upstream art was tuned for.
  factory AdventurerConfig.random({Random? random}) {
    final r = random ?? Random();
    final glasses = r.nextDouble() < kGlassesProbability;
    final earrings = r.nextDouble() < kEarringsProbability;
    final feature = r.nextDouble() < kFeatureProbability;
    final featureIsBlush = r.nextBool();
    return AdventurerConfig(
      hairIndex: r.nextInt(kHairStyles.length),
      hairColorIndex: r.nextInt(kHairColors.length),
      skinColorIndex: r.nextInt(kSkinColors.length),
      eyesIndex: r.nextInt(kEyeVariants.length),
      mouthIndex: r.nextInt(kMouthVariants.length),
      // Index 0 of both option lists is "none".
      glassesIndex: glasses ? 1 + r.nextInt(kGlassesOptions.length - 1) : 0,
      earringsIndex: earrings ? 1 + r.nextInt(kEarringsOptions.length - 1) : 0,
      blush: feature && featureIsBlush,
      freckles: feature && !featureIsBlush,
    );
  }

  /// DiceBear Adventurer schema defaults for the optional slots, as a
  /// fraction. See [AdventurerConfig.random].
  static const double kGlassesProbability = 0.10;
  static const double kEarringsProbability = 0.10;
  static const double kFeatureProbability = 0.05;

  final int hairIndex;
  final int hairColorIndex;
  final int skinColorIndex;
  final int eyesIndex;
  final int mouthIndex;
  final int glassesIndex;
  final int earringsIndex;
  final bool blush;
  final bool freckles;

  String toJsonString() => jsonEncode(<String, dynamic>{
    'h': hairIndex,
    'hc': hairColorIndex,
    's': skinColorIndex,
    'e': eyesIndex,
    'm': mouthIndex,
    'g': glassesIndex,
    'er': earringsIndex,
    'bl': blush,
    'fr': freckles,
  });

  AdventurerConfig copyWith({
    int? hairIndex,
    int? hairColorIndex,
    int? skinColorIndex,
    int? eyesIndex,
    int? mouthIndex,
    int? glassesIndex,
    int? earringsIndex,
    bool? blush,
    bool? freckles,
  }) => AdventurerConfig(
    hairIndex: hairIndex ?? this.hairIndex,
    hairColorIndex: hairColorIndex ?? this.hairColorIndex,
    skinColorIndex: skinColorIndex ?? this.skinColorIndex,
    eyesIndex: eyesIndex ?? this.eyesIndex,
    mouthIndex: mouthIndex ?? this.mouthIndex,
    glassesIndex: glassesIndex ?? this.glassesIndex,
    earringsIndex: earringsIndex ?? this.earringsIndex,
    blush: blush ?? this.blush,
    freckles: freckles ?? this.freckles,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdventurerConfig &&
          hairIndex == other.hairIndex &&
          hairColorIndex == other.hairColorIndex &&
          skinColorIndex == other.skinColorIndex &&
          eyesIndex == other.eyesIndex &&
          mouthIndex == other.mouthIndex &&
          glassesIndex == other.glassesIndex &&
          earringsIndex == other.earringsIndex &&
          blush == other.blush &&
          freckles == other.freckles;

  @override
  int get hashCode => Object.hash(
    hairIndex,
    hairColorIndex,
    skinColorIndex,
    eyesIndex,
    mouthIndex,
    glassesIndex,
    earringsIndex,
    blush,
    freckles,
  );
}
