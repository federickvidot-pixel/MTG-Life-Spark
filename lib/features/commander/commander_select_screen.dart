import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/motion_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/game/lobby_state.dart';
import '../../core/game/scryfall_service.dart';
import '../../core/models/player_deck.dart';
import '../../core/persistence/providers.dart';
import '../../shared/mana/mana_symbol_assets.dart';
import '../../shared/theme/app_theme.dart';
import '../../ui/tokens/layout_tokens.dart';

String? _hiveManaCost(String? raw) {
  final n = normalizeScryfallManaCost(raw);
  return n.isEmpty ? null : n;
}

class CommanderSelectScreen extends ConsumerStatefulWidget {
  final String playerId;

  /// When set with [newDeckDisplayName] or [editDeckId], saves a deck instead of the lobby.
  final String? newDeckDisplayName;
  final String? editDeckId;

  const CommanderSelectScreen({
    super.key,
    required this.playerId,
    this.newDeckDisplayName,
    this.editDeckId,
  });

  bool get _deckMode =>
      (newDeckDisplayName != null && newDeckDisplayName!.isNotEmpty) ||
      (editDeckId != null && editDeckId!.isNotEmpty);

  @override
  ConsumerState<CommanderSelectScreen> createState() =>
      _CommanderSelectScreenState();
}

class _CommanderSelectScreenState
    extends ConsumerState<CommanderSelectScreen> {
  // Route extra also passes hasPartner
  bool _hasPartner = false;

  final _searchController = TextEditingController();
  Timer? _debounce;

  List<ScryfallCard> _results = [];
  bool _loading = false;
  String? _error;

  // Selected cards
  ScryfallCard? _primary;
  ScryfallCard? _partner;
  bool _pickingPartner = false; // true when user is selecting the 2nd card

  @override
  void initState() {
    super.initState();
    if (widget.editDeckId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEditDeck());
    }
  }

  void _loadEditDeck() {
    final deck =
        ref.read(deckRepositoryProvider).getById(widget.editDeckId!);
    if (deck == null || !mounted) return;
    setState(() {
      _hasPartner = deck.hasPartner;
      _primary = ScryfallCard(
        name: deck.commanderName,
        imageUrl: deck.commanderImageUrl,
        manaCost: deck.commanderManaCost,
        colorIdentity: deck.hasPartner
            ? const []
            : List<String>.from(deck.commanderColorIdentity),
      );
      if (deck.hasPartner && deck.partnerCommanderName != null) {
        _partner = ScryfallCard(
          name: deck.partnerCommanderName!,
          imageUrl: deck.partnerCommanderImageUrl,
          manaCost: deck.partnerManaCost,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget._deckMode) return;
    // Resolve hasPartner from lobby state for this player
    final lobbySlots = ref.read(lobbyProvider).players;
    final slot = lobbySlots.where((p) => p.playerId == widget.playerId);
    if (slot.isNotEmpty) _hasPartner = slot.first.hasPartner;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(scryfallServiceProvider);
      final results = await service.searchCommanders(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        if (results.isEmpty) _error = 'No commanders found for "$query"';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = 'Unable to search. Check your internet connection and try again.';
      });
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void _onCardTap(ScryfallCard card) {
    if (_pickingPartner) {
      setState(() {
        _partner = card;
        _pickingPartner = false;
      });
    } else {
      setState(() {
        _primary = card;
        _partner = null; // reset partner when primary changes
      });
    }
  }

  bool get _canConfirm {
    if (_primary == null) return false;
    if (_hasPartner && _partner == null) return false;
    return true;
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    if (widget.newDeckDisplayName != null &&
        widget.newDeckDisplayName!.trim().isNotEmpty) {
      final ci = ScryfallCard.unionColorIdentity(_primary!, _hasPartner ? _partner : null);
      final deck = PlayerDeck.create(
        displayName: widget.newDeckDisplayName!.trim(),
        commanderName: _primary!.name,
        commanderImageUrl: _primary!.imageUrl,
        partnerCommanderName: _hasPartner ? _partner?.name : null,
        partnerCommanderImageUrl: _hasPartner ? _partner?.imageUrl : null,
        commanderManaCost: _hiveManaCost(_primary!.manaCost),
        partnerManaCost: _hasPartner ? _hiveManaCost(_partner?.manaCost) : null,
        commanderColorIdentity: ci,
      );
      await ref.read(deckRepositoryProvider).save(deck);
      bumpDeckListRevision(ref);
      if (mounted) context.pop();
      return;
    }
    if (widget.editDeckId != null) {
      final repo = ref.read(deckRepositoryProvider);
      final deck = repo.getById(widget.editDeckId!);
      if (deck == null) {
        if (mounted) context.pop();
        return;
      }
      final ci = ScryfallCard.unionColorIdentity(_primary!, _hasPartner ? _partner : null);
      deck.commanderName = _primary!.name;
      deck.commanderImageUrl = _primary!.imageUrl;
      deck.commanderManaCost = _hiveManaCost(_primary!.manaCost);
      deck.partnerCommanderName = _hasPartner ? _partner?.name : null;
      deck.partnerCommanderImageUrl = _hasPartner ? _partner?.imageUrl : null;
      deck.partnerManaCost = _hasPartner ? _hiveManaCost(_partner?.manaCost) : null;
      deck.commanderColorIdentity = ci;
      await repo.save(deck);
      bumpDeckListRevision(ref);
      if (mounted) context.pop();
      return;
    }
    ref.read(lobbyProvider.notifier).setCommander(
          playerId: widget.playerId,
          commanderName: _primary!.name,
          commanderImageUrl: _primary!.imageUrl ?? '',
          partnerCommanderName: _hasPartner ? _partner?.name : null,
          partnerCommanderImageUrl:
              _hasPartner ? (_partner?.imageUrl ?? '') : null,
          commanderColorIdentity:
              ScryfallCard.unionColorIdentity(_primary!, _hasPartner ? _partner : null),
        );
    if (mounted) context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  String get _title {
    if (widget._deckMode) {
      if (widget.editDeckId != null) return 'Edit deck commanders';
      return 'New deck — pick commander';
    }
    return _pickingPartner ? 'Select Partner' : 'Select Commander';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text(_pickingPartner ? 'Select Partner' : _title),
        actions: [
          if (_canConfirm)
            TextButton(
              onPressed: _confirm,
              child: const Text(
                'Confirm',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selected preview
          if (_primary != null || (_hasPartner && _partner != null))
            _SelectionPreview(
              primary: _primary,
              partner: _hasPartner ? _partner : null,
              hasPartner: _hasPartner,
              onPickPartner: _primary != null
                  ? () => setState(() => _pickingPartner = !_pickingPartner)
                  : null,
              pickingPartner: _pickingPartner,
            ),
          if (widget._deckMode)
            Padding(
              padding: EdgeInsets.fromLTRB(
                LayoutTokens.gr3,
                LayoutTokens.gr1,
                LayoutTokens.gr3,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: const Text('Partner commander'),
                  selected: _hasPartner,
                  onSelected: (v) {
                    setState(() {
                      _hasPartner = v;
                      if (!v) {
                        _partner = null;
                        _pickingPartner = false;
                      }
                    });
                  },
                ),
              ),
            ),

          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(LayoutTokens.gr3, LayoutTokens.gr2, LayoutTokens.gr3, 0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _pickingPartner
                    ? 'Search for partner commander…'
                    : 'Search for a commander…',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 12),

          // Results
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_results.isEmpty && _searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Type a commander name to search the Scryfall database.',
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(LayoutTokens.gr3, 0, LayoutTokens.gr3, LayoutTokens.gr4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final card = _results[i];
        final isSelected = card.name == _primary?.name ||
            (card.name == _partner?.name && _hasPartner);
        return _CommanderCard(
          card: card,
          isSelected: isSelected,
          onTap: () => _onCardTap(card),
        );
      },
    );
  }
}

// ── Selection preview strip ───────────────────────────────────────────────

class _SelectionPreview extends StatelessWidget {
  final ScryfallCard? primary;
  final ScryfallCard? partner;
  final bool hasPartner;
  final VoidCallback? onPickPartner;
  final bool pickingPartner;

  const _SelectionPreview({
    required this.primary,
    required this.partner,
    required this.hasPartner,
    this.onPickPartner,
    required this.pickingPartner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(LayoutTokens.gr3, LayoutTokens.gr2, LayoutTokens.gr3, LayoutTokens.gr1),
      color: AppTheme.surface,
      child: Row(
        children: [
          if (primary != null) _MiniCard(card: primary!, label: 'Commander'),
          if (hasPartner) ...[
            const SizedBox(width: 8),
            if (partner != null)
              _MiniCard(card: partner!, label: 'Partner')
            else
              GestureDetector(
                onTap: onPickPartner,
                child: Container(
                  width: 56,
                  height: 78,
                  decoration: BoxDecoration(
                    color: pickingPartner
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pickingPartner
                          ? AppTheme.accent
                          : AppTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: pickingPartner
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Partner',
                        style: TextStyle(
                          color: pickingPartner
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const Spacer(),
          if (hasPartner && partner == null)
            Flexible(
              child: TextButton(
                onPressed: onPickPartner,
                child: Text(
                  pickingPartner ? 'Cancel' : 'Add Partner',
                  style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final ScryfallCard card;
  final String label;
  const _MiniCard({required this.card, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: card.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: card.imageUrl!,
                  width: 56,
                  height: 78,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 78,
        color: AppTheme.card,
        child: const Icon(Icons.style, color: AppTheme.textSecondary),
      );
}

// ── Commander card grid item ──────────────────────────────────────────────

class _CommanderCard extends StatelessWidget {
  final ScryfallCard card;
  final bool isSelected;
  final VoidCallback onTap;

  const _CommanderCard({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: card.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: card.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.accent),
                        ),
                        errorWidget: (_, __, ___) => Image.asset(
                          ScryfallCard.offlineImageAsset,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        ScryfallCard.offlineImageAsset,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (card.isPartner)
                    const Text(
                      'Partner',
                      style: TextStyle(
                          color: AppTheme.accentGold, fontSize: 10),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 14, color: ColorTokens.onAccent),
                    SizedBox(width: 4),
                    Text(
                      'Selected',
                      style: TextStyle(
                          color: ColorTokens.onAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
