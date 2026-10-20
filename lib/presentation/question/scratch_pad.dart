import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/presentation/diagrams/diagram_renderer.dart';

/// The scratch pad: squared paper a kid writes on with a finger while
/// working a long question (prd.md *Scratch pad*; which concepts get one is
/// `usesScratchPad` in the domain layer).
///
/// Pieces:
/// * [ScratchPadController] holds the strokes and the current tool.
/// * [ScratchPaper] is the paper itself — grid, the question's figure
///   printed on it, the ink, the eraser ring, the tool pill.
/// * [InkPainter] paints strokes, also used by the red screen to show the
///   player's work next to the explanation.
/// * [PaperFigurePainter] prints a [ColumnArithmeticSpec] in digit cells two
///   squares wide, so the kid's own digits land in the same cells.
/// * [scratchSlideDistance] is the rule that keeps the last ink visible when
///   the keypad slides over the paper.

/// Side of one paper square, in dp — 5 mm quad paper at roughly 112 dp per
/// inch. Digit cells on the printed figures are two squares.
const double kPaperSquare = 22;

/// Pen stroke width and eraser diameter, in dp.
const double kPenWidth = 3.2;
const double kEraserWidth = 26;

/// How far above the keypad's top edge the last stroke is kept.
const double kInkKeepClear = 18;

/// Blue-black, so handwriting reads as handwriting next to the printed
/// black question.
const Color kInkColor = Color(0xFF25407A);

enum InkTool { pen, eraser }

/// One stroke: pen ink or eraser rubbing, points in paper dp.
class InkStroke {
  InkStroke({required this.erase, required Offset first}) : points = [first];

  final bool erase;
  final List<Offset> points;
}

/// Everything the player drew, with the size of the paper it was drawn on
/// so another surface (the red screen) can scale it to fit.
class ScratchInk {
  const ScratchInk({
    required this.strokes,
    required this.paperSize,
    this.figure,
  });

  final List<InkStroke> strokes;
  final Size paperSize;

  /// The column figure that was printed on the paper, if any, so the work
  /// can be shown again under the sum it was done for.
  final ColumnArithmeticSpec? figure;

  bool get isEmpty => !strokes.any((s) => !s.erase);

  /// Bottom edge of the most recent pen stroke, or null when there is none.
  double? get lastInkBottom => _lastPenExtent((p) => p.dy);

  /// Right edge of the most recent pen stroke, or null when there is none.
  double? get lastInkRight => _lastPenExtent((p) => p.dx);

  double? _lastPenExtent(double Function(Offset) axis) {
    for (final s in strokes.reversed) {
      if (s.erase) continue;
      return s.points.map(axis).reduce(math.max);
    }
    return null;
  }
}

/// Holds the strokes while a question is on screen and tells the paper to
/// repaint as they grow.
class ScratchPadController extends ChangeNotifier {
  final List<InkStroke> _strokes = [];
  InkTool _tool = InkTool.pen;

  /// Set by the paper on layout, so the ink remembers what it was drawn on.
  Size paperSize = Size.zero;

  /// The column figure printed on the paper, if any (set by the paper).
  ColumnArithmeticSpec? figure;

  /// Where the eraser ring is shown while the eraser is down, else null.
  Offset? eraserAt;

  InkTool get tool => _tool;
  set tool(InkTool t) {
    if (t == _tool) return;
    _tool = t;
    eraserAt = null;
    notifyListeners();
  }

  ScratchInk get ink => ScratchInk(
    strokes: List.unmodifiable(_strokes),
    paperSize: paperSize,
    figure: figure,
  );

  bool get canUndo => _strokes.isNotEmpty;

  void begin(Offset p) {
    _strokes.add(InkStroke(erase: _tool == InkTool.eraser, first: p));
    if (_tool == InkTool.eraser) eraserAt = p;
    notifyListeners();
  }

  void extend(Offset p) {
    if (_strokes.isEmpty) return;
    final pts = _strokes.last.points;
    if ((p - pts.last).distance < 0.8) return;
    pts.add(p);
    if (_tool == InkTool.eraser) eraserAt = p;
    notifyListeners();
  }

  void end() {
    eraserAt = null;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }
}

/// How far the paper slides (up, or left on a side) when a keypad covering
/// [covered] of its [paperExtent] opens, so the most recent ink stays
/// [kInkKeepClear] clear of it. Nothing moves when the last ink is already
/// in view, and the paper never slides further than the keypad is tall.
double scratchSlideDistance({
  required double? lastInk,
  required double paperExtent,
  required double covered,
}) {
  if (covered <= 0 || lastInk == null) return 0;
  final visible = paperExtent - covered;
  return (lastInk + kInkKeepClear - visible).clamp(0.0, covered);
}

/// Whether a question's figure is printed on the paper by
/// [PaperFigurePainter] (and the "Multiply." / "Divide." prompt card left
/// out, the figure saying it all) rather than rendered as its widget.
bool isPaperFigure(DiagramSpec? spec) => spec is ColumnArithmeticSpec;

/// The paper. Fills the box it is given.
class ScratchPaper extends StatefulWidget {
  const ScratchPaper({
    required this.controller,
    this.figure,
    this.toolsOnLeft = false,
    this.corner,
    super.key,
  });

  final ScratchPadController controller;

  /// The question's diagram, printed at the top of the paper: a column
  /// figure aligned to the squares, or any other diagram at its own size.
  final DiagramSpec? figure;

  /// Put the tool pill bottom-left (when [corner] takes the bottom-right).
  final bool toolsOnLeft;

  /// A widget floated over the paper's bottom-right corner (the Answer
  /// button on a phone on its side).
  final Widget? corner;

  @override
  State<ScratchPaper> createState() => _ScratchPaperState();
}

class _ScratchPaperState extends State<ScratchPaper> {
  /// Only the first finger draws; a second one (or a resting palm) is
  /// ignored until the first lifts.
  int? _pointer;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    widget.controller.begin(e.localPosition);
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    widget.controller.extend(e.localPosition);
  }

  void _up(int pointer) {
    if (pointer != _pointer) return;
    _pointer = null;
    widget.controller.end();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final figure = widget.figure;
    final ink = theme.colorScheme.onSurface;
    return LayoutBuilder(
      builder: (context, c) {
        controller
          ..paperSize = Size(c.maxWidth, c.maxHeight)
          ..figure = isPaperFigure(figure)
              ? figure! as ColumnArithmeticSpec
              : null;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBFCFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _GridPainter()),
                if (isPaperFigure(figure))
                  CustomPaint(
                    painter: PaperFigurePainter(
                      spec: figure! as ColumnArithmeticSpec,
                      color: ink,
                    ),
                  )
                else if (figure != null)
                  // The diagram sits at the top, capped at 45 % of the paper
                  // so there is always room to work under it.
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: c.maxHeight * 0.45,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: c.maxWidth - 16,
                          ),
                          child: DiagramRenderer(spec: figure),
                        ),
                      ),
                    ),
                  ),
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _down,
                  onPointerMove: _move,
                  onPointerUp: (e) => _up(e.pointer),
                  onPointerCancel: (e) => _up(e.pointer),
                  child: CustomPaint(
                    painter: InkPainter(controller: controller),
                  ),
                ),
                _EraserRing(controller: controller),
                Positioned(
                  bottom: 10,
                  left: widget.toolsOnLeft ? 10 : null,
                  right: widget.toolsOnLeft ? null : 10,
                  child: _ToolPill(controller: controller),
                ),
                if (widget.corner != null)
                  Positioned(bottom: 10, right: 10, child: widget.corner!),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The translucent disc that follows the finger while erasing, at the
/// eraser's true size.
class _EraserRing extends StatelessWidget {
  const _EraserRing({required this.controller});

  final ScratchPadController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final at = controller.eraserAt;
      if (at == null) return const SizedBox.shrink();
      return Positioned(
        left: at.dx - kEraserWidth / 2,
        top: at.dy - kEraserWidth / 2,
        child: IgnorePointer(
          child: Container(
            width: kEraserWidth,
            height: kEraserWidth,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kInkColor.withValues(alpha: 0.12),
              border: Border.all(
                color: kInkColor.withValues(alpha: 0.75),
                width: 1.5,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Pen, eraser, undo. No clear button: the pad empties itself with the
/// next question, and a stray tap on a clear would lose minutes of work.
class _ToolPill extends StatelessWidget {
  const _ToolPill({required this.controller});

  final ScratchPadController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        elevation: 2,
        shape: StadiumBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Pen',
                selected: controller.tool == InkTool.pen,
                onTap: () => controller.tool = InkTool.pen,
              ),
              _ToolButton(
                icon: const EraserIcon(),
                tooltip: 'Eraser',
                selected: controller.tool == InkTool.eraser,
                onTap: () => controller.tool = InkTool.eraser,
              ),
              _ToolButton(
                icon: const Icon(Icons.undo_rounded),
                tooltip: 'Undo',
                selected: false,
                onTap: controller.canUndo ? controller.undo : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onTap,
      isSelected: selected,
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        backgroundColor: selected ? scheme.primaryContainer : null,
        disabledForegroundColor: scheme.onSurfaceVariant.withValues(
          alpha: 0.35,
        ),
      ),
    );
  }
}

/// An eraser: a block tilted at 45° with its sleeve line, on a baseline.
/// Flutter's icon font has no eraser glyph (its nearest is a brush, which
/// playtesters read as a paint tool), so this is drawn as paths, the same
/// on every platform. Takes its colour and size from the ambient
/// [IconTheme] like any icon.
class EraserIcon extends StatelessWidget {
  const EraserIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _EraserPainter(
          color: (theme.color ?? Colors.black).withValues(
            alpha: theme.opacity ?? 1,
          ),
        ),
      ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  const _EraserPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => Offset(x * k, y * k);
    // The block: a rounded rectangle lying at 45°, long axis lower-left to
    // upper-right.
    final block = Path()
      ..moveTo(p(3, 15).dx, p(3, 15).dy)
      ..lineTo(p(12.5, 5.5).dx, p(12.5, 5.5).dy)
      ..lineTo(p(18.5, 11.5).dx, p(18.5, 11.5).dy)
      ..lineTo(p(9, 21).dx, p(9, 21).dy)
      ..close();
    canvas
      ..drawPath(block, paint)
      // The sleeve: the line between the rubber and the holder.
      ..drawLine(p(7.5, 10.5), p(13.5, 16.5), paint)
      // The baseline it has just rubbed along.
      ..drawLine(p(11, 21), p(21, 21), paint);
  }

  @override
  bool shouldRepaint(_EraserPainter old) => old.color != color;
}

/// 5 mm squares.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4DEE8)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += kPaperSquare) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += kPaperSquare) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Paints ink: live from a [controller] (repainting as it changes) or a
/// finished [ink] scaled down to fit the box, top-aligned and centred, on
/// its squared paper with the figure it was written under.
class InkPainter extends CustomPainter {
  InkPainter({this.controller, this.ink})
    : assert((controller == null) != (ink == null), 'one source'),
      super(repaint: controller);

  final ScratchPadController? controller;
  final ScratchInk? ink;

  @override
  void paint(Canvas canvas, Size size) {
    final source = ink ?? controller!.ink;
    final strokes = source.strokes;
    canvas.save();
    if (ink != null && source.paperSize.width > 0) {
      final paper = source.paperSize;
      final k = math.min(size.width / paper.width, size.height / paper.height);
      canvas
        ..translate((size.width - paper.width * k) / 2, 0)
        ..scale(k)
        ..clipRect(Offset.zero & paper);
      const _GridPainter().paint(canvas, paper);
      final figure = source.figure;
      if (figure != null) {
        PaperFigurePainter(
          spec: figure,
          color: const Color(0xFF1F2B2A),
        ).paint(canvas, paper);
      }
    }
    if (strokes.isEmpty) {
      canvas.restore();
      return;
    }
    // One layer, so the eraser clears ink without punching through the
    // paper underneath.
    canvas.saveLayer(null, Paint());
    final pen = Paint()
      ..color = kInkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = kPenWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = kEraserWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      canvas.drawPath(_pathFor(s.points), s.erase ? eraser : pen);
    }
    canvas
      ..restore()
      ..restore();
  }

  /// Points joined through the midpoints with quadratic curves, which
  /// rounds off the polygon a finger sampled at 60–120 Hz leaves behind.
  static Path _pathFor(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    if (p.length == 1) {
      path.lineTo(p[0].dx, p[0].dy);
      return path;
    }
    for (var i = 1; i < p.length - 1; i++) {
      final m = (p[i] + p[i + 1]) / 2;
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(InkPainter old) => old.ink != ink;
}

/// Prints a [ColumnArithmeticSpec] on the paper in cells two squares on a
/// side, starting two squares down. Stacked operations are right-aligned
/// with the operator in its own cell and the rule on a grid line; only the
/// operands and the rule are printed — carries, partial products and the
/// answer are the kid's to write. Division is the house: divisor, bracket,
/// dividend under its bar, an empty quotient row above.
class PaperFigurePainter extends CustomPainter {
  const PaperFigurePainter({required this.spec, required this.color});

  final ColumnArithmeticSpec spec;
  final Color color;

  static const double _cell = kPaperSquare * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: kPaperSquare * 1.55,
      color: color,
    );
    void glyph(String ch, int col, int row) {
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          col * kPaperSquare + (_cell - tp.width) / 2,
          row * kPaperSquare + (_cell - tp.height) / 2,
        ),
      );
    }

    final rule = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final cols = (size.width / kPaperSquare).floor();

    if (spec.op == ColumnArithmeticOp.div) {
      final dividend = '${spec.operands[0]}';
      final divisor = '${spec.operands[1]}';
      const row = 4; // quotient row is 2, dividend row 4
      var col = 1;
      for (final ch in divisor.split('')) {
        glyph(ch, col, row);
        col += 2;
      }
      final barLeft = (col + 1) * kPaperSquare;
      for (final ch in dividend.split('')) {
        glyph(ch, col + 1, row);
        col += 2;
      }
      final barRight = (col + 1) * kPaperSquare;
      const barY = row * kPaperSquare;
      canvas.drawLine(Offset(barLeft, barY), Offset(barRight, barY), rule);
      final bracket = Path()
        ..moveTo(barLeft, barY)
        ..quadraticBezierTo(
          barLeft - kPaperSquare * 0.6,
          barY + kPaperSquare * 1.1,
          barLeft - kPaperSquare * 0.1,
          barY + _cell,
        );
      canvas.drawPath(bracket, rule..style = PaintingStyle.stroke);
      return;
    }

    final maxLen = spec.operands.map((v) => '$v'.length).reduce(math.max);
    // Right edge column: two squares in from the right on a phone, no
    // further out than the figure needs on a wide paper.
    final endCol = math.min(cols - 2, 2 * (maxLen + 2));
    final opCol = endCol - 2 * (maxLen + 1);
    var row = 2;
    for (final (i, v) in spec.operands.indexed) {
      final digits = '$v';
      var col = endCol - 2 * digits.length;
      for (final ch in digits.split('')) {
        glyph(ch, col, row);
        col += 2;
      }
      if (i == spec.operands.length - 1) {
        glyph(
          switch (spec.op) {
            ColumnArithmeticOp.add => '+',
            ColumnArithmeticOp.sub => '−',
            _ => '×',
          },
          opCol,
          row,
        );
      }
      row += 2;
    }
    final y = row * kPaperSquare;
    canvas.drawLine(
      Offset(opCol * kPaperSquare, y),
      Offset(endCol * kPaperSquare, y),
      rule,
    );
  }

  @override
  bool shouldRepaint(PaperFigurePainter old) =>
      old.spec != spec || old.color != color;
}
