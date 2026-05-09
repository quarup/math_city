// ignore_for_file: lines_longer_than_80_chars // long lines are SVG constants
import 'package:math_city/domain/avatar/adventurer_catalog.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/avatar/adventurer_svg_data.dart';

// Hair styles whose length covers the earring position.
const _kEarringBlockedStyles = {
  'long01', 'long04', 'long05', 'long06',
  'long20', 'long22', 'long24', 'long26',
};

String composeAdventurer(AdventurerConfig config) {
  final hairStyle =
      kHairStyles[config.hairIndex.clamp(0, kHairStyles.length - 1)];
  final hairHex =
      '#${kHairColors[config.hairColorIndex.clamp(0, kHairColors.length - 1)]}';
  final skinHex =
      '#${kSkinColors[config.skinColorIndex.clamp(0, kSkinColors.length - 1)]}';

  final eyeVariant =
      kEyeVariants[config.eyesIndex.clamp(0, kEyeVariants.length - 1)];
  final mouthVariant =
      kMouthVariants[config.mouthIndex.clamp(0, kMouthVariants.length - 1)];

  final glassesVariant =
      kGlassesOptions[config.glassesIndex.clamp(0, kGlassesOptions.length - 1)];
  final earringsVariant =
      kEarringsOptions[config.earringsIndex.clamp(0, kEarringsOptions.length - 1)];

  final base = kAdventurerBase.replaceAll('__SKIN__', skinHex);
  final hair = (kAdventurerHair[hairStyle] ?? '').replaceAll('__HAIR__', hairHex);

  final eyesSvg = kAdventurerEyes[eyeVariant] ?? '';
  final mouthSvg = kAdventurerMouth[mouthVariant] ?? '';
  final glassesSvg =
      glassesVariant != null ? (kAdventurerGlasses[glassesVariant] ?? '') : '';
  final earringsSvg =
      earringsVariant != null && !_kEarringBlockedStyles.contains(hairStyle)
          ? (kAdventurerEarrings[earringsVariant] ?? '')
          : '';

  final blushSvg = config.blush ? (kAdventurerFeatures['blush'] ?? '') : '';
  final frecklesSvg =
      config.freckles ? (kAdventurerFeatures['freckles'] ?? '') : '';

  // Layer order from DiceBear index.ts:
  // base → eyes → eyebrows → mouth → features → glasses → hair → earrings
  // All except base get translate(-161 -83).
  const t = '<g transform="translate(-161 -83)">';
  const te = '</g>';

  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 762 762">'
      '$base'
      '$t$eyesSvg$te'
      '$t$kAdventurerEyebrows$te'
      '$t$mouthSvg$te'
      '$t$blushSvg$frecklesSvg$te'
      '$t$glassesSvg$te'
      '$t$hair$te'
      '$t$earringsSvg$te'
      '</svg>';
}
