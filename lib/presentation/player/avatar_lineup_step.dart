import 'package:flutter/material.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/avatar_thumb.dart';
import 'package:math_city/presentation/player/creation_chrome.dart';

/// Step 1 of creating a player: six random faces to pick from. Tapping
/// one is the whole action; the editor opens on that face next. [onBack]
/// leaves the flow without creating anyone.
class AvatarLineupStep extends StatelessWidget {
  const AvatarLineupStep({
    required this.faces,
    required this.onPick,
    required this.onMore,
    this.onBack,
    super.key,
  });

  final List<AdventurerConfig> faces;
  final ValueChanged<AdventurerConfig> onPick;
  final VoidCallback onMore;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StepScaffold(
      step: 1,
      onBack: onBack,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const StepTitle(
              title: 'Pick a mayor',
              hint: Text('You can change anything next.'),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cell = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (i, face) in faces.indexed)
                        OptionCell(
                          size: cell,
                          selected: false,
                          semanticLabel: 'Mayor ${i + 1}',
                          onTap: () => onPick(face),
                          child: AvatarThumb(
                            config: face,
                            size: cell - 28,
                            background: theme.colorScheme.surfaceContainerLow,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RowButton(
                label: 'Show me more',
                icon: Icons.shuffle_rounded,
                onPressed: onMore,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
