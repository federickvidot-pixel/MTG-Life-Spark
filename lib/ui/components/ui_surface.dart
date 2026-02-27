import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
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
    final bgColor = color ??
        (glass
            ? ColorTokens.surface.withValues(alpha: 0.6)
            : ColorTokens.surface);
    final border = borderColor ?? ColorTokens.borderSubtle.withValues(alpha: 0.5);

    return Container(
      padding: padding ?? const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? RadiusTokens.radiusMd,
        border: Border.all(color: border),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
