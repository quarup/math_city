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
      title: 'Pick a mayor',
      hint: const Text('You can change anything next.'),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, c) {
            // As many faces across as gives the biggest cells that still
            // all fit: two columns upright, three or six on a side.
            final (cols, cell) = fitSquareGrid(
              count: faces.length,
              width: c.maxWidth,
              height: c.maxHeight - 16,
              gap: 12,
              maxCell: 220,
            );
            return Center(
              child: SizedBox(
                width: cols * cell + (cols - 1) * 12,
                child: Wrap(
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
                          size: cell - 24,
                          background: theme.colorScheme.surfaceContainerLow,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        RowButton(
          label: 'Show me more',
          icon: Icons.shuffle_rounded,
          onPressed: onMore,
        ),
      ],
    );
  }
}
