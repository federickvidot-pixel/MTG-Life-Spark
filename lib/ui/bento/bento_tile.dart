import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../components/ui_surface.dart';

/// Bento tile: rounded, optional accent strip, supports title/subtitle/icon/trailing/content.
/// Grid span: 1x1, 2x1, 2x2 via columnSpan and rowSpan.
class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.child,
    this.columnSpan = 1,
    this.rowSpan = 1,
    this.accentStrip = false,
    this.compact = false,
    this.onTap,
  });

  final String? title;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final Widget? child;
  final int columnSpan;
  final int rowSpan;
  final bool accentStrip;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (accentStrip)
          Container(
            height: 2,
            decoration: const BoxDecoration(
              color: ColorTokens.primaryAccent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.xl)),
            ),
          ),
        Padding(
          padding: EdgeInsets.all(compact ? SpacingTokens.xs : SpacingTokens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null || icon != null || trailing != null)
                Row(
                  children: [
                    if (icon != null) ...[
                      icon!,
                      SizedBox(width: compact ? SpacingTokens.xxs : SpacingTokens.sm),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 16 : null,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
              if (subtitle != null) ...[
                SizedBox(height: compact ? 2 : SpacingTokens.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 11 : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (child != null) ...[
                if (title != null || subtitle != null) const SizedBox(height: SpacingTokens.sm),
                child!,
              ],
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: RadiusTokens.radiusMd,
          child: UiSurface(
            borderRadius: RadiusTokens.radiusMd,
            borderColor: accentStrip ? ColorTokens.primaryAccent.withValues(alpha: 0.3) : null,
            child: content,
          ),
        ),
      );
    }

    return UiSurface(
      borderRadius: RadiusTokens.radiusMd,
      borderColor: accentStrip ? ColorTokens.primaryAccent.withValues(alpha: 0.3) : null,
      child: content,
    );
  }
}
