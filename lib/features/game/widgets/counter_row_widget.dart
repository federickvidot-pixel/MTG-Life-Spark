import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../ui/tokens/layout_tokens.dart';

double _gr(num n) => (n * LayoutTokens.goldenRatio).roundToDouble();

/// A compact row of player-level counters: poison, energy, experience, rad.
/// Each chip shows an icon + count. Tapping opens a +/- sheet.
/// Includes a Proliferate button at the right edge.
class CounterRowWidget extends StatelessWidget {
  final int poison;
  final int energy;
  final int experience;
  final int rad;
  final bool isEliminated;
  final void Function(String field, int delta) onCounterChange;
  final VoidCallback onProliferate;

  const CounterRowWidget({
    super.key,
    required this.poison,
    required this.energy,
    required this.experience,
    required this.rad,
    required this.onCounterChange,
    required this.onProliferate,
    this.isEliminated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _gr(10), vertical: _gr(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CounterChip(
            iconWidget: GameIcon.poison(size: _gr(14), color: AppTheme.success),
            label: 'Poison',
            value: poison,
            accentColor: AppTheme.success,
            dangerAt: 8,
            deathAt: 10,
            isEliminated: isEliminated,
            onTap: () =>
                _showAdjust(context, 'Poison Counters', 'poison', poison),
          ),
          SizedBox(width: _gr(8)),
          _CounterChip(
            iconWidget: GameIcon.energy(size: _gr(14), color: AppTheme.accentGold),
            label: 'Energy',
            value: energy,
            accentColor: AppTheme.accentGold,
            isEliminated: isEliminated,
            onTap: () =>
                _showAdjust(context, 'Energy Counters', 'energy', energy),
          ),
          SizedBox(width: _gr(8)),
          _CounterChip(
            iconWidget: GameIcon.experience(size: _gr(14), color: const Color(0xFF9C7AFF)),
            label: 'Exp',
            value: experience,
            accentColor: const Color(0xFF9C7AFF),
            isEliminated: isEliminated,
            onTap: () => _showAdjust(
                context, 'Experience Counters', 'experience', experience),
          ),
          SizedBox(width: _gr(8)),
          _CounterChip(
            iconWidget: GameIcon.radiation(size: _gr(14), color: const Color(0xFF66FF66)),
            label: 'Rad',
            value: rad,
            accentColor: const Color(0xFF66FF66),
            isEliminated: isEliminated,
            onTap: () =>
                _showAdjust(context, 'Rad Counters', 'rad', rad),
          ),
          SizedBox(width: _gr(9)),
          // Proliferate button
          Tooltip(
            message: 'Proliferate',
            child: GestureDetector(
              onTap: isEliminated ? null : onProliferate,
              child: Container(
                width: _gr(30),
                height: _gr(30),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(_gr(8)),
                  border: Border.all(
                    color: isEliminated
                        ? AppTheme.textSecondary.withValues(alpha: 0.3)
                        : AppTheme.accent.withValues(alpha: 0.6),
                  ),
                ),
                child: Center(
                  child: Text(
                    '+1',
                    style: TextStyle(
                      fontSize: _gr(9),
                      fontWeight: FontWeight.bold,
                      color: isEliminated
                          ? AppTheme.textSecondary
                          : AppTheme.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjust(
    BuildContext context,
    String title,
    String field,
    int current,
  ) {
    if (isEliminated) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CounterAdjustSheet(
        title: title,
        current: current,
        onChanged: (delta) => onCounterChange(field, delta),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final Widget? iconWidget;
  final String label;
  final int value;
  final Color accentColor;
  final int? dangerAt;
  final int? deathAt;
  final bool isEliminated;
  final VoidCallback onTap;

  const _CounterChip({
    this.iconWidget,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onTap,
    this.dangerAt,
    this.deathAt,
    this.isEliminated = false,
  });

  Color get _chipColor {
    if (isEliminated) return AppTheme.textSecondary;
    if (deathAt != null && value >= deathAt!) return AppTheme.textSecondary;
    if (dangerAt != null && value >= dangerAt!) return AppTheme.textSecondary;
    return value > 0 ? accentColor : AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: _gr(9), vertical: _gr(6)),
        decoration: BoxDecoration(
          color: _chipColor.withValues(alpha: value > 0 ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(_gr(8)),
          border: Border.all(
            color: _chipColor.withValues(alpha: value > 0 ? 0.6 : 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) iconWidget!,
            const SizedBox(height: 2),
            Text(
              '$value',
              style: TextStyle(
                color: _chipColor,
                fontSize: _gr(10),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterAdjustSheet extends StatefulWidget {
  final String title;
  final int current;
  final void Function(int delta) onChanged;

  const _CounterAdjustSheet({
    required this.title,
    required this.current,
    required this.onChanged,
  });

  @override
  State<_CounterAdjustSheet> createState() => _CounterAdjustSheetState();
}

class _CounterAdjustSheetState extends State<_CounterAdjustSheet> {
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjBtn(label: '−5', onTap: () => _adjust(-5)),
              const SizedBox(width: 8),
              _AdjBtn(label: '−1', onTap: () => _adjust(-1)),
              const SizedBox(width: 16),
              Text(
                '$_value',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _AdjBtn(label: '+1', onTap: () => _adjust(1)),
              const SizedBox(width: 8),
              _AdjBtn(label: '+5', onTap: () => _adjust(5)),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done',
                style: TextStyle(color: AppTheme.textSecondary)),
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
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
