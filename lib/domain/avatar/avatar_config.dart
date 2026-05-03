import 'dart:convert';

import 'package:flutter/material.dart';

const List<Color> kSkinTones = [
  Color(0xFFFFE0BD),
  Color(0xFFEDBF96),
  Color(0xFFC68642),
  Color(0xFF8D5524),
  Color(0xFF4C2E05),
];

const List<Color> kHairColors = [
  Color(0xFF1A1A1A),
  Color(0xFF6B3A1A),
  Color(0xFFC07831),
  Color(0xFFDDB877),
  Color(0xFF888888),
  Color(0xFFF8F8FF),
];

const List<Color> kEyeColors = [
  Color(0xFF5C3D1A),
  Color(0xFF3A78C9),
  Color(0xFF4CAF50),
  Color(0xFF8B7355),
];

const List<Color> kTopColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFFB300),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
];

const List<Color> kBottomColors = [
  Color(0xFF1560BD),
  Color(0xFF212121),
  Color(0xFF757575),
  Color(0xFF8B4513),
  Color(0xFFD2B48C),
];

@immutable
class AvatarConfig {
  const AvatarConfig({
    this.skinToneIndex = 0,
    this.hairColorIndex = 0,
    this.hairStyleIndex = 0,
    this.eyeColorIndex = 0,
    this.topColorIndex = 0,
    this.bottomColorIndex = 0,
  });

  factory AvatarConfig.fromJsonString(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return AvatarConfig(
      skinToneIndex: (m['s'] as int?) ?? 0,
      hairColorIndex: (m['h'] as int?) ?? 0,
      hairStyleIndex: (m['hs'] as int?) ?? 0,
      eyeColorIndex: (m['e'] as int?) ?? 0,
      topColorIndex: (m['t'] as int?) ?? 0,
      bottomColorIndex: (m['b'] as int?) ?? 0,
    );
  }

  final int skinToneIndex;
  final int hairColorIndex;

  /// 0 = short, 1 = long.
  final int hairStyleIndex;

  final int eyeColorIndex;
  final int topColorIndex;
  final int bottomColorIndex;

  Color get skinTone =>
      kSkinTones[skinToneIndex.clamp(0, kSkinTones.length - 1)];
  Color get hairColor =>
      kHairColors[hairColorIndex.clamp(0, kHairColors.length - 1)];
  Color get eyeColor =>
      kEyeColors[eyeColorIndex.clamp(0, kEyeColors.length - 1)];
  Color get topColor =>
      kTopColors[topColorIndex.clamp(0, kTopColors.length - 1)];
  Color get bottomColor =>
      kBottomColors[bottomColorIndex.clamp(0, kBottomColors.length - 1)];

  String toJsonString() => jsonEncode(<String, int>{
    's': skinToneIndex,
    'h': hairColorIndex,
    'hs': hairStyleIndex,
    'e': eyeColorIndex,
    't': topColorIndex,
    'b': bottomColorIndex,
  });

  AvatarConfig copyWith({
    int? skinToneIndex,
    int? hairColorIndex,
    int? hairStyleIndex,
    int? eyeColorIndex,
    int? topColorIndex,
    int? bottomColorIndex,
  }) => AvatarConfig(
    skinToneIndex: skinToneIndex ?? this.skinToneIndex,
    hairColorIndex: hairColorIndex ?? this.hairColorIndex,
    hairStyleIndex: hairStyleIndex ?? this.hairStyleIndex,
    eyeColorIndex: eyeColorIndex ?? this.eyeColorIndex,
    topColorIndex: topColorIndex ?? this.topColorIndex,
    bottomColorIndex: bottomColorIndex ?? this.bottomColorIndex,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarConfig &&
          skinToneIndex == other.skinToneIndex &&
          hairColorIndex == other.hairColorIndex &&
          hairStyleIndex == other.hairStyleIndex &&
          eyeColorIndex == other.eyeColorIndex &&
          topColorIndex == other.topColorIndex &&
          bottomColorIndex == other.bottomColorIndex;

  @override
  int get hashCode => Object.hash(
    skinToneIndex,
    hairColorIndex,
    hairStyleIndex,
    eyeColorIndex,
    topColorIndex,
    bottomColorIndex,
  );
}
