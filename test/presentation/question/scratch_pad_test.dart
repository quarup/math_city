import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/presentation/question/scratch_pad.dart';

void main() {
  group('scratchSlideDistance', () {
    test('nothing moves when the keypad covers no paper', () {
      expect(
        scratchSlideDistance(lastInk: 400, paperExtent: 500, covered: 0),
        0,
      );
    });

    test('nothing moves when the last ink is already in view', () {
      // 500 of paper, 300 covered → 200 visible; ink at 100 is clear.
      expect(
        scratchSlideDistance(lastInk: 100, paperExtent: 500, covered: 300),
        0,
      );
    });

    test('slides just enough to keep the last ink clear of the keypad', () {
      final d = scratchSlideDistance(
        lastInk: 350,
        paperExtent: 500,
        covered: 300,
      );
      expect(d, 350 + kInkKeepClear - 200);
    });

    test('never slides further than the keypad is tall', () {
      expect(
        scratchSlideDistance(lastInk: 495, paperExtent: 500, covered: 300),
        300,
      );
    });

    test('an empty pad stays put', () {
      expect(
        scratchSlideDistance(lastInk: null, paperExtent: 500, covered: 300),
        0,
      );
    });
  });

  group('ScratchPadController', () {
    test('records pen strokes and reports the last ink edge', () {
      final c = ScratchPadController()
        ..paperSize = const Size(300, 400)
        ..begin(const Offset(10, 20))
        ..extend(const Offset(50, 80))
        ..end()
        ..begin(const Offset(100, 200))
        ..extend(const Offset(120, 260))
        ..end();
      final ink = c.ink;
      expect(ink.strokes, hasLength(2));
      expect(ink.isEmpty, isFalse);
      expect(ink.lastInkBottom, 260);
      expect(ink.lastInkRight, 120);
      expect(ink.paperSize, const Size(300, 400));
    });

    test('eraser strokes do not count as ink', () {
      final c = ScratchPadController()
        ..tool = InkTool.eraser
        ..begin(const Offset(10, 20))
        ..end();
      expect(c.ink.isEmpty, isTrue);
      expect(c.ink.lastInkBottom, isNull);
    });

    test('the eraser ring follows the finger and lifts with it', () {
      final c = ScratchPadController()
        ..tool = InkTool.eraser
        ..begin(const Offset(10, 20));
      expect(c.eraserAt, const Offset(10, 20));
      c.extend(const Offset(30, 40));
      expect(c.eraserAt, const Offset(30, 40));
      c.end();
      expect(c.eraserAt, isNull);
    });

    test('undo removes the last stroke, whatever its tool', () {
      final c = ScratchPadController()
        ..begin(const Offset(10, 20))
        ..end()
        ..tool = InkTool.eraser
        ..begin(const Offset(10, 20))
        ..end();
      expect(c.canUndo, isTrue);
      c.undo();
      expect(c.ink.strokes.single.erase, isFalse);
      c.undo();
      expect(c.canUndo, isFalse);
      c.undo(); // nothing left: no throw
    });
  });

  testWidgets('the paper draws a stroke from a finger and ignores a second', (
    tester,
  ) async {
    final c = ScratchPadController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: ScratchPaper(controller: c),
          ),
        ),
      ),
    );
    final paper = tester.getTopLeft(find.byType(ScratchPaper));
    final first = await tester.startGesture(paper + const Offset(50, 50));
    final second = await tester.startGesture(paper + const Offset(200, 200));
    await first.moveTo(paper + const Offset(90, 120));
    await second.moveTo(paper + const Offset(220, 260));
    await first.up();
    await second.up();
    await tester.pump();
    expect(c.ink.strokes, hasLength(1));
    expect(c.ink.lastInkBottom, 120);
    expect(find.byTooltip('Pen'), findsOneWidget);
    expect(find.byTooltip('Eraser'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);
  });
}
