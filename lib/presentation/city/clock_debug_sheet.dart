import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:math_city/domain/city/day_clock.dart';

/// Debug-only control over the town clock, opened by tapping the clock chip
/// on the city screen: drag to any time of day, jump to a preset, or pause
/// the clock to look at one moment. The town stays in view behind the sheet
/// and follows as the slider moves.
class ClockDebugSheet extends StatefulWidget {
  const ClockDebugSheet({
    required this.clock,
    required this.minuteOfDay,
    required this.paused,
    required this.onPausedChanged,
    super.key,
  });

  /// The game's clock; the sheet writes its hour directly.
  final AmbientClock clock;

  /// Ticks every quarter hour: keeps the readout and the slider in step
  /// while the clock runs.
  final ValueListenable<int> minuteOfDay;

  /// Whether the clock is paused from here. The screen owns it, so the
  /// pause outlasts the sheet.
  final bool paused;
  final ValueChanged<bool> onPausedChanged;

  /// The last quarter hour of the day: the slider's top end.
  static const double maxHour = 23.75;

  /// Moments worth a look: the tint's turns and the light schedules' edges.
  /// Short labels, so the row fits a phone and the sheet stays low.
  static const presets = <(String, double)>[
    ('6 am', 6),
    ('Noon', 12),
    ('6 pm', 18),
    ('8 pm', 20),
    ('11 pm', 23),
    ('2 am', 2),
  ];

  @override
  State<ClockDebugSheet> createState() => _ClockDebugSheetState();
}

class _ClockDebugSheetState extends State<ClockDebugSheet> {
  late bool _paused = widget.paused;

  void _setHour(double hour) => setState(() => widget.clock.hour = hour);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ValueListenableBuilder<int>(
          valueListenable: widget.minuteOfDay,
          builder: (context, _, _) {
            final hour = widget.clock.hour.clamp(0.0, ClockDebugSheet.maxHour);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded),
                    const SizedBox(width: 8),
                    Text('Town clock', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      formatHour(quarterHourMinute(hour) / 60),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: hour,
                  max: ClockDebugSheet.maxHour,
                  divisions: 95,
                  label: formatHour(hour),
                  onChanged: _setHour,
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final (label, at) in ClockDebugSheet.presets)
                      ActionChip(
                        label: Text(label),
                        visualDensity: VisualDensity.compact,
                        labelPadding: EdgeInsets.zero,
                        onPressed: () => _setHour(at),
                      ),
                  ],
                ),
                // The pause outlasts the sheet, for this visit to the city.
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pause the clock'),
                  value: _paused,
                  onChanged: (v) {
                    setState(() => _paused = v);
                    widget.onPausedChanged(v);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
