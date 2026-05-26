import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/opacity_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import 'game_main_tab_bar.dart';

/// Commander + Play/Stack/History in one header card.
class GameHudHeader extends StatelessWidget {
  const GameHudHeader({
    super.key,
    required this.commander,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.accentColor,
    required this.tightVertical,
  });

  final Widget commander;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final Color accentColor;
  final bool tightVertical;

  static final Color _dividerColor =
      AppTheme.textSecondary.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: RadiusTokens.radiusMd,
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: OpacityTokens.faint),
            blurRadius: LayoutTokens.gr2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: RadiusTokens.radiusMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(
                tightVertical ? LayoutTokens.gr1 : LayoutTokens.gr2,
              ),
              child: commander,
            ),
            Divider(height: 1, thickness: 1, color: _dividerColor),
            GameMainTabBarStrip(
              selectedIndex: selectedTabIndex,
              accentColor: accentColor,
              onSelected: onTabSelected,
            ),
          ],
        ),
      ),
    );
  }
}
