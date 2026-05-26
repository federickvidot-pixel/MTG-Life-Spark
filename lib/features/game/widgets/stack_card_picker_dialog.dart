import 'dart:async';

import 'package:flutter/material.dart';
import '../../../ui/tokens/font_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/scryfall_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/mana/mana_symbol_assets.dart';
import '../../../ui/tokens/layout_tokens.dart';
import 'game_modal_chrome.dart';

/// Pick a card from Scryfall so the stack entry stores the official name and rules.
Future<ScryfallCard?> showStackCardPickerDialog(
  BuildContext context, {
  required String title,
  String? initialQuery,
}) {
  return showDialog<ScryfallCard>(
    context: context,
    builder: (ctx) => _StackCardPickerDialog(
      title: title,
      initialQuery: initialQuery,
    ),
  );
}

class _StackCardPickerDialog extends ConsumerStatefulWidget {
  final String title;
  final String? initialQuery;

  const _StackCardPickerDialog({
    required this.title,
    this.initialQuery,
  });

  @override
  ConsumerState<_StackCardPickerDialog> createState() =>
      _StackCardPickerDialogState();
}

class _StackCardPickerDialogState extends ConsumerState<_StackCardPickerDialog> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  List<ScryfallCard> _results = [];
  ScryfallCard? _selected;
  bool _loading = false;
  bool _confirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _search(widget.initialQuery!.trim());
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _selected = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
    });
    try {
      final service = ref.read(scryfallServiceProvider);
      final results = await service.searchCards(query);
      if (!mounted) return;
      setState(() {
        _results = results.take(20).toList();
        _loading = false;
        if (results.isEmpty) {
          _error = 'No cards found. Try a different spelling.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = 'Could not reach Scryfall. Check your internet connection.';
      });
    }
  }

  void _select(ScryfallCard card) {
    setState(() {
      _selected = card;
      _searchController.text = card.name;
    });
  }

  Future<void> _confirm() async {
    final service = ref.read(scryfallServiceProvider);
    ScryfallCard? card = _selected;

    if (card == null) {
      setState(() {
        _confirming = true;
        _error = null;
      });
      card = await service.fetchCardFuzzy(_searchController.text);
      if (!mounted) return;
      setState(() => _confirming = false);
      if (card == null) {
        setState(() {
          _error =
              'Pick a card from the list, or type a name Scryfall recognizes.';
        });
        return;
      }
    } else {
      final exact = await service.fetchCardByName(card.name);
      if (!mounted) return;
      if (exact != null) card = exact;
    }

    Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = !_confirming &&
        (_selected != null || _searchController.text.trim().isNotEmpty);

    return AlertDialog(
      backgroundColor: AppTheme.card,
      title: GameDialogTitleRow(
        title: widget.title,
        onClose: () => Navigator.pop(context),
      ),
      content: SizedBox(
        width: 360,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Search Scryfall so we store the correct card name and rules text.',
              style: GameModalChrome.dialogBodyStyle,
            ),
            SizedBox(height: LayoutTokens.gr2),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Card name',
                hintText: 'e.g. Lightning Bolt',
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _selected = null;
                            _error = null;
                          });
                        },
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (v) {
                setState(() => _selected = null);
                _onSearchChanged(v);
              },
            ),
            if (_error != null) ...[
              SizedBox(height: LayoutTokens.gr1),
              Text(
                _error!,
                style: TextStyle(fontSize: 12, color: AppTheme.danger),
              ),
            ],
            SizedBox(height: LayoutTokens.gr2),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: canAdd ? _confirm : null,
          child: _confirming
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textPrimary,
                  ),
                )
              : Text('Add'),
        ),
      ],
    );
  }

  Widget? _cardSubtitle(ScryfallCard card) {
    final type = card.typeLine?.trim();
    final rules = card.oracleText?.trim();
    if ((type == null || type.isEmpty) && (rules == null || rules.isEmpty)) {
      return null;
    }
    final lines = <String>[];
    if (type != null && type.isNotEmpty) lines.add(type);
    if (rules != null && rules.isNotEmpty) lines.add(rules);
    return Text(
      lines.join('\n'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: FontTokens.hudXs,
        color: AppTheme.textSecondary.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Type to search cards',
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            fontSize: FontTokens.hudSm,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => Divider(height: 1),
      itemBuilder: (context, index) {
        final card = _results[index];
        final isSelected = _selected?.name == card.name;
        return ListTile(
          selected: isSelected,
          title: Text(
            card.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: _cardSubtitle(card),
          trailing: card.manaCost != null && card.manaCost!.isNotEmpty
              ? Text(
                  manaCostPlainText(card.manaCost!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                )
              : null,
          onTap: () => _select(card),
        );
      },
    );
  }
}
