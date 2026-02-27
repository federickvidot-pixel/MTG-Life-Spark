import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/utils/app_router.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/spacing_tokens.dart';

/// Game lobby access screen — Host and Join buttons, 50% each.
class GameLobbyScreen extends StatelessWidget {
  const GameLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            children: [
              // Host button — 50% of available space
              Expanded(
                child: _BigActionButton(
                  label: 'Host a Game',
                  subtitle: 'Create a session — others join you',
                  icon: Icons.wifi_tethering_rounded,
                  onTap: () => context.push(AppRoutes.lobbyHost),
                ),
              ),
              const SizedBox(height: SpacingTokens.md),
              // Join button — 50% of available space
              Expanded(
                child: _BigActionButton(
                  label: 'Join a Game',
                  subtitle: 'Scan for a nearby host',
                  icon: Icons.bluetooth_searching_rounded,
                  onTap: () => context.push(AppRoutes.lobbyJoin),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.radiusXl,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SpacingTokens.xl),
          decoration: BoxDecoration(
            color: ColorTokens.surface,
            borderRadius: RadiusTokens.radiusXl,
            border: Border.all(
              color: ColorTokens.primaryAccent.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorTokens.primaryAccent.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: ColorTokens.primaryAccent,
                size: 64,
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
