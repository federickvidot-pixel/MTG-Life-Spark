import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/bluetooth/ble_providers.dart';
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
      appBar: AppBar(
        title: const Text('Host Lobby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match pod',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
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
                fontSize: 11,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Commander avatar / color dot
          _CommanderAvatar(slot: slot, compact: compact),
          SizedBox(width: LayoutTokens.gr2),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
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
                        color: slot.commanderName != null
                        ? colors.textSecondary
                        : colors.primaryAccent,
                    fontSize: FontTokens.caption,
                  ),
                ),
                if (slot.hasPartner && slot.partnerCommanderName != null)
                  Text(
                    '+ ${slot.partnerCommanderName}',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: FontTokens.sm),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Controls (for own slot: host and clients)
          if (isMe)
            Flexible(
              fit: FlexFit.loose,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 280;
                  final btnH = 44.0; // Min touch target
                  final btnPadH = isNarrow ? 10.0 : 16.0;
                  final readyButton = IconButton(
                    style: IconButton.styleFrom(
                      minimumSize: Size(btnH, btnH),
                      backgroundColor: slot.isReady
                          ? ColorTokens.success.withValues(alpha: 0.2)
                          : colors.surface,
                      foregroundColor: slot.isReady
                          ? ColorTokens.success
                          : colors.textSecondary,
                      side: BorderSide(
                        color: slot.isReady
                            ? ColorTokens.success
                            : colors.textSecondary,
                      ),
                    ),
                    onPressed: () {
                      final notifier = ref.read(lobbyProvider.notifier);
                      notifier.setReady(slot.playerId, ready: !slot.isReady);
                    },
                    icon: Icon(
                      slot.isReady ? Icons.check : Icons.check,
                      size: 24,
                    ),
                  );
                  if (isNarrow) {
                    // Narrow: Partner above Commander (same width), checkmark centered to the box
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PartnerChip(slot: slot, compact: true),
                              SizedBox(height: LayoutTokens.gr2),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(0, btnH),
                                  padding: EdgeInsets.symmetric(horizontal: btnPadH),
                                  backgroundColor: slot.selectedDeckId != null
                                      ? colors.primaryAccent.withValues(alpha: 0.35)
                                      : Colors.transparent,
                                  foregroundColor: slot.selectedDeckId != null
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                  side: BorderSide(
                                    color: slot.selectedDeckId != null
                                        ? colors.primaryAccent
                                        : colors.textSecondary,
                                  ),
                                  textStyle: TextStyle(fontSize: FontTokens.body, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => showDeckPickerSheet(
                                  context,
                                  ref,
                                  slot.playerId,
                                ),
                                child: const Text('Deck'),
                              ),
                              SizedBox(height: LayoutTokens.gr2),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(0, btnH),
                                  padding: EdgeInsets.symmetric(horizontal: btnPadH),
                                  backgroundColor: slot.commanderName != null
                                      ? colors.primaryAccent
                                      : Colors.transparent,
                                  foregroundColor: slot.commanderName != null
                                      ? Colors.white
                                      : colors.textSecondary,
                                  side: BorderSide(
                                    color: slot.commanderName != null
                                        ? colors.primaryAccent
                                        : colors.textSecondary,
                                  ),
                                  textStyle: TextStyle(fontSize: FontTokens.body, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => context.push(
                                  AppRoutes.commanderSelect,
                                  extra: {
                                    'playerId': slot.playerId,
                                    'hasPartner': slot.hasPartner,
                                  },
                                ),
                                child: const Text('Commander'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: LayoutTokens.gr2),
                        readyButton,
                      ],
                    );
                  }
                  // Wide: all three in a row
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PartnerChip(slot: slot, compact: false),
                      SizedBox(width: LayoutTokens.gr2),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(72, btnH),
                          padding: EdgeInsets.symmetric(horizontal: btnPadH),
                          backgroundColor: slot.selectedDeckId != null
                              ? colors.primaryAccent.withValues(alpha: 0.35)
                              : Colors.transparent,
                          foregroundColor: slot.selectedDeckId != null
                              ? colors.textPrimary
                              : colors.textSecondary,
                          side: BorderSide(
                            color: slot.selectedDeckId != null
                                ? colors.primaryAccent
                                : colors.textSecondary,
                          ),
                          textStyle: TextStyle(fontSize: FontTokens.body, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => showDeckPickerSheet(
                          context,
                          ref,
                          slot.playerId,
                        ),
                        child: const Text('Deck'),
                      ),
                      SizedBox(width: LayoutTokens.gr2),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(80, btnH),
                          padding: EdgeInsets.symmetric(horizontal: btnPadH),
                          backgroundColor: slot.commanderName != null
                              ? colors.primaryAccent
                              : Colors.transparent,
                          foregroundColor: slot.commanderName != null
                              ? Colors.white
                              : colors.textSecondary,
                          side: BorderSide(
                            color: slot.commanderName != null
                                ? colors.primaryAccent
                                : colors.textSecondary,
                          ),
                          textStyle: TextStyle(fontSize: FontTokens.body, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => context.push(
                          AppRoutes.commanderSelect,
                          extra: {
                            'playerId': slot.playerId,
                            'hasPartner': slot.hasPartner,
                          },
                        ),
                        child: const Text('Commander'),
                      ),
                      SizedBox(width: LayoutTokens.gr2),
                      readyButton,
                    ],
                  );
                },
              ),
            ),
        ],
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
    final size = compact ? 44.0 : 50.0;
    if (slot.commanderImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
  const _ColorDot({required this.color, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(Icons.person, color: color, size: size * 0.56),
    );
  }
}

class _PartnerChip extends ConsumerWidget {
  final PlayerSlot slot;
  final bool compact;
  const _PartnerChip({required this.slot, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorTokens.of(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(compact ? 60 : 80, 44),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        backgroundColor: slot.hasPartner
            ? ColorTokens.accentGold.withValues(alpha: 0.15)
            : Colors.transparent,
        foregroundColor: slot.hasPartner
            ? ColorTokens.accentGold
            : colors.textSecondary,
        side: BorderSide(
          color: slot.hasPartner
              ? ColorTokens.accentGold
              : colors.textSecondary.withValues(alpha: 0.4),
        ),
        textStyle: TextStyle(fontSize: compact ? 12 : 14, fontWeight: FontWeight.w600),
      ),
      onPressed: () => ref.read(lobbyProvider.notifier).togglePartner(slot.playerId),
      child: const Text('Partner'),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.textSecondary.withValues(alpha: 0.2),
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Settings',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: LayoutTokens.gr3),
          // Format
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child:                   Text('Format',
                      style: TextStyle(color: colors.textSecondary, fontSize: FontTokens.label)),
              ),
              SizedBox(width: LayoutTokens.gr2),
              Expanded(
                child: _FormatToggle(
                  current: config.format,
                  onChanged: (f) => notifier.updateConfig(config.copyWith(format: f)),
                ),
              ),
            ],
          ),
          SizedBox(height: LayoutTokens.gr3),
          // Starting life — quick-select 20, 25, 30, 40, 60, Custom
          _StartingLifeRow(
            value: config.startingLife,
            onChanged: (v) =>
                notifier.updateConfig(config.copyWith(startingLife: v)),
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

class _FormatToggle extends StatelessWidget {
  final GameFormat current;
  final void Function(GameFormat) onChanged;
  const _FormatToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FormatButton(
            label: 'Commander',
            selected: current == GameFormat.commander,
            onTap: () => onChanged(GameFormat.commander),
          ),
        ),
        SizedBox(width: LayoutTokens.gr2),
        Expanded(
          child: _FormatButton(
            label: 'Standard',
            selected: current == GameFormat.standard,
            onTap: () => onChanged(GameFormat.standard),
          ),
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const _radius = 999.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return Material(
      color: selected ? colors.primaryAccent : colors.surface,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: colors.textSecondary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: FontTokens.label,
              color: selected ? Colors.white : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── Starting life quick-select: 20, 25, 30, 40, 60, Custom ───────────────────

class _StartingLifeRow extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const _StartingLifeRow({required this.value, required this.onChanged});

  static const _presets = [20, 30, 40];

  List<Widget> _buildChips(BuildContext context) => [
    ..._presets.map((v) => _LifeChip(
          value: v,
          selected: value == v,
          onTap: () => onChanged(v),
        )),
    _LifeChip(
      value: value,
      selected: !_presets.contains(value),
      isCustom: true,
      onTap: () => _showCustomDialog(context),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertical = constraints.maxWidth < 280;
        final chips = Wrap(
          spacing: LayoutTokens.gr2,
          runSpacing: LayoutTokens.gr2,
          alignment: WrapAlignment.end,
          children: _buildChips(context),
        );
        return stackVertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Starting Life',
                      style: TextStyle(color: colors.textSecondary, fontSize: FontTokens.label)),
                  SizedBox(height: LayoutTokens.gr2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: chips,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text('Starting Life',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  ),
                  SizedBox(width: LayoutTokens.gr2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: chips,
                    ),
                  ),
                ],
              );
      },
    );
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = AppColorTokens.of(ctx);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Custom Starting Life',
              style: TextStyle(color: colors.textPrimary)),
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
            child: Text('Cancel',
                style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v >= 1 && v <= 999) {
                onChanged(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          ),
        ],
        );
      },
    );
  }
}

class _LifeChip extends StatelessWidget {
  final int value;
  final bool selected;
  final bool isCustom;
  final VoidCallback onTap;

  const _LifeChip({
    required this.value,
    required this.selected,
    this.isCustom = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final label = isCustom ? '+' : '$value';
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: selected ? colors.primaryAccent : colors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? colors.primaryAccent
                    : colors.textSecondary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isCustom ? FontTokens.headline : FontTokens.sm,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : (isCustom ? colors.textSecondary : colors.textPrimary),
              ),
            ),
          ),
        ),
      ),
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
          subtitle: 'Tracks turn durations',
          value: config.trackTurnDuration,
          onChanged: (v) =>
              notifier.updateConfig(config.copyWith(trackTurnDuration: v)),
        ),
        _TurnTimeLimitTile(config: config, notifier: notifier),
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
        borderRadius: BorderRadius.circular(12),
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
        activeTrackColor: colors.primaryAccent.withValues(alpha: 0.5),
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

class _TimerChip extends StatelessWidget {
  final String label;
  final int? value;
  final bool selected;
  final VoidCallback onTap;

  const _TimerChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: selected ? colors.primaryAccent : colors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? colors.primaryAccent
                    : colors.textSecondary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: FontTokens.sm,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnTimeLimitTile extends StatelessWidget {
  final LobbyConfig config;
  final LobbyNotifier notifier;

  const _TurnTimeLimitTile({required this.config, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final limit = config.turnTimeLimitSeconds;
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackVertical = constraints.maxWidth < 320;
          final chips = Wrap(
            spacing: LayoutTokens.gr1,
            runSpacing: LayoutTokens.gr1,
            alignment: WrapAlignment.end,
            children: [
              _TimerChip(
                label: 'Off',
                value: null,
                selected: limit == null,
                onTap: () => notifier.updateConfig(
                    config.copyWith(turnTimeLimitSeconds: null)),
              ),
              _TimerChip(
                label: '30s',
                value: 30,
                selected: limit == 30,
                onTap: () => notifier.updateConfig(
                    config.copyWith(turnTimeLimitSeconds: 30)),
              ),
              _TimerChip(
                label: '60s',
                value: 60,
                selected: limit == 60,
                onTap: () => notifier.updateConfig(
                    config.copyWith(turnTimeLimitSeconds: 60)),
              ),
            ],
          );
          return stackVertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turn time limit',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FontTokens.title,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      limit != null ? '${limit}s per turn' : 'No timer',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FontTokens.caption,
                      ),
                    ),
                    SizedBox(height: LayoutTokens.gr2),
                    chips,
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Turn time limit',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            limit != null ? '${limit}s per turn' : 'No timer',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    chips,
                  ],
                );
        },
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
        disabledBackgroundColor: colors.textSecondary.withValues(alpha: 0.3),
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
                color: Colors.white,
              ),
            )
          : Text(
              widget.canStart ? 'Start Game' : widget.hint,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.sizeOf(context).width < 360 ? FontTokens.title : FontTokens.bodyLg,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
    );
  }
}
