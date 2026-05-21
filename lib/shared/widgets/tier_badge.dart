import 'package:flutter/material.dart';
import '../../ui/tokens/font_tokens.dart';

import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../utils/wizard_rank_titles.dart';

class TierBadge extends StatelessWidget {
  final String tier;
  final int level;

  const TierBadge({super.key, required this.tier, required this.level});

  Color get _color {
    switch (tier) {
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return ColorTokens.accentGold;
      case 'Platinum':
        return const Color(0xFFE5E4E2);
      case 'Diamond':
        return const Color(0xFFB9F2FF);
      default:
        return const Color(0xFFCD7F32); // Bronze
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: RadiusTokens.radiusSm,
        border: Border.all(color: _color, width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          wizardRankTitle(level),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _color,
            fontSize: FontTokens.hudXs,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
