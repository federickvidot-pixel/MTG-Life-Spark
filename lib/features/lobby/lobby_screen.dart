import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/bluetooth/ble_providers.dart';
import '../../core/game/game_format.dart';
import '../../core/game/lobby_state.dart';
import '../../core/models/player_slot.dart';
import '../../core/models/pod_preset.dart';
import '../../core/network/local_ip.dart';
import '../../core/network/ws_host_service.dart';
import '../../core/persistence/providers.dart';
import '../../shared/utils/app_router.dart';
import 'deck_picker_sheet.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/color_tokens.dart';
import '../../ui/tokens/font_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';
import '../../ui/tokens/typography_tokens.dart';
import '../../ui/components/ui_app_bar.dart';
import '../../ui/tokens/opacity_tokens.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  String? _qrData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await startHostSession(ref);
      ref.read(lobbyProvider.notifier).initAsHost();
      _buildQrData();
    });
  }

  Future<void> _buildQrData() async {
    final host = ref.read(bleServiceProvider);
    if (host is! WsHostService) return;
    final ip = await getLocalIpAddress();
    if (ip == null || !mounted) return;
    setState(() {
      _qrData = 'mgtlifespark://$ip:${host.port}';
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobby = ref.watch(lobbyProvider);
    final colors = AppColorTokens.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: UiAppBar(
        title: 'Host Lobby',
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await endSession(ref);
            if (context.mounted) context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            LayoutTokens.gr3,
            LayoutTokens.gr2,
            LayoutTokens.gr3,
            LayoutTokens.gr5 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
          _QrHeader(qrData: _qrData, playerCount: lobby.players.length),
          SizedBox(height: LayoutTokens.gr4),
          ...lobby.players.map((slot) => _PlayerSlotCard(slot: slot)),
          if (lobby.players.length < lobby.config.maxPlayers)
            _EmptySlotCard(
              remaining: lobby.config.maxPlayers - lobby.players.length,
            ),
          SizedBox(height: LayoutTokens.gr4),
          const _PodSection(),
          SizedBox(height: LayoutTokens.gr4),
          _ConfigSection(config: lobby.config),
          SizedBox(height: LayoutTokens.gr4),
          _StartGameButton(
            canStart: lobby.canStart,
            hint: lobby.players.isEmpty
                ? 'Need at least 1 player'
                : lobby.players.any((p) => !p.isReady)
                    ? 'Everyone must be ready'
                    : 'Start Game',
          ),
          SizedBox(height: LayoutTokens.gr5),
        ],
        ),
      ),
    );
  }
}

// ── Match pod (presets) ─────────────────────────────────────────────────

class _PodSection extends ConsumerWidget {
  const _PodSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobby = ref.watch(lobbyProvider);
    final pods = ref.watch(podPresetsListProvider);
    final repo = ref.read(podRepositoryProvider);
    final notifier = ref.read(lobbyProvider.notifier);
    final colors = AppColorTokens.of(context);
    final compact = MediaQuery.sizeOf(context).width < 360;

    String? effectiveId;
    PodPreset? selectedPreset;
    if (lobby.selectedPodPresetId != null &&
        pods.any((p) => p.id == lobby.selectedPodPresetId)) {
      effectiveId = lobby.selectedPodPresetId;
      selectedPreset = repo.getById(effectiveId!);
    }

    return Container(
      padding: EdgeInsets.all(compact ? LayoutTokens.gr3 : LayoutTokens.gr4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.radiusChip,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match pod',
            style: TypographyTokens.sectionTitle(colors.textPrimary),
          ),
          SizedBox(height: LayoutTokens.gr1),
          Text(
            'Optional. Pod name is saved with match history. Players listed on the pod are shown below so you know who is in this group.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: LayoutTokens.gr2),
          DropdownButton<String?>(
            isExpanded: true,
            value: effectiveId,
            hint: Text(
              'None',
              style: TextStyle(color: colors.textSecondary),
            ),
            dropdownColor: colors.surface,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'None',
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),
              ...pods.map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ),
              ),
            ],
            onChanged: (id) {
              if (id == null) {
                notifier.setMatchPodFromPreset(null);
              } else {
                final preset = repo.getById(id);
                if (preset != null) notifier.setMatchPodFromPreset(preset);
              }
            },
          ),
          if (selectedPreset != null &&
              selectedPreset.memberPlayerIds.isNotEmpty) ...[
            SizedBox(height: LayoutTokens.gr2),
            Text(
              'Players in this pod',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: FontTokens.hudXs,
              ),
            ),
            SizedBox(height: LayoutTokens.gr1),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selectedPreset.memberPlayerIds.map((id) {
                return Chip(
                  label: Text(
                    id,
                    style: TextStyle(color: colors.textPrimary, fontSize: 12),
                  ),
                  backgroundColor: colors.backgroundSecondary,
                  side: BorderSide(
                    color: colors.textSecondary.withValues(alpha: 0.25),
                  ),
                );
              }).toList(),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.profilePods),
              icon: Icon(Icons.edit_note, color: colors.primaryAccent, size: 20),
              label: Text(
                'Manage pods',
                style: TextStyle(
                  color: colors.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR code header ────────────────────────────────────────────────────────

class _QrHeader extends StatelessWidget {
  final String? qrData;
  final int playerCount;
  const _QrHeader({required this.qrData, required this.playerCount});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < 360;
    final qrSize = compact ? 140.0 : 160.0;
    final pad = compact ? LayoutTokens.gr3 : LayoutTokens.gr4;

    return Container(
      width: double.infinity,
      color: colors.backgroundSecondary,
      padding: EdgeInsets.symmetric(vertical: pad, horizontal: pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, color: colors.primaryAccent, size: compact ? 16 : 18),
              SizedBox(width: LayoutTokens.gr1),
              Flexible(
                child: Text(
                  'Players joined: $playerCount  •  Scan QR to join',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: compact ? 12 : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: LayoutTokens.gr3),
          if (qrData == null)
            SizedBox(
              height: qrSize,
              child: Center(
                child: CircularProgressIndicator(color: colors.primaryAccent),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: ColorTokens.onAccent,
                borderRadius: RadiusTokens.radiusSm,
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryAccent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: QrImageView(
                data: qrData!,
                version: QrVersions.auto,
                size: qrSize,
                backgroundColor: Colors.white,
              ),
            ),
          if (qrData != null)
            Padding(
              padding: EdgeInsets.only(top: LayoutTokens.gr1),
              child: Text(
                qrData!.replaceFirst('mgtlifespark://', ''),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: compact ? 9 : 10,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Player slot card ──────────────────────────────────────────────────────

class _PlayerSlotCard extends ConsumerWidget {
  final PlayerSlot slot;
  const _PlayerSlotCard({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorTokens.of(context);
    final isLocalHost = ref.watch(
      profileRepositoryProvider.select((r) => r.getProfile()?.username),
    );
    final isMe = slot.playerId == isLocalHost;
    final linkedDeck = isMe && slot.selectedDeckId != null
        ? ref.read(deckRepositoryProvider).getById(slot.selectedDeckId!)
        : null;

    final borderColor = isMe
        ? (slot.isReady ? ColorTokens.success : colors.primaryAccent)
        : slot.playerColor.withValues(alpha: 0.25);

    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      margin: EdgeInsets.only(bottom: LayoutTokens.gr2),
      padding: EdgeInsets.all(compact ? LayoutTokens.gr2 : LayoutTokens.gr3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.radiusMd,
        border: Border.all(
          color: borderColor,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: OpacityTokens.subtle),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommanderAvatar(slot: slot, compact: compact),
              SizedBox(width: LayoutTokens.gr2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: LayoutTokens.gr1,
                          height: LayoutTokens.gr1,
                          decoration: BoxDecoration(
                            color: slot.playerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: LayoutTokens.gr1),
                        Expanded(
                          child: Text(
                            slot.username,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: FontTokens.title,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: LayoutTokens.gr1),
                    Text(
                      slot.commanderName ?? 'No commander selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            slot.commanderName != null
                                ? colors.textSecondary
                                : colors.primaryAccent,
                        fontSize: FontTokens.caption,
                      ),
                    ),
                    if (slot.hasPartner && slot.partnerCommanderName != null)
                      Text(
                        '+ ${slot.partnerCommanderName}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FontTokens.sm,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isMe && slot.selectedDeckId != null) ...[
                      SizedBox(height: LayoutTokens.gr0),
                      Text(
                        linkedDeck != null
                            ? 'Tracking: ${linkedDeck.displayName}'
                            : 'Deck (saved list changed)',
                        style: TextStyle(
                          color: colors.primaryAccent,
                          fontSize: FontTokens.hudXs,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isMe) _SlotReadyButton(slot: slot),
            ],
          ),
          if (isMe) ...[
            SizedBox(height: LayoutTokens.gr2),
            _SlotCommanderControls(slot: slot),
          ],
        ],
      ),
    );
  }
}

/// Partner / Deck / Commander actions for the local player's slot (full-width row).
class _SlotCommanderControls extends ConsumerWidget {
  final PlayerSlot slot;

  const _SlotCommanderControls({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = LayoutTokens.gr1;

    return Row(
      children: [
        Expanded(
          child: _SlotActionButton(
            label: 'Deck',
            highlighted: slot.selectedDeckId != null,
            filled: false,
            onPressed:
                () => showDeckPickerSheet(context, ref, slot.playerId),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _SlotActionButton(
            label: 'Commander',
            highlighted: slot.commanderName != null,
            filled: true,
            onPressed:
                () => context.push(
                  AppRoutes.commanderSelect,
                  extra: {
                    'playerId': slot.playerId,
                    'hasPartner': slot.hasPartner,
                  },
                ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(child: _PartnerChip(slot: slot)),
      ],
    );
  }
}

class _SlotReadyButton extends ConsumerWidget {
  final PlayerSlot slot;

  const _SlotReadyButton({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorTokens.of(context);
    return IconButton(
      style: IconButton.styleFrom(
        minimumSize: const Size(
          LayoutTokens.minTapTarget,
          LayoutTokens.minTapTarget,
        ),
        backgroundColor:
            slot.isReady
                ? ColorTokens.success.withValues(alpha: OpacityTokens.soft)
                : colors.surface,
        foregroundColor:
            slot.isReady ? ColorTokens.success : colors.textSecondary,
        side: BorderSide(
          color: slot.isReady ? ColorTokens.success : colors.textSecondary,
        ),
      ),
      onPressed: () {
        final notifier = ref.read(lobbyProvider.notifier);
        notifier.setReady(slot.playerId, ready: !slot.isReady);
      },
      icon: Icon(Icons.check_rounded, size: 24),
    );
  }
}

class _SlotActionButton extends StatelessWidget {
  final String label;
  final bool highlighted;
  final bool filled;
  final VoidCallback onPressed;

  const _SlotActionButton({
    required this.label,
    required this.highlighted,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final accent = colors.primaryAccent;

    Color? bg;
    Color fg;
    Color border;

    if (filled && highlighted) {
      bg = accent;
      fg = ColorTokens.onAccent;
      border = accent;
    } else if (highlighted) {
      bg = accent.withValues(alpha: 0.35);
      fg = colors.textPrimary;
      border = accent;
    } else {
      bg = Colors.transparent;
      fg = colors.textSecondary;
      border = colors.textSecondary;
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: LayoutTokens.gr2),
        backgroundColor: bg,
        foregroundColor: fg,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LayoutTokens.gr1),
        ),
        textStyle: TextStyle(
          fontSize: FontTokens.sm,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CommanderAvatar extends StatelessWidget {
  final PlayerSlot slot;
  final bool compact;
  const _CommanderAvatar({required this.slot, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size =
        compact ? LayoutTokens.minTapTarget : LayoutTokens.gr6 + LayoutTokens.gr0;
    if (slot.commanderImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(LayoutTokens.gr1),
        child: CachedNetworkImage(
          imageUrl: slot.commanderImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _ColorDot(color: slot.playerColor, size: size),
        ),
      );
    }
    return _ColorDot(color: slot.playerColor, size: size);
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;
  const _ColorDot({required this.color, this.size = LayoutTokens.gr6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(LayoutTokens.gr1),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(Icons.person, color: color, size: size * 0.56),
    );
  }
}

class _PartnerChip extends ConsumerWidget {
  final PlayerSlot slot;
  const _PartnerChip({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorTokens.of(context);
    final accent = colors.primaryAccent;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, LayoutTokens.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: LayoutTokens.gr2),
        backgroundColor:
            slot.hasPartner
                ? accent.withValues(alpha: 0.15)
                : Colors.transparent,
        foregroundColor:
            slot.hasPartner ? accent : colors.textSecondary,
        side: BorderSide(
          color:
              slot.hasPartner
                  ? accent
                  : colors.textSecondary.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LayoutTokens.gr1),
        ),
        textStyle: TextStyle(
          fontSize: FontTokens.sm,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed:
          () => ref.read(lobbyProvider.notifier).togglePartner(slot.playerId),
      child: Text(
        'Partner',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Empty slots indicator ─────────────────────────────────────────────────

class _EmptySlotCard extends StatelessWidget {
  final int remaining;
  const _EmptySlotCard({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: LayoutTokens.gr2),
      padding: EdgeInsets.symmetric(vertical: LayoutTokens.gr4),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: RadiusTokens.radiusChip,
        border: Border.all(
          color: colors.textSecondary.withValues(alpha: OpacityTokens.soft),
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: LayoutTokens.gr2),
        child: Text(
          '$remaining open slot${remaining == 1 ? '' : 's'} — share your device to let friends join',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: MediaQuery.sizeOf(context).width < 360 ? 12 : 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
  }
}

// ── Config section ────────────────────────────────────────────────────────

class _ConfigSection extends ConsumerWidget {
  final LobbyConfig config;
  const _ConfigSection({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorTokens.of(context);
    final notifier = ref.read(lobbyProvider.notifier);

    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.all(compact ? LayoutTokens.gr3 : LayoutTokens.gr4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.radiusChip,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Settings',
            style: TypographyTokens.sectionTitle(colors.textPrimary),
          ),
          SizedBox(height: LayoutTokens.gr3),
          _ConfigDropdownRow(
            label: 'Format',
            child: _FormatDropdown(
              value: config.format,
              onChanged: (f) => notifier.updateConfig(
                config.copyWith(
                  format: f,
                  startingLife: f.defaultStartingLife,
                ),
              ),
            ),
          ),
          SizedBox(height: LayoutTokens.gr3),
          _ConfigDropdownRow(
            label: 'Starting Life',
            child: _StartingLifeDropdown(
              value: config.startingLife,
              onChanged:
                  (v) => notifier.updateConfig(
                    config.copyWith(startingLife: v),
                  ),
            ),
          ),
          SizedBox(height: LayoutTokens.gr4),
          // Gameplay settings
          Text(
            'Gameplay',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: LayoutTokens.gr2),
          _GameplayToggles(config: config, notifier: notifier),
        ],
      ),
    );
  }
}

InputDecoration _lobbyDropdownDecoration(BuildContext context) {
  final colors = AppColorTokens.of(context);
  final border = OutlineInputBorder(
    borderRadius: RadiusTokens.radiusSm,
    borderSide: BorderSide(
      color: colors.textSecondary.withValues(alpha: OpacityTokens.moderate),
    ),
  );
  return InputDecoration(
    filled: true,
    fillColor: colors.backgroundSecondary,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: LayoutTokens.gr3,
      vertical: LayoutTokens.gr2,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: colors.primaryAccent),
    ),
  );
}

/// Label + full-width dropdown (Format, Starting Life, …).
class _ConfigDropdownRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _ConfigDropdownRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FontTokens.label,
            ),
          ),
        ),
        SizedBox(width: LayoutTokens.gr2),
        Expanded(child: child),
      ],
    );
  }
}

class _FormatDropdown extends StatelessWidget {
  final GameFormat value;
  final ValueChanged<GameFormat> onChanged;

  const _FormatDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return DropdownButtonFormField<GameFormat>(
      value: value,
      isExpanded: true,
      decoration: _lobbyDropdownDecoration(context),
      dropdownColor: colors.surface,
      style: TextStyle(color: colors.textPrimary, fontSize: FontTokens.body),
      menuMaxHeight: 360,
      items:
          GameFormatDetails.lobbyPickerOrder
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f.displayName),
                ),
              )
              .toList(),
      onChanged: (f) {
        if (f != null) onChanged(f);
      },
    );
  }
}

class _StartingLifeDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StartingLifeDropdown({
    required this.value,
    required this.onChanged,
  });

  static const _presets = [20, 25, 30, 40, 60];
  static const _customMenuValue = -1;

  static void _showCustomDialog(
    BuildContext context, {
    required int current,
    required ValueChanged<int> onChanged,
  }) {
    final controller = TextEditingController(text: current.toString());
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = AppColorTokens.of(ctx);
        return AlertDialog(
          title: Text(
            'Custom Starting Life',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter life total (1–999)',
              hintStyle: TextStyle(color: colors.textSecondary),
            ),
            onSubmitted: (s) {
              final v = int.tryParse(s);
              if (v != null && v >= 1 && v <= 999) {
                onChanged(v);
                Navigator.pop(ctx);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(controller.text);
                if (v != null && v >= 1 && v <= 999) {
                  onChanged(v);
                  Navigator.pop(ctx);
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final items = <DropdownMenuItem<int>>[
      ..._presets.map(
        (v) => DropdownMenuItem(value: v, child: Text('$v')),
      ),
      if (!_presets.contains(value))
        DropdownMenuItem(value: value, child: Text('$value')),
      const DropdownMenuItem(
        value: _customMenuValue,
        child: Text('Custom…'),
      ),
    ];

    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: _lobbyDropdownDecoration(context),
      dropdownColor: colors.surface,
      style: TextStyle(color: colors.textPrimary, fontSize: FontTokens.body),
      items: items,
      onChanged: (v) {
        if (v == null) return;
        if (v == _customMenuValue) {
          _showCustomDialog(context, current: value, onChanged: onChanged);
        } else {
          onChanged(v);
        }
      },
    );
  }
}

class _TurnTimeLimitDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _TurnTimeLimitDropdown({
    required this.value,
    required this.onChanged,
  });

  static const _presets = <int?>[null, 30, 60];

  static String _label(int? seconds) => switch (seconds) {
    null => 'Off',
    30 => '30 seconds',
    60 => '60 seconds',
    final int s => '$s seconds',
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final items = <DropdownMenuItem<int?>>[
      ..._presets.map(
        (v) => DropdownMenuItem(value: v, child: Text(_label(v))),
      ),
      if (value != null && !_presets.contains(value))
        DropdownMenuItem(value: value, child: Text(_label(value))),
    ];

    return DropdownButtonFormField<int?>(
      value: value,
      isExpanded: true,
      decoration: _lobbyDropdownDecoration(context),
      dropdownColor: colors.surface,
      style: TextStyle(color: colors.textPrimary, fontSize: FontTokens.body),
      items: items,
      onChanged: onChanged,
    );
  }
}

// ── Gameplay toggles (reference: grouped card style with icons & subtitles) ─

class _GameplayToggles extends StatelessWidget {
  final LobbyConfig config;
  final LobbyNotifier notifier;
  const _GameplayToggles({required this.config, required this.notifier});

  bool get _autoKoAll =>
      config.autoKoFromLife &&
      config.autoKoFromPoison &&
      config.autoKoFromCommanderDamage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GameplaySwitchTile(
          title: 'Planechase',
          subtitle: 'Internet required for planar deck',
          value: config.planechaseEnabled,
          onChanged: (v) =>
              notifier.updateConfig(config.copyWith(planechaseEnabled: v)),
        ),
        _GameplaySwitchTile(
          title: 'Archenemy',
          subtitle: 'Internet required for scheme deck',
          value: config.archenemyEnabled,
          onChanged: (v) =>
              notifier.updateConfig(config.copyWith(archenemyEnabled: v)),
        ),
        _GameplaySwitchTile(
          title: 'Bounty',
          subtitle: 'Internet required for bounty deck',
          value: config.bountyEnabled,
          onChanged: (v) =>
              notifier.updateConfig(config.copyWith(bountyEnabled: v)),
        ),
        _GameplaySwitchTile(
          title: 'Auto-KO',
          subtitle: 'From life, poison, or commander damage',
          value: _autoKoAll,
          onChanged: (v) => notifier.updateConfig(config.copyWith(
                autoKoFromLife: v,
                autoKoFromPoison: v,
                autoKoFromCommanderDamage: v,
              )),
        ),
        _GameplaySwitchTile(
          title: 'Commander damage life loss',
          subtitle: 'Commander damage also reduces life',
          value: config.commanderDamageReducesLife,
          onChanged: (v) => notifier.updateConfig(
              config.copyWith(commanderDamageReducesLife: v)),
        ),
        _GameplaySwitchTile(
          title: 'Turn timer',
          subtitle: 'Show elapsed time each turn',
          value: config.trackTurnDuration,
          onChanged:
              (v) => notifier.updateConfig(
                config.copyWith(
                  trackTurnDuration: v,
                  turnTimeLimitSeconds: v ? config.turnTimeLimitSeconds : null,
                ),
              ),
        ),
        if (config.trackTurnDuration) ...[
          SizedBox(height: LayoutTokens.gr1),
          Padding(
            padding: const EdgeInsets.only(
              left: LayoutTokens.gr4,
              right: LayoutTokens.gr4,
              bottom: LayoutTokens.gr2,
            ),
            child: _ConfigDropdownRow(
              label: 'Turn limit',
              child: _TurnTimeLimitDropdown(
                value: config.turnTimeLimitSeconds,
                onChanged:
                    (v) => notifier.updateConfig(
                      config.copyWith(turnTimeLimitSeconds: v),
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GameplaySwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GameplaySwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.radiusSm,
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: compact ? FontTokens.body : FontTokens.title,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: FontTokens.caption,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: colors.primaryAccent.withValues(alpha: OpacityTokens.half),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primaryAccent;
          }
          return null;
        }),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: 8,
        ),
      ),
    );
  }
}

// ── Start game button ─────────────────────────────────────────────────────

class _StartGameButton extends ConsumerStatefulWidget {
  final bool canStart;
  final String hint;
  const _StartGameButton({required this.canStart, required this.hint});

  @override
  ConsumerState<_StartGameButton> createState() => _StartGameButtonState();
}

class _StartGameButtonState extends ConsumerState<_StartGameButton> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final canStart = widget.canStart && !_isStarting;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: canStart ? ColorTokens.success : colors.textSecondary,
        disabledBackgroundColor: colors.textSecondary.withValues(alpha: OpacityTokens.moderate),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: canStart
          ? () async {
              setState(() => _isStarting = true);
              try {
                await ref.read(lobbyProvider.notifier).broadcastGameStart();
                if (context.mounted) context.go(AppRoutes.game);
              } finally {
                if (mounted) setState(() => _isStarting = false);
              }
            }
          : null,
      child: _isStarting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorTokens.onAccent,
              ),
            )
          : Text(
              widget.canStart ? 'Start Game' : widget.hint,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.sizeOf(context).width < 360 ? FontTokens.title : FontTokens.bodyLg,
                color: ColorTokens.onAccent,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
    );
  }
}
