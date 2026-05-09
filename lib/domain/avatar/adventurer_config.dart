import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:math_dash/domain/avatar/adventurer_catalog.dart';

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

  /// Builds a uniformly-random config across every slot.
  ///
  /// Used to seed the avatar editor for new players so the default look
  /// varies. Glasses/earrings include a "none" option (index 0) and are
  /// uniformly sampled; blush/freckles flip independently at ~30% so most
  /// avatars stay uncluttered.
  factory AdventurerConfig.random({Random? random}) {
    final r = random ?? Random();
    return AdventurerConfig(
      hairIndex: r.nextInt(kHairStyles.length),
      hairColorIndex: r.nextInt(kHairColors.length),
      skinColorIndex: r.nextInt(kSkinColors.length),
      eyesIndex: r.nextInt(kEyeVariants.length),
      mouthIndex: r.nextInt(kMouthVariants.length),
      glassesIndex: r.nextInt(kGlassesOptions.length),
      earringsIndex: r.nextInt(kEarringsOptions.length),
      blush: r.nextDouble() < 0.3,
      freckles: r.nextDouble() < 0.3,
    );
  }

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
