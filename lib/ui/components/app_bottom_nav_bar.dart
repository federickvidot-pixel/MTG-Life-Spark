import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color_tokens.dart';
import '../tokens/layout_tokens.dart';
import '../tokens/motion_tokens.dart';
import '../tokens/radius_tokens.dart';

/// Shell tab descriptor for [AppBottomNavBar].
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating dock-style bottom navigation with a sliding accent pill.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> destinations;

  static const shellDestinations = [
    AppNavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppNavDestination(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      label: 'Lobby',
    ),
    AppNavDestination(
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers_rounded,
      label: 'Decks',
    ),
    AppNavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.surfaceElevated.withValues(alpha: 0.92),
                  colors.backgroundPrimary.withValues(alpha: 0.98),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: colors.primaryAccent.withValues(alpha: 0.42),
                  width: 1.2,
                ),
                left: BorderSide(
                  color: colors.borderSubtle.withValues(alpha: 0.35),
                ),
                right: BorderSide(
                  color: colors.borderSubtle.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: LayoutTokens.bottomNavHeight - 8,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        constraints.maxWidth / destinations.length;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedPositioned(
                          duration: MotionTokens.standard,
                          curve: MotionTokens.easeOut,
                          left: selectedIndex * itemWidth + itemWidth * 0.1,
                          width: itemWidth * 0.8,
                          top: 6,
                          bottom: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: RadiusTokens.radiusPill,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.primaryAccent.withValues(alpha: 0.28),
                                  colors.primaryAccent.withValues(alpha: 0.12),
                                ],
                              ),
                              border: Border.all(
                                color:
                                    colors.primaryAccent.withValues(alpha: 0.38),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primaryAccent
                                      .withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(
                                child: _DockNavItem(
                                  destination: destinations[i],
                                  selected: selectedIndex == i,
                                  onTap: () {
                                    if (i == selectedIndex) return;
                                    HapticFeedback.selectionClick();
                                    onDestinationSelected(i);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockNavItem extends StatelessWidget {
  const _DockNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final accent = colors.primaryAccent;
    final inactive = colors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.12),
          highlightColor: accent.withValues(alpha: 0.06),
          child: AnimatedScale(
            scale: selected ? 1.0 : 0.96,
            duration: MotionTokens.standard,
            curve: MotionTokens.easeOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: MotionTokens.fast,
                  switchInCurve: MotionTokens.enter,
                  switchOutCurve: MotionTokens.exit,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: MotionTokens.easeOut,
                        ),
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    size: selected ? 26 : 24,
                    color: selected ? accent : inactive,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: MotionTokens.standard,
                  curve: MotionTokens.easeOut,
                  style: TextStyle(
                    fontSize: selected ? 12 : 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: selected ? 0.35 : 0.2,
                    color: selected ? accent : inactive,
                    height: 1.1,
                  ),
                  child: Text(destination.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
