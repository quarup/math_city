import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/day_clock.dart';
import 'package:math_city/presentation/city/clock_debug_sheet.dart';

void main() {
  late AmbientClock clock;
  late ValueNotifier<int> minute;
  late List<bool> pauses;

  Future<void> pump(WidgetTester tester, {bool paused = false}) async {
    clock = AmbientClock();
    minute = ValueNotifier<int>(quarterHourMinute(clock.hour));
    pauses = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClockDebugSheet(
            clock: clock,
            minuteOfDay: minute,
            paused: paused,
            onPausedChanged: pauses.add,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the clock time it opened at', (tester) async {
    await pump(tester);
    expect(find.text('9:30 am'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 9.5);
  });

  testWidgets('a preset jumps the clock there', (tester) async {
    await pump(tester);
    await tester.tap(find.text('8 pm'));
    await tester.pump();
    expect(clock.hour, 20);
    expect(find.text('8:00 pm'), findsOneWidget);
    await tester.tap(find.text('2 am'));
    await tester.pump();
    expect(clock.hour, 2);
    expect(find.text('2:00 am'), findsOneWidget);
  });

  testWidgets('the slider sets the hour, in quarter hours', (tester) async {
    await pump(tester);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(18.25);
    await tester.pump();
    expect(clock.hour, 18.25);
    expect(find.text('6:15 pm'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.max, 23.75);
    expect(slider.divisions, 95);
  });

  testWidgets('follows the clock as it runs', (tester) async {
    await pump(tester);
    clock.hour = 13;
    minute.value = quarterHourMinute(clock.hour);
    await tester.pump();
    expect(find.text('1:00 pm'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 13);
  });

  testWidgets('the pause switch reports to its owner', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(pauses, [true]);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(pauses, [true, false]);
  });

  testWidgets('opens showing a pause already in force', (tester) async {
    await pump(tester, paused: true);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });
}
