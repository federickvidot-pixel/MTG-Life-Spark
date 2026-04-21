import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../ui/theme/app_color_tokens.dart';
import '../mana/mana_symbol_assets.dart';

/// Single bundled PNG from `assets/mana/**` at [height] logical pixels.
class _BundledManaPip extends StatelessWidget {
  const _BundledManaPip({
    required this.assetPath,
    required this.fallbackLabel,
    required this.height,
    required this.fallbackStyle,
  });

  final String assetPath;
  final String fallbackLabel;
  final double height;
  final TextStyle fallbackStyle;

  @override
  Widget build(BuildContext context) {
    final w = height * 1.15;
    final chip = AppColorTokens.of(context).surface.withValues(alpha: 0.45);
    return SizedBox(
      height: height,
      width: w,
      child: DecoratedBox(
        decoration: BoxDecoration(color: chip, shape: BoxShape.circle),
        child: Padding(
          padding: const EdgeInsets.all(1.5),
          child: Image.asset(
            assetPath,
            bundle: rootBundle,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            isAntiAlias: true,
            // Do not set cacheWidth/cacheHeight — on some targets it breaks PNG decode
            // and triggers errorBuilder (user sees `{W}` text instead of art).
            errorBuilder: (_, __, ___) => Center(
              child: Text(fallbackLabel, style: fallbackStyle),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a Scryfall mana cost as a row of bundled PNG symbols (`assets/mana/`).
class ManaCostPips extends StatelessWidget {
  const ManaCostPips({
    super.key,
    required this.manaCost,
    this.symbolHeight = 16,
    this.spacing = 2,
  });

  final String? manaCost;
  final double symbolHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final c = manaCost?.trim();
    if (c == null || c.isEmpty) {
      return Text(
        '—',
        style: TextStyle(
          color: AppColorTokens.of(context).textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final tokens = manaCostTokens(c);
    final h = symbolHeight;
    final muted = AppColorTokens.of(context).textMuted;
    final fallbackStyle = TextStyle(
      color: muted,
      fontSize: (h * 0.72).clamp(9.0, 13.0),
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (tokens.isEmpty) {
      return Text(
        manaCostPlainText(c),
        style: TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    Widget tokenWidget(ManaCostToken t) {
      final label = '{${t.inner}}';
      if (t.assetPath == null) {
        return SizedBox(
          height: h,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: fallbackStyle),
          ),
        );
      }
      return _BundledManaPip(
        assetPath: t.assetPath!,
        fallbackLabel: label,
        height: h,
        fallbackStyle: fallbackStyle,
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: tokens.map(tokenWidget).toList(),
    );
  }
}

/// Optional commander + partner mana rows for deck tiles.
class DeckManaCostRows extends StatelessWidget {
  const DeckManaCostRows({
    super.key,
    required this.commanderManaCost,
    required this.partnerManaCost,
    required this.hasPartner,
    this.compact = false,
  });

  final String? commanderManaCost;
  final String? partnerManaCost;
  final bool hasPartner;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 14.0 : 16.0;
    final c = commanderManaCost?.trim();
    final p = partnerManaCost?.trim();
    final hasC = c != null && c.isNotEmpty;
    final hasP = hasPartner && p != null && p.isNotEmpty;
    final children = <Widget>[];
    if (hasC) {
      children.add(ManaCostPips(manaCost: commanderManaCost, symbolHeight: h));
    }
    if (hasP) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: compact ? 4 : 6));
      }
      children.add(ManaCostPips(manaCost: partnerManaCost, symbolHeight: h));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
