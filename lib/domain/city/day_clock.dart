/// The ambient day (city_builder.md §11, D2 + K1 + S4): an eight-minute
/// loop — five minutes of day, three of night — that colours the sky haze
/// and tints the town. The clock is frozen at 9:30 through chapter one and
/// pauses while a question screen covers the city.
///
/// Pure Dart: no Flutter / Flame / Drift imports. Colours are plain
/// `0xRRGGBB` ints; the painter wraps them.
library;

/// The horizon colour by hour (K1): near-black at midnight, dark grey →
/// peach → white at dawn, off-white through the day, orange → grey-brown
/// → dark at dusk. Interpolation only ever runs between neighbouring keys,
/// so there is no purple between night and dawn.
const List<(double, int)> kHazeKeys = <(double, int)>[
  (0, 0x0E1118),
  (4.5, 0x141821),
  (5.5, 0x3C4049),
  (6.5, 0xF1CBA4),
  (7.5, 0xF3EBDD),
  (9, 0xEDF3F8),
  (13, 0xE8F0F6),
  (17, 0xF0EEE8),
  (18.5, 0xF3C58F),
  (19.5, 0x8E7568),
  (20.5, 0x3A3C47),
  (22, 0x171A22),
  (24, 0x0E1118),
];

/// How dark the town is, `0` by day to `1` at night; drives the multiply
/// tint. Keys from the mocks' `timeOfDay`.
const List<(double, double)> _nightKeys = <(double, double)>[
  (0, 1),
  (5, 0.85),
  (6.5, 0.35),
  (8, 0),
  (16, 0),
  (18.5, 0.25),
  (20, 0.8),
  (21.5, 1),
  (24, 1),
];

/// The warm wash at dawn and dusk, `0..1`.
const List<(double, double)> _duskKeys = <(double, double)>[
  (0, 0),
  (5, 0.2),
  (6.5, 0.8),
  (8, 0.15),
  (16, 0.05),
  (18.5, 0.9),
  (20, 0.35),
  (21.5, 0),
  (24, 0),
];

double _wrap(double hour) => ((hour % 24) + 24) % 24;

/// Linear interpolation of a keyed value at [hour] between its two
/// neighbouring keys.
double _keyed(List<(double, double)> keys, double hour) {
  final h = _wrap(hour);
  var i = 0;
  while (i + 2 < keys.length && keys[i + 1].$1 <= h) {
    i++;
  }
  final (h0, v0) = keys[i];
  final (h1, v1) = keys[i + 1];
  return v0 + (v1 - v0) * ((h - h0) / (h1 - h0));
}

/// The haze colour at [hour], as `0xRRGGBB`.
int hazeColorAt(double hour) {
  final h = _wrap(hour);
  var i = 0;
  while (i + 2 < kHazeKeys.length && kHazeKeys[i + 1].$1 <= h) {
    i++;
  }
  final (h0, c0) = kHazeKeys[i];
  final (h1, c1) = kHazeKeys[i + 1];
  final t = (h - h0) / (h1 - h0);
  int mix(int shift) {
    final a = (c0 >> shift) & 0xFF;
    final b = (c1 >> shift) & 0xFF;
    return (a + (b - a) * t).round().clamp(0, 255);
  }

  return (mix(16) << 16) | (mix(8) << 8) | mix(0);
}

/// Night strength at [hour], `0` (full day) to `1` (deep night).
double nightStrengthAt(double hour) => _keyed(_nightKeys, hour);

/// Dusk warmth at [hour], `0..1`.
double duskWarmthAt(double hour) => _keyed(_duskKeys, hour);

/// The clock's hour through chapter one (S4): a fixed bright morning.
const double kChapterOneHour = 9.5;

/// The day runs from [kDayStartHour] to [kNightStartHour] in
/// [kDaySeconds]; the night takes the rest of the 24 hours in
/// [kNightSeconds]. Five minutes of day, three of night (D2).
const double kDayStartHour = 6.5;
const double kNightStartHour = 18.5;
const double kDaySeconds = 300;
const double kNightSeconds = 180;

bool isDaytime(double hour) {
  final h = _wrap(hour);
  return h >= kDayStartHour && h < kNightStartHour;
}

/// The hour [seconds] after [hour] at the day's or the night's rate. The
/// rate switches at the boundary a step crosses, so a long step keeps
/// time correctly.
double advanceHour(double hour, double seconds) {
  var h = _wrap(hour);
  var left = seconds;
  const dayHours = kNightStartHour - kDayStartHour;
  const nightHours = 24 - dayHours;
  while (left > 0) {
    final day = isDaytime(h);
    final rate = day ? dayHours / kDaySeconds : nightHours / kNightSeconds;
    final end = day
        ? kNightStartHour
        : (h >= kNightStartHour ? 24 + kDayStartHour : kDayStartHour);
    final toEnd = (end - h) / rate;
    if (left < toEnd) {
      h = _wrap(h + rate * left);
      break;
    }
    left -= toEnd;
    h = _wrap(end);
  }
  return h;
}

/// The ambient clock a city screen keeps: ticks with real time unless it
/// is [frozen] (chapter one) or [paused] (a question screen is up).
class AmbientClock {
  AmbientClock({this.hour = kChapterOneHour});

  double hour;
  bool frozen = false;
  bool paused = false;

  bool get running => !frozen && !paused;

  void tick(double seconds) {
    if (!running || seconds <= 0) return;
    hour = advanceHour(hour, seconds);
  }
}
