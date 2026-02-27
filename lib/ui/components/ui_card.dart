import 'package:flutter/material.dart';

import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'ui_surface.dart';

/// Card built on UiSurface with consistent padding and border.
class UiCard extends StatelessWidget {
  const UiCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = RadiusTokens.radiusMd,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = UiSurface(
      padding: padding ?? const EdgeInsets.all(SpacingTokens.md),
      borderRadius: borderRadius ?? RadiusTokens.radiusMd,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? RadiusTokens.radiusMd,
          child: content,
        ),
      );
    }

    return content;
  }
}
