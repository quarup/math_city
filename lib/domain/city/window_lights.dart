/// When each window is lit (city_builder.md §12, D4).
///
/// Windows come on as it gets dark and are all out again before midnight —
/// nobody's window glows at 2 am — and a few come back for the early
/// risers before dawn. Signs and lamps are different: they burn from dusk
/// until dawn, like the street lanterns. Every window keeps its own times,
/// drawn from a hash of the building and the window, so a facade fills in
/// one window at a time and two houses of the same kind never switch
/// together; a shop's windows keep close to each other, because a shop
/// opens and closes as one.
///
/// Pure Dart: no Flutter / Flame / Drift imports.
library;

import 'package:math_city/domain/city/category.dart';

/// Who is behind the windows, which decides their hours.
enum LightProfile {
  /// Homes: evenings spread over hours, bedtimes too, early risers.
  home,

  /// Shops and eateries: on together at dusk, off together at closing.
  shop,

  /// Offices and schools: on at dusk, emptying through the evening.
  office,

  /// Hospital, police, fire station: staffed late, still dark by midnight.
  civic,

  /// Cinemas, stadiums, the amusement park: bright until late evening.
  venue,
}

const _homes = <String>{
  'single_home',
  'duplex',
  'townhouse_row',
  'apartment',
  'mid_rise_apartment',
  'high_rise',
  'luxury_condo',
  'farmhouse',
};

const _alwaysStaffed = <String>{
  'hospital',
  'clinic',
  'police_station',
  'fire_station',
  'power_plant',
  'power_station',
};

const _offices = <String>{'office_building', 'business_tower'};

/// The light profile of a building type.
LightProfile lightProfileFor({
  required String typeId,
  required BuildingCategory category,
}) {
  if (_homes.contains(typeId)) return LightProfile.home;
  if (_alwaysStaffed.contains(typeId)) return LightProfile.civic;
  if (_offices.contains(typeId)) return LightProfile.office;
  return switch (category) {
    BuildingCategory.housing => LightProfile.office,
    BuildingCategory.services => LightProfile.office,
    BuildingCategory.commercial => LightProfile.shop,
    BuildingCategory.entertainment => LightProfile.venue,
  };
}

/// No *window* is lit between these hours, whatever its profile. (Signs
/// and lamps stay on through them.)
const double kLightsOutHour = 0;
const double kFirstLightHour = 5.5;

/// How long a window takes to come on or go off, in clock hours (about a
/// second of real time at the day's pace).
const double kWindowFadeHours = 0.05;

/// A stable pseudo-random number in `[0, 1)` for one draw of one window.
double _draw(int seed, int index, int salt) {
  var h = (seed * 0x9E3779B1) ^ (index * 0x85EBCA6B) ^ (salt * 0xC2B2AE35);
  h &= 0xFFFFFFFF;
  h = ((h ^ (h >> 15)) * 0x2C1B3C6D) & 0xFFFFFFFF;
  h = ((h ^ (h >> 12)) * 0x297A2D39) & 0xFFFFFFFF;
  h ^= h >> 15;
  return h / 4294967296;
}

/// One window's hours: the evening it is lit, and a morning spell if it
/// has one. All within `[kFirstLightHour, 24)`.
class WindowHours {
  const WindowHours({
    required this.eveningOn,
    required this.eveningOff,
    this.morningOn,
    this.morningOff,
  }) : allNight = false;

  /// A sign or a lamp: on from [on] in the evening straight through the
  /// night until [off] the next morning.
  const WindowHours.allNight({required double on, required double off})
    : eveningOn = on,
      eveningOff = 24,
      morningOn = 0,
      morningOff = off,
      allNight = true;

  /// A window that never lights (an empty flat, a storeroom).
  static const never = WindowHours(eveningOn: 0, eveningOff: 0);

  final double eveningOn;
  final double eveningOff;
  final double? morningOn;
  final double? morningOff;

  /// Lit from dusk until dawn rather than in an evening and a morning spell.
  final bool allNight;

  bool get isNever => eveningOff <= eveningOn && morningOn == null;
}

/// The hours of window [index] of the building with [seed] (a stable id of
/// the placed building). [glow] is a sign or a lamp rather than a window:
/// it comes on with the building at dusk and stays on until dawn.
WindowHours windowHoursFor({
  required int seed,
  required int index,
  required LightProfile profile,
  bool glow = false,
}) {
  double r(int salt) => _draw(seed, index, salt);
  // Draws shared by the whole building (index −1).
  double b(int salt) => _draw(seed, -1, salt);
  if (glow) {
    // The whole building's signs and lamps switch on within minutes of
    // each other and go out one by one as it gets light.
    return WindowHours.allNight(
      on: 16.9 + b(2) * 0.3 + r(3) * 0.1,
      off: 6.3 + r(4) * 0.4,
    );
  }
  switch (profile) {
    case LightProfile.home:
      // One flat in eight stays dark; the rest come home over the evening
      // and go to bed over the night. A third are up before dawn.
      if (r(1) < 0.12) return WindowHours.never;
      final early = r(2) < 0.35;
      return WindowHours(
        eveningOn: 17.25 + r(3) * 2.75,
        eveningOff: 21.0 + r(4) * 2.5,
        morningOn: early ? 5.6 + r(5) * 0.9 : null,
        morningOff: early ? 7.0 + r(6) * 0.8 : null,
      );
    case LightProfile.shop:
      // The shop switches on as one, give or take a few minutes, and
      // closes as one.
      return WindowHours(
        eveningOn: 16.9 + b(3) * 0.4 + r(3) * 0.15,
        eveningOff: 20.5 + b(4) * 1.5 + r(4) * 0.2,
      );
    case LightProfile.office:
      if (r(1) < 0.1) return WindowHours.never;
      final early = r(2) < 0.3;
      return WindowHours(
        eveningOn: 16.75 + r(3) * 1.0,
        eveningOff: 18.5 + r(4) * 3.0,
        morningOn: early ? 6.2 + r(5) * 0.6 : null,
        morningOff: early ? 7.4 + r(6) * 0.5 : null,
      );
    case LightProfile.civic:
      final early = r(2) < 0.5;
      return WindowHours(
        eveningOn: 16.9 + r(3) * 1.0,
        eveningOff: 22.5 + r(4) * 1.25,
        morningOn: early ? 5.6 + r(5) * 0.6 : null,
        morningOff: early ? 7.2 + r(6) * 0.6 : null,
      );
    case LightProfile.venue:
      return WindowHours(
        eveningOn: 16.9 + b(3) * 0.3 + r(3) * 0.4,
        eveningOff: 22.5 + b(4) * 0.75 + r(4) * 0.5,
      );
  }
}

double _spell(double hour, double on, double off) {
  if (off <= on || hour <= on || hour >= off) return 0;
  final rise = (hour - on) / kWindowFadeHours;
  final fall = (off - hour) / kWindowFadeHours;
  final level = rise < fall ? rise : fall;
  return level > 1 ? 1 : level;
}

/// How lit a window with [hours] is at [hour]: `0` off, `1` on, in between
/// while it fades.
double windowLightAt(double hour, WindowHours hours) {
  final h = ((hour % 24) + 24) % 24;
  if (hours.allNight) {
    double ramp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
    if (h >= hours.eveningOn) {
      return ramp((h - hours.eveningOn) / kWindowFadeHours);
    }
    return ramp((hours.morningOff! - h) / kWindowFadeHours);
  }
  if (h < kFirstLightHour) return 0;
  final evening = _spell(h, hours.eveningOn, hours.eveningOff);
  final on = hours.morningOn;
  final off = hours.morningOff;
  if (on == null || off == null) return evening;
  final morning = _spell(h, on, off);
  return evening > morning ? evening : morning;
}
