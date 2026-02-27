import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';

/// App bar using design tokens.
class UiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UiAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const [],
  });

  final String? title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorTokens.backgroundPrimary,
      foregroundColor: ColorTokens.textPrimary,
      elevation: 0,
      centerTitle: true,
      leading: leading,
      title: title != null && title!.isNotEmpty
          ? Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
            )
          : null,
      actions: actions,
    );
  }
}
