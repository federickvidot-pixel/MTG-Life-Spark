import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/theme/app_color_tokens.dart';
import 'main_bottom_nav.dart';

/// Shell scaffold with persistent bottom navigation.
/// Body is the StatefulNavigationShell (branch content).
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: navigationShell,
      bottomNavigationBar: MainBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
      ),
    );
  }
}
