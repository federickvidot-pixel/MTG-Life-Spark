import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/app_router.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/spacing_tokens.dart';

/// Navigation bar with Home button.
/// [showQuitConfirmation] — when true, shows "Are you sure you want to quit?" before navigating.
/// Only use true when the user is in an active game.
class HomeNavBar extends StatelessWidget {
  const HomeNavBar({
    super.key,
    this.showQuitConfirmation = false,
  });

  final bool showQuitConfirmation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundSecondary,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => showQuitConfirmation
                ? _showQuitDialog(context)
                : _goHome(context),
            icon: const Icon(Icons.home_rounded, color: ColorTokens.primaryAccent),
            label: const Text(
              'Home',
              style: TextStyle(
                color: ColorTokens.primaryAccent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _showQuitDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surface,
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.radiusXl),
        title: const Text(
          'Are you sure you want to quit?',
          style: TextStyle(color: ColorTokens.textPrimary),
        ),
        content: const Text(
          'You will return to the home page.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: ColorTokens.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryAccent,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    ).then((quit) {
      if (quit == true && context.mounted) {
        context.go(AppRoutes.home);
      }
    });
  }

  static void _goHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  /// Call from anywhere (e.g. game screen) to show quit confirmation.
  static void promptQuitAndGoHome(BuildContext context) {
    _showQuitDialog(context);
  }
}
