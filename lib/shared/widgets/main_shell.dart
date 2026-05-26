import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/components/app_bottom_nav_bar.dart';

/// Shell scaffold with a floating dock-style bottom nav.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: AppBottomNavBar.shellDestinations,
      ),
    );
  }
}
