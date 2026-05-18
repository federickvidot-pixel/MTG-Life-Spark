import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/app_router.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/font_tokens.dart';
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => showQuitConfirmation
                  ? _showQuitDialog(context)
                  : _goHome(context),
              icon: Icon(Icons.home_rounded, color: scheme.primary),
              label: Text(
                'Home',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: FontTokens.bodyLg,
                ),
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
      builder: (ctx) {
        final colors = AppColorTokens.of(ctx);
        return AlertDialog(
          title: Text(
            'Are you sure you want to quit?',
            style: TextStyle(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'You will return to the home page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: SpacingTokens.lg),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes'),
              ),
              const SizedBox(height: SpacingTokens.sm),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'No',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
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
