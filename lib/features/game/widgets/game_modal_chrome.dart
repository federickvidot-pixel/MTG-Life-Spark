import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/font_tokens.dart';
import '../../../ui/tokens/layout_tokens.dart';
import '../../../ui/tokens/radius_tokens.dart';

/// Shared dialog and bottom-sheet chrome for in-game modals.
abstract final class GameModalChrome {
  static const double _compactBreakpoint = 360;

  static double horizontalInset(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _compactBreakpoint
          ? LayoutTokens.gr3
          : LayoutTokens.gr4;

  static TextStyle get dialogTitleStyle => const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: FontTokens.title,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get dialogBodyStyle => TextStyle(
        color: AppTheme.textSecondary.withValues(alpha: 0.9),
        fontSize: FontTokens.hudSm,
        height: 1.4,
      );

  static TextStyle get sheetTitleStyle => const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: FontTokens.title,
        fontWeight: FontWeight.w700,
      );

  static EdgeInsets sheetPadding(BuildContext context) {
    final h = horizontalInset(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(h, LayoutTokens.gr2, h, bottom + LayoutTokens.gr3);
  }
}

/// Rounded X for game [AlertDialog] title rows.
class GameDialogCloseButton extends StatelessWidget {
  const GameDialogCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: Material(
        color: AppTheme.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            Icons.close_rounded,
            size: 20,
            color: AppTheme.textSecondary.withValues(alpha: 0.9),
          ),
          tooltip: 'Close',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(
            minWidth: LayoutTokens.minTapTarget,
            minHeight: LayoutTokens.minTapTarget,
          ),
        ),
      ),
    );
  }
}

/// Title row: [title] or [titleWidget] + close button.
class GameDialogTitleRow extends StatelessWidget {
  const GameDialogTitleRow({
    super.key,
    this.title,
    this.titleWidget,
    required this.onClose,
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final Widget? titleWidget;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: titleWidget ??
              Text(title!, style: GameModalChrome.dialogTitleStyle),
        ),
        GameDialogCloseButton(onPressed: onClose),
      ],
    );
  }
}

/// Drag pill used at the top of game bottom sheets.
class GameSheetHandle extends StatelessWidget {
  const GameSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary.withValues(alpha: 0.22),
          borderRadius: RadiusTokens.radiusPill,
        ),
      ),
    );
  }
}

/// Standard sheet header: handle, title, optional subtitle.
class GameSheetHeader extends StatelessWidget {
  const GameSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showHandle = true,
  });

  final String title;
  final String? subtitle;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle) ...[
          const GameSheetHandle(),
          SizedBox(height: LayoutTokens.gr2),
        ],
        Text(title, style: GameModalChrome.sheetTitleStyle),
        if (subtitle != null) ...[
          SizedBox(height: LayoutTokens.gr1),
          Text(subtitle!, style: GameModalChrome.dialogBodyStyle),
        ],
      ],
    );
  }
}

/// Wraps sheet body with standard padding and optional scroll.
class GameSheetBody extends StatelessWidget {
  const GameSheetBody({
    super.key,
    required this.child,
    this.scrollable = false,
  });

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final pad = GameModalChrome.sheetPadding(context);
    final content = scrollable
        ? SingleChildScrollView(padding: pad, child: child)
        : Padding(padding: pad, child: child);
    return SafeArea(top: false, child: content);
  }
}

Future<T?> showGameBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppTheme.card,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: RadiusTokens.radiusSheetTop,
    ),
    builder: builder,
  );
}

/// Confirm dialog: title, body, single primary action; dismiss via X.
Future<bool?> showGameConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.card,
      title: GameDialogTitleRow(
        title: title,
        onClose: () => Navigator.pop(ctx, false),
      ),
      content: Text(message, style: GameModalChrome.dialogBodyStyle),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppTheme.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Two-action dialog: X to cancel, [secondaryLabel] + [primaryLabel].
Future<bool?> showGameChoiceDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required String primaryLabel,
  String? secondaryLabel,
  bool primaryDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.card,
      title: GameDialogTitleRow(
        title: title,
        onClose: () => Navigator.pop(ctx, false),
      ),
      content: content,
      actions: [
        if (secondaryLabel != null)
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              secondaryLabel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: primaryDestructive
              ? FilledButton.styleFrom(backgroundColor: AppTheme.danger)
              : null,
          child: Text(primaryLabel),
        ),
      ],
    ),
  );
}
