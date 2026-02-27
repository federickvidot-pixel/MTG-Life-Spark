import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/game/scryfall_service.dart';
import '../../core/persistence/providers.dart';
import '../../ui/components/ui_app_bar.dart';
import '../../ui/tokens/color_tokens.dart';

/// Screen to pick an MTG card image as profile avatar.
class ProfileAvatarPickerScreen extends ConsumerStatefulWidget {
  const ProfileAvatarPickerScreen({super.key});

  @override
  ConsumerState<ProfileAvatarPickerScreen> createState() =>
      _ProfileAvatarPickerScreenState();
}

class _ProfileAvatarPickerScreenState
    extends ConsumerState<ProfileAvatarPickerScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<ScryfallCard> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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
      final results = await service.searchCards(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        if (results.isEmpty) _error = 'No cards found for "$query"';
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

  Future<void> _onCardTap(ScryfallCard card) async {
    if (card.imageUrl == null || card.imageUrl!.isEmpty) return;
    final profile = ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;
    profile.profileAvatarImageUrl = card.imageUrl;
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    ref.invalidate(profileProvider);
    if (mounted) context.pop();
  }

  Future<void> _clearAvatar() async {
    final profile = ref.read(profileRepositoryProvider).getProfile();
    if (profile == null) return;
    profile.profileAvatarImageUrl = null;
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    ref.invalidate(profileProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiAppBar(
        title: 'Profile Picture',
        actions: [
          TextButton(
            onPressed: _clearAvatar,
            child: Text(
              'Remove',
              style: TextStyle(
                color: ColorTokens.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: ColorTokens.backgroundPrimary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search MTG cards…',
                prefixIcon: const Icon(
                  Icons.search,
                  color: ColorTokens.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: ColorTokens.textSecondary,
                        ),
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
              style: const TextStyle(color: ColorTokens.textPrimary),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorTokens.primaryAccent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: ColorTokens.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_results.isEmpty && _searchController.text.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Search for an MTG card to use as your profile picture.',
            style: TextStyle(color: ColorTokens.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final card = _results[i];
        return _AvatarCard(
          card: card,
          onTap: () => _onCardTap(card),
        );
      },
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final ScryfallCard card;
  final VoidCallback onTap;

  const _AvatarCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: card.imageUrl != null ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: ColorTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorTokens.borderSubtle.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: card.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: card.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  card.name,
                  style: const TextStyle(
                    color: ColorTokens.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: ColorTokens.backgroundSecondary,
        child: const Center(
          child: Icon(Icons.style, color: ColorTokens.textMuted, size: 32),
        ),
      );
}
