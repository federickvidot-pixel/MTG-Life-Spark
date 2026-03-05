import 'package:flutter/material.dart';

import '../../debug_log.dart';
import '../theme/app_color_tokens.dart';
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

  Widget _buildCompactInlineRow(BuildContext context) {
    final fontSize = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 16.0;
    final subFontSize = MediaQuery.sizeOf(context).width < 360 ? 10.0 : 11.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          SizedBox(width: SpacingTokens.xxs),
        ],
        if (title != null)
          Text(
            title!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        if (title != null && subtitle != null) SizedBox(width: SpacingTokens.xxs),
        if (subtitle != null)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: subFontSize,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // #region agent log
    final useInlineSubtitle = compact && title != null && subtitle != null;
    if (useInlineSubtitle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            debugLog(
              location: 'bento_tile.dart:build',
              message: 'BentoTile compact layout constraints',
              data: {
                'maxWidth': box.constraints.maxWidth,
                'maxHeight': box.constraints.maxHeight,
                'size': '${box.size.width}x${box.size.height}',
                'subtitle': subtitle,
              },
              hypothesisId: 'H1',
            );
          }
        }
      });
    }
    // #endregion

    final colors = AppColorTokens.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (accentStrip)
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: colors.primaryAccent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.xl)),
            ),
          ),
        Padding(
          padding: EdgeInsets.all(compact ? SpacingTokens.xs : SpacingTokens.md),
          child: useInlineSubtitle
              ? _buildCompactInlineRow(context)
              : Column(
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
                                      fontSize: compact
                                          ? (MediaQuery.sizeOf(context).width < 360 ? 14 : 16)
                                          : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                          fontSize: compact
                              ? (MediaQuery.sizeOf(context).width < 360 ? 10 : 11)
                              : null,
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
            borderColor: accentStrip ? colors.primaryAccent.withValues(alpha: 0.3) : null,
            child: content,
          ),
        ),
      );
    }

    return UiSurface(
      borderRadius: RadiusTokens.radiusMd,
      borderColor: accentStrip ? colors.primaryAccent.withValues(alpha: 0.3) : null,
      child: content,
    );
  }
}
