import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/providers.dart';
import '../../shared/utils/achievement_definitions.dart';
import '../../ui/bento/bento_grid.dart';
import '../../ui/bento/bento_tile.dart';
import '../../ui/components/ui_app_bar.dart';
import '../../ui/components/ui_surface.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/spacing_tokens.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedIds = ref.watch(achievementRepositoryProvider).getUnlockedIds();
    final all = AchievementDefinitions.all;
    final unlocked = all.where((a) => unlockedIds.contains(a.id)).toList();
    final locked = all.where((a) => !unlockedIds.contains(a.id)).toList();

    return Scaffold(
      appBar: const UiAppBar(title: 'Achievements'),
      backgroundColor: ColorTokens.backgroundPrimary,
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        children: [
          UiSurface(
            padding: const EdgeInsets.all(SpacingTokens.md),
            borderRadius: RadiusTokens.radiusMd,
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${unlocked.length} / ${all.length} Unlocked',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      ClipRRect(
                        borderRadius: RadiusTokens.radiusSm,
                        child: LinearProgressIndicator(
                          value: all.isEmpty ? 0 : unlocked.length / all.length,
                          minHeight: 6,
                          backgroundColor: ColorTokens.backgroundPrimary,
                          valueColor: const AlwaysStoppedAnimation<Color>(ColorTokens.accentGold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (unlocked.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Unlocked',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            BentoGrid(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              children: unlocked
                  .map((a) => BentoTile(
                        title: a.title,
                        subtitle: a.description,
                        icon: Text(
                          a.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        accentStrip: true,
                        columnSpan: 1,
                      ))
                  .toList(),
            ),
          ],
          if (locked.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Locked',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            BentoGrid(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              children: locked
                  .map((a) => BentoTile(
                        title: a.title,
                        subtitle: '???',
                        icon: Text(
                          a.icon,
                          style: TextStyle(
                            fontSize: 24,
                            color: ColorTokens.textMuted,
                          ),
                        ),
                        columnSpan: 1,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: SpacingTokens.xl),
        ],
      ),
    );
  }
}
