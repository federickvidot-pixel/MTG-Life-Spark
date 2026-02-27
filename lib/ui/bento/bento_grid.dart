import 'package:flutter/material.dart';

import '../tokens/spacing_tokens.dart';
import 'bento_tile.dart';

/// Responsive Bento grid layout.
/// Mobile: 1 col, Tablet: 2 cols, Desktop/Web: 3-4 cols.
class BentoGrid extends StatelessWidget {
  const BentoGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.mainAxisSpacing = SpacingTokens.sm,
    this.crossAxisSpacing = SpacingTokens.sm,
    this.padding,
    this.tileAspectRatio,
  });

  final List<BentoTile> children;
  final int? crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;
  /// Optional aspect ratio (width/height) for tiles. E.g. LayoutTokens.goldenRatioInverse for portrait golden.
  final double? tileAspectRatio;

  int _columnCount(BuildContext context) {
    if (crossAxisCount != null) return crossAxisCount!;
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    if (width >= 400) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columnCount(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pad = padding ?? const EdgeInsets.all(SpacingTokens.md);
        final availableWidth = maxWidth - pad.horizontal;
        return SingleChildScrollView(
          padding: pad,
          child: SizedBox(
            width: availableWidth,
            child: _BentoGridDelegate(
              crossAxisCount: columns,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              tileAspectRatio: tileAspectRatio,
              availableWidth: availableWidth,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _BentoGridDelegate extends StatelessWidget {
  const _BentoGridDelegate({
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    this.tileAspectRatio,
    required this.availableWidth,
    required this.children,
  });

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double? tileAspectRatio;
  final double availableWidth;
  final List<BentoTile> children;

  @override
  Widget build(BuildContext context) {
    final tileWidth = (availableWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;

    final rows = <List<BentoTile>>[];
    var currentRow = <BentoTile>[];
    var currentRowSpan = 0;

    for (final tile in children) {
      final span = tile.columnSpan;
      if (currentRowSpan + span > crossAxisCount && currentRow.isNotEmpty) {
        rows.add(List.from(currentRow));
        currentRow = [];
        currentRowSpan = 0;
      }
      currentRow.add(tile);
      currentRowSpan += span;
      if (currentRowSpan >= crossAxisCount) {
        rows.add(List.from(currentRow));
        currentRow = [];
        currentRowSpan = 0;
      }
    }
    if (currentRow.isNotEmpty) rows.add(currentRow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.asMap().entries.map((entry) {
        final row = entry.value;
        final isLast = entry.key == rows.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : mainAxisSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: row.asMap().entries.map((entry) {
              final tile = entry.value;
              final isLastInRow = entry.key == row.length - 1;
              final w = tileWidth * tile.columnSpan + (tile.columnSpan - 1) * crossAxisSpacing;
              final child = tileAspectRatio != null
                  ? AspectRatio(
                      aspectRatio: tileAspectRatio!,
                      child: tile,
                    )
                  : tile;
              return Padding(
                padding: EdgeInsets.only(right: isLastInRow ? 0 : crossAxisSpacing),
                child: SizedBox(
                  width: w,
                  child: child,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
