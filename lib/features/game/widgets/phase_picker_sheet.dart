import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/game/game_phase.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import 'game_modal_chrome.dart';
import 'game_ui_tokens.dart';

/// Scrollable phase list for host / active player to jump to any step.
Future<void> showPhasePickerSheet(
  BuildContext context, {
  required GamePhase currentPhase,
  required Color accentColor,
  required ValueChanged<GamePhase> onSelected,
}) {
  return showGameBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => PhasePickerSheet(
      currentPhase: currentPhase,
      accentColor: accentColor,
      onSelected: (phase) {
        Navigator.pop(sheetCtx);
        onSelected(phase);
      },
    ),
  );
}

class PhasePickerSheet extends StatefulWidget {
  final GamePhase currentPhase;
  final Color accentColor;
  final ValueChanged<GamePhase> onSelected;

  const PhasePickerSheet({
    super.key,
    required this.currentPhase,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  State<PhasePickerSheet> createState() => _PhasePickerSheetState();
}

class _PhasePickerSheetState extends State<PhasePickerSheet> {
  late FixedExtentScrollController _wheelCtrl;
  late int _highlightIndex;

  @override
  void initState() {
    super.initState();
    _highlightIndex = widget.currentPhase.index;
    _wheelCtrl = FixedExtentScrollController(initialItem: _highlightIndex);
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    super.dispose();
  }

  void _select(GamePhase phase) {
    HapticFeedback.selectionClick();
    widget.onSelected(phase);
  }

  @override
  Widget build(BuildContext context) {
    const itemExtent = 48.0;

    return GameSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameSheetHeader(
            title: 'Select phase',
            subtitle:
                'Scroll and tap a phase, or use Set phase for the highlighted step.',
          ),
          SizedBox(height: LayoutTokens.gr2),
          SizedBox(
            height: itemExtent * 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.35),
                borderRadius: RadiusTokens.radiusSm,
                border: Border.all(
                  color: AppTheme.surface.withValues(alpha: 0.6),
                ),
              ),
              child: ClipRRect(
                borderRadius: RadiusTokens.radiusSm,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification && _wheelCtrl.hasClients) {
                      setState(() => _highlightIndex = _wheelCtrl.selectedItem);
                    }
                    return false;
                  },
                  child: ListWheelScrollView.useDelegate(
                    controller: _wheelCtrl,
                    itemExtent: itemExtent,
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.003,
                    diameterRatio: 1.4,
                    useMagnifier: true,
                    magnification: 1.12,
                    overAndUnderCenterOpacity: 0.45,
                    onSelectedItemChanged: (i) {
                      setState(() => _highlightIndex = i);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: GamePhase.values.length,
                      builder: (context, index) {
                        final phase = GamePhase.values[index];
                        final centered = index == _highlightIndex;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _select(phase),
                            child: Center(
                              child: Text(
                                phase.displayName,
                                style: TextStyle(
                                  fontSize: centered ? 17 : FontTokens.hudSm,
                                  fontWeight:
                                      centered
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                  color:
                                      centered
                                          ? widget.accentColor
                                          : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: LayoutTokens.gr2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: GameUiTokens.sheetCancelButton,
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: LayoutTokens.gr2),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed:
                      () => _select(GamePhase.values[_highlightIndex]),
                  style: GameUiTokens.sheetPrimaryButton(widget.accentColor),
                  child: Text(
                    'Set ${GamePhase.values[_highlightIndex].displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
