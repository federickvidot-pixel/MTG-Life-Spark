import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';

/// Base container: background fill, border, subtle shadow.
/// Optional glass mode (very light opacity).
class UiSurface extends StatelessWidget {
  const UiSurface({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.borderRadius = RadiusTokens.radiusMd,
    this.elevation = ElevationTokens.none,
    this.glass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final bgColor = color ??
        (glass
            ? colors.surface.withValues(alpha: 0.72)
            : colors.surface);
    final border = borderColor ?? colors.borderSubtle.withValues(alpha: 0.65);

    return Container(
      padding: padding ?? const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? RadiusTokens.radiusMd,
        border: Border.all(color: border, width: 1),
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: elevation * 4,
              offset: Offset(0, elevation),
            ),
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.06),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
