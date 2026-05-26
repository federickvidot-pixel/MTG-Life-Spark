import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';

/// Play · Stack · History row — use inside [GameHudHeader].
class GameMainTabBarStrip extends StatelessWidget {
  const GameMainTabBarStrip({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor = AppTheme.accent,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  static const _segments = <(int, String, IconData)>[
    (0, 'Play', Icons.sports_esports_rounded),
    (1, 'Stack', Icons.layers_rounded),
    (2, 'History', Icons.history_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final dividerColor = AppTheme.textSecondary.withValues(alpha: 0.12);

    return SizedBox(
      height: LayoutTokens.minTapTarget,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _segments.length; i++) ...[
            if (i > 0)
              VerticalDivider(width: 1, thickness: 1, color: dividerColor),
            Expanded(
              child: _GameMainTab(
                label: _segments[i].$2,
                icon: _segments[i].$3,
                selected: selectedIndex == _segments[i].$1,
                accentColor: accentColor,
                onTap: () => onSelected(_segments[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameMainTab extends StatelessWidget {
  const _GameMainTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg =
        selected
            ? accentColor
            : AppTheme.textSecondary.withValues(alpha: 0.88);
    final bg =
        selected
            ? accentColor.withValues(alpha: 0.16)
            : Colors.transparent;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: LayoutTokens.gr1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: LayoutTokens.gr0),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: FontTokens.hudSm,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: fg,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
