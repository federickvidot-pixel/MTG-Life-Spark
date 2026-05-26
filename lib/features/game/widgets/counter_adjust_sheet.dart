import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import 'game_modal_chrome.dart';
import 'game_ui_tokens.dart';

Future<void> showCounterAdjustSheet(
  BuildContext context, {
  required String title,
  required int current,
  required void Function(int delta) onChanged,
}) {
  return showGameBottomSheet<void>(
    context: context,
    builder: (_) => CounterAdjustSheet(
      title: title,
      current: current,
      onChanged: onChanged,
    ),
  );
}

class CounterAdjustSheet extends StatefulWidget {
  final String title;
  final int current;
  final void Function(int delta) onChanged;

  const CounterAdjustSheet({
    super.key,
    required this.title,
    required this.current,
    required this.onChanged,
  });

  @override
  State<CounterAdjustSheet> createState() => _CounterAdjustSheetState();
}

class _CounterAdjustSheetState extends State<CounterAdjustSheet> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current;
  }

  void _adjust(int delta) {
    final newVal = (_value + delta).clamp(0, 9999);
    if (newVal == _value) return;
    widget.onChanged(newVal - _value);
    setState(() => _value = newVal);
  }

  @override
  Widget build(BuildContext context) {
    return GameSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameSheetHeader(title: widget.title),
          SizedBox(height: LayoutTokens.gr3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjBtn(label: '−5', onTap: () => _adjust(-5)),
              const SizedBox(width: LayoutTokens.gr1),
              _AdjBtn(label: '−1', onTap: () => _adjust(-1)),
              const SizedBox(width: LayoutTokens.gr3),
              Text(
                '$_value',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: LayoutTokens.gr2 * 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: LayoutTokens.gr3),
              _AdjBtn(label: '+1', onTap: () => _adjust(1)),
              const SizedBox(width: LayoutTokens.gr1),
              _AdjBtn(label: '+5', onTap: () => _adjust(5)),
            ],
          ),
          SizedBox(height: LayoutTokens.gr3),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: GameUiTokens.sheetSecondaryButton,
            child: Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _AdjBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AdjBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: LayoutTokens.minTapTarget,
            height: LayoutTokens.minTapTarget,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
              color: AppTheme.surface,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
