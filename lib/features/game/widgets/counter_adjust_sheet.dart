import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';
import '../../../ui/tokens/spacing_tokens.dart';

Future<void> showCounterAdjustSheet(
  BuildContext context, {
  required String title,
  required int current,
  required void Function(int delta) onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: RadiusTokens.radiusSheetTop,
    ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.md,
        SpacingTokens.lg,
        SpacingTokens.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: LayoutTokens.gr3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
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
          const SizedBox(height: SpacingTokens.lg),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Done',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
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
    return Material(
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
