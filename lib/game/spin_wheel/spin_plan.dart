import 'dart:math' as math;

/// The wheel's free spin is exponential decay: `ω(t) = ω₀·e^(−k·t)`,
/// stopping once `|ω|` drops below [kSpinStopVelocity]. So a spin started
/// at `ω₀` with decay `k` travels `(|ω₀| − stop) / k` radians in all.
const double kSpinStopVelocity = 0.05;

/// Normal friction: what a strong throw spins down with.
const double kSpinDecay = 1.5;

/// The least a selecting spin travels before the random extra: a short
/// throw is "lubricated" up to this many turns so it still feels like a
/// spin.
const double kMinSpinTurns = 1.5;

/// The lowest friction a lubricated spin gets. Below it the spin would
/// crawl for too long, so the start speed is raised instead.
const double kMinSpinDecay = 0.9;

/// How a released throw spins: its start speed (signed, rad/s) and decay
/// rate (1/s).
typedef SpinPlan = ({double velocity, double decay});

/// Total angle a spin of [velocity] and [decay] travels before it stops.
double spinTravel(double velocity, double decay) =>
    (velocity.abs() - kSpinStopVelocity) / decay;

/// The spin for a selecting throw of [velocity] (signed, rad/s).
///
/// A throw that would travel [kMinSpinTurns] turns or more on normal
/// friction spins as thrown. A shorter one is lubricated: it travels
/// [kMinSpinTurns] turns plus [extraTurns] (`0 ≤ extraTurns < 1`, drawn at
/// random by the caller). That extra makes where it lands uniformly
/// random, so a gentle flick from a chosen spot can't pick the slice. The
/// distance comes from lowering the friction, keeping the speed the
/// child threw at; only below [kMinSpinDecay] is the start speed raised.
SpinPlan planSpin(double velocity, {required double extraTurns}) {
  const minTravel = kMinSpinTurns * 2 * math.pi;
  if (spinTravel(velocity, kSpinDecay) >= minTravel) {
    return (velocity: velocity, decay: kSpinDecay);
  }
  final travel = (kMinSpinTurns + extraTurns) * 2 * math.pi;
  final sign = velocity < 0 ? -1.0 : 1.0;
  final decay = (velocity.abs() - kSpinStopVelocity) / travel;
  if (decay >= kMinSpinDecay) return (velocity: velocity, decay: decay);
  return (
    velocity: sign * (kMinSpinDecay * travel + kSpinStopVelocity),
    decay: kMinSpinDecay,
  );
}
