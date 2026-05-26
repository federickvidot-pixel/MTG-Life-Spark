import 'package:flutter/material.dart';
import '../../../ui/tokens/font_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../ui/tokens/layout_tokens.dart';
import 'game_modal_chrome.dart';

const _kStackArticleUrl =
    'https://magic.wizards.com/en/news/feature/stack-and-its-tricks-2017-11-30';

/// Beginner-oriented explanation of the stack (shown from the Stack tab).
class StackHelpSheet extends StatelessWidget {
  const StackHelpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showGameBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const StackHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameSheetBody(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GameSheetHeader(title: 'How the stack works'),
          SizedBox(height: LayoutTokens.gr3),
          const _Bullet(
            'When someone casts a spell or uses an ability, it goes on the **stack** — a waiting line before it happens.',
          ),
          const _Bullet(
            'The **last thing added resolves first** (like a stack of plates). That is why the top entry says **Resolves next**.',
          ),
          const _Bullet(
            'When you add a spell, **search Scryfall** and pick the card from the list so we store the correct name and rules text.',
          ),
          const _Bullet(
            'To answer something, tap **Respond** or use **In response to…** — your spell goes on top and resolves before the one under it.',
          ),
          const _Bullet(
            'When an effect finishes, tap **Resolve** — the card stays on the stack and turns green. To answer it, tap **Respond**. If a counterspell worked, **Mark countered** (use the Countered filter to view). If a spell lost its target, tap **Fizzle** — it stays greyed; tap **Fizzled** again to undo.',
          ),
          const _Bullet(
            'At the table you still say “pass” out loud for priority; this screen helps everyone remember **what** is waiting and **in what order**.',
          ),
          SizedBox(height: LayoutTokens.gr3),
          Text(
            'Example: You cast a pump spell on your creature. Your opponent casts Lightning Bolt in response. Bolt resolves first, then your pump spell (if its target is still legal).',
            style: TextStyle(
              fontSize: FontTokens.hudSm,
              color: AppTheme.textSecondary.withValues(alpha: 0.95),
              height: 1.4,
            ),
          ),
          SizedBox(height: LayoutTokens.gr4),
          FilledButton.icon(
            onPressed: () => _openArticle(context),
            icon: Icon(Icons.open_in_new_rounded, size: 18),
            label: Text('Read more on Magic.com'),
          ),
        ],
      ),
    );
  }

  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.parse(_kStackArticleUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6, right: LayoutTokens.gr2),
            child: Icon(
              Icons.circle,
              size: 6,
              color: AppTheme.accent,
            ),
          ),
          Expanded(
            child: Text(
              text.replaceAll('**', ''),
              style: TextStyle(
                fontSize: FontTokens.hudSm,
                color: AppTheme.textPrimary.withValues(alpha: 0.92),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
