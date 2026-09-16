import 'dart:async';

import 'package:flutter/material.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/presentation/theme/category_colors.dart';

/// Overlay shown the first time the wheel lands on a concept the player has
/// never answered — the "you unlocked something" moment now lives on the
/// wheel rather than on the block summary. Pops in, then continues into the
/// question block on tap or after [autoAdvance] (so an unattended flow, such
/// as the emulator-driven smoke test, never stalls here).
class NewConceptCelebration extends StatefulWidget {
  const NewConceptCelebration({
    required this.concept,
    required this.onDone,
    this.autoAdvance = const Duration(milliseconds: 2400),
    super.key,
  });

  final Concept concept;
  final VoidCallback onDone;
  final Duration autoAdvance;

  @override
  State<NewConceptCelebration> createState() => _NewConceptCelebrationState();
}

class _NewConceptCelebrationState extends State<NewConceptCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoAdvance, _finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = categoryColorFor(widget.concept);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: FadeTransition(
        opacity: _controller,
        child: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutBack,
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: color, width: 3),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: color,
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'New topic!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.concept.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to start',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
