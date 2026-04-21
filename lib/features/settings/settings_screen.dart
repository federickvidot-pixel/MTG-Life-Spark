import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_settings.dart';
import '../../core/persistence/providers.dart';
import '../../shared/theme/theme_provider.dart';
import '../../shared/utils/app_router.dart';
import '../../ui/components/ui_app_bar.dart';
import '../../ui/components/ui_dialog.dart';
import '../../ui/components/ui_surface.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/font_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(settingsRepositoryProvider).settings;
  }

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).update(_settings);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Scaffold(
      appBar: const UiAppBar(title: 'Settings'),
      backgroundColor: colors.backgroundPrimary,
      body: ListView(
        padding: EdgeInsets.all(LayoutTokens.gr4),
        children: [
          _SectionHeader('Gameplay'),
          _SettingTile(
            title: 'Default Format',
            subtitle: _settings.defaultFormat,
            onTap: () async {
              final picked = await _pickFormat(context);
              if (picked != null && mounted) {
                _settings.defaultFormat = picked;
                await _save();
              }
            },
          ),
          _SettingTile(
            title: 'Default Starting Life',
            subtitle: '${_settings.defaultStartingLife} life',
            onTap: () async {
              final picked = await _pickStartingLife(context);
              if (picked != null && mounted) {
                _settings.defaultStartingLife = picked;
                await _save();
              }
            },
          ),
          SizedBox(height: LayoutTokens.gr4),
          _SectionHeader('Misc'),
          _SwitchTile(
            title: 'Keep display awake',
            subtitle: 'Prevent screen from sleeping during a game',
            value: _settings.keepDisplayAwake,
            onChanged: (v) {
              _settings.keepDisplayAwake = v;
              _save();
            },
            icon: Icons.brightness_5_outlined,
          ),
          _SwitchTile(
            title: 'Hide navigation and status bars',
            subtitle: 'Fullscreen mode during gameplay',
            value: _settings.hideSystemBars,
            onChanged: (v) {
              _settings.hideSystemBars = v;
              _save();
            },
            icon: Icons.fullscreen,
          ),
          SizedBox(height: LayoutTokens.gr4),
          _SectionHeader('Appearance'),
          _SwitchTile(
            title: 'Dark theme',
            subtitle: 'Use dark mode. Light mode when off. In-game Day/Night also controls this.',
            value: ref.watch(themePreferenceProvider),
            onChanged: (v) {
              ref.read(themePreferenceProvider.notifier).setUseDarkTheme(v);
            },
            icon: Icons.dark_mode_outlined,
          ),
          SizedBox(height: LayoutTokens.gr4),
          _SectionHeader('Feel'),
          _SwitchTile(
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on life changes and rank ups',
            value: _settings.hapticEnabled,
            onChanged: (v) {
              _settings.hapticEnabled = v;
              _save();
            },
          ),
          _SwitchTile(
            title: 'Shake to Undo',
            subtitle: 'Shake phone to undo last life change',
            value: _settings.shakeToUndoEnabled,
            onChanged: (v) {
              _settings.shakeToUndoEnabled = v;
              _save();
            },
          ),
          SizedBox(height: LayoutTokens.gr4),
          _SectionHeader('Data'),
          _SwitchTile(
            title: 'Cache Commander Images',
            subtitle: 'Store Scryfall images locally for offline use',
            value: _settings.scryfallCacheEnabled,
            onChanged: (v) {
              _settings.scryfallCacheEnabled = v;
              _save();
            },
          ),
          _SettingTile(
            title: 'Clear Image Cache',
            subtitle: 'Free up storage from cached card images',
            onTap: _clearCache,
            isDestructive: true,
          ),
          SizedBox(height: LayoutTokens.gr4),
          _SectionHeader('Help'),
          _SettingTile(
            title: 'Feedback',
            subtitle: 'Send us your thoughts and suggestions',
            onTap: () => context.push(AppRoutes.feedback),
          ),
          _SettingTile(
            title: 'View Tutorial Again',
            subtitle: 'Re-launch the onboarding walkthrough',
            onTap: () {
              _settings.onboardingCompleted = false;
              _save().then((_) {
                if (context.mounted) context.push(AppRoutes.onboarding);
              });
            },
          ),
          SizedBox(height: LayoutTokens.gr5),
        ],
      ),
    );
  }

  Future<String?> _pickFormat(BuildContext context) {
    return UiDialog.show<String>(
      context,
      title: 'Default Format',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Commander', 'Standard'].map((f) {
          return ListTile(
            title: Text(f),
            onTap: () => Navigator.pop(context, f),
          );
        }).toList(),
      ),
    );
  }

  Future<int?> _pickStartingLife(BuildContext context) {
    return UiDialog.show<int>(
      context,
      title: 'Default Starting Life',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [20, 30, 40, 50].map((l) {
          return ListTile(
            title: Text('$l life'),
            onTap: () => Navigator.pop(context, l),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _clearCache() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image cache cleared.')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: LayoutTokens.gr4,
        bottom: LayoutTokens.gr2,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.primaryAccent,
          fontSize: FontTokens.sm,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
      child: UiSurface(
        padding: EdgeInsets.zero,
        borderRadius: RadiusTokens.radiusMd,
        child: SwitchListTile(
        secondary: icon != null
            ? Icon(icon, size: 22, color: colors.textSecondary)
            : null,
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
        value: value,
        onChanged: onChanged,
        activeTrackColor: colors.primaryAccent.withValues(alpha: 0.5),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primaryAccent;
          }
          return null;
        }),
        contentPadding: EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr3,
          vertical: LayoutTokens.gr1,
        ),
      ),
    ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final color = isDestructive ? ColorTokens.danger : colors.textSecondary;
    return Padding(
      padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
      child: UiSurface(
        padding: EdgeInsets.zero,
        borderRadius: RadiusTokens.radiusMd,
        child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDestructive ? ColorTokens.danger : null,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right_rounded, color: color),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: LayoutTokens.gr3,
          vertical: LayoutTokens.gr1,
        ),
      ),
    ),
    );
  }
}
