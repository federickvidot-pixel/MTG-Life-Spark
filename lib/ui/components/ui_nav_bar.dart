import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../tokens/font_tokens.dart';
import '../tokens/radius_tokens.dart';

/// Discord-like dark bar with animated active state, rounded pill highlights.
class UiNavBar extends StatelessWidget {
  const UiNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<UiNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isSelected = currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primaryAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: RadiusTokens.radiusPill,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: isSelected
                          ? colors.primaryAccent
                          : colors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: FontTokens.caption,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colors.primaryAccent
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class UiNavBarItem {
  const UiNavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
