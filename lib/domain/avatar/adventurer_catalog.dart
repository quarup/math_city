import 'package:flutter/material.dart';

// 8 picks from Adventurer's long01..long26, short01..short19
const kHairStyles = <String>[
  'short01',
  'short05',
  'short10',
  'short15',
  'long01',
  'long05',
  'long10',
  'long20',
];

const kHairStyleLabels = <String>[
  'Crop',
  'Waves',
  'Spiky',
  'Bob',
  'Flowing',
  'Braided',
  'Long Waves',
  'Wild',
];

// Hair colors: hex without # (DiceBear format)
const kHairColors = <String>[
  '0e0e0e',
  '3d1c02',
  'a56531',
  'f0d060',
  '9d9d9d',
  'e8e8e8',
];

const kHairColorLabels = <String>[
  'Black',
  'Brown',
  'Auburn',
  'Blonde',
  'Grey',
  'Silver',
];

// Skin colors: hex without # (DiceBear Adventurer default palette)
const kSkinColors = <String>[
  'ffdbb4',
  'edb98a',
  'ae5d29',
  '614335',
];

const kSkinColorLabels = <String>[
  'Light',
  'Medium',
  'Tan',
  'Dark',
];

// 5 picks from variant01..variant26
const kEyeVariants = <String>[
  'variant01',
  'variant06',
  'variant11',
  'variant16',
  'variant21',
];

// 5 picks from variant01..variant30
const kMouthVariants = <String>[
  'variant01',
  'variant05',
  'variant10',
  'variant15',
  'variant20',
];

// index 0 = none, 1..5 = variant01..variant05
const kGlassesOptions = <String?>[
  null,
  'variant01',
  'variant02',
  'variant03',
  'variant04',
  'variant05',
];

// index 0 = none, 1..6 = variant01..variant06
const kEarringsOptions = <String?>[
  null,
  'variant01',
  'variant02',
  'variant03',
  'variant04',
  'variant05',
  'variant06',
];

Color hairColorSwatch(int index) {
  final hex = kHairColors[index.clamp(0, kHairColors.length - 1)];
  return Color(int.parse('ff$hex', radix: 16));
}

Color skinColorSwatch(int index) {
  final hex = kSkinColors[index.clamp(0, kSkinColors.length - 1)];
  return Color(int.parse('ff$hex', radix: 16));
}
