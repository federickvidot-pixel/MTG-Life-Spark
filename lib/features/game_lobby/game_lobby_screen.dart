import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/utils/app_router.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/spacing_tokens.dart';

/// Game lobby access screen — Host and Join buttons, 50% each.
class GameLobbyScreen extends StatelessWidget {
  const GameLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(LayoutTokens.gr4),
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
              SizedBox(height: LayoutTokens.gr4),
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
    final colors = AppColorTokens.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.sizeOf(context).height < 600;
    final iconSize = isCompact ? 48.0 : 64.0;
    final padding = isCompact ? LayoutTokens.gr3 : LayoutTokens.gr5;
    final titleSize = isCompact ? 20.0 : 24.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.radiusXl,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: RadiusTokens.radiusXl,
            border: Border.all(
              color: colors.primaryAccent.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primaryAccent.withValues(alpha: 0.1),
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
                color: colors.primaryAccent,
                size: iconSize,
              ),
              SizedBox(height: LayoutTokens.gr4),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: LayoutTokens.gr1),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
