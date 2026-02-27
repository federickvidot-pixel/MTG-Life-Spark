import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/bluetooth/ble_providers.dart';
import '../../core/game/lobby_state.dart';
import '../../core/models/player_slot.dart';
import '../../core/network/local_ip.dart';
import '../../core/network/ws_host_service.dart';
import '../../core/persistence/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_router.dart';
import '../../shared/widgets/game_icon.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.primary,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _QrHeader(qrData: _qrData, playerCount: lobby.players.length),
          const SizedBox(height: 20),
          ...lobby.players.map((slot) => _PlayerSlotCard(slot: slot)),
          if (lobby.players.length < lobby.config.maxPlayers)
            _EmptySlotCard(
              remaining: lobby.config.maxPlayers - lobby.players.length,
            ),
          const SizedBox(height: 24),
          _ConfigSection(config: lobby.config),
          const SizedBox(height: 24),
          _StartGameButton(
            canStart: lobby.canStart,
            hint: lobby.players.isEmpty
                ? 'Need at least 1 player'
                : lobby.players.any((p) => !p.isReady)
                    ? 'Everyone must be ready'
                    : 'Start Game',
          ),
          const SizedBox(height: 32),
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
    return Container(
      width: double.infinity,
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Players joined: $playerCount  •  Scan QR to join',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (qrData == null)
            const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: qrData!,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
          if (qrData != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                qrData!.replaceFirst('mgtlifespark://', ''),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10),
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
    final isLocalHost = ref.watch(
      profileRepositoryProvider.select((r) => r.getProfile()?.username),
    );
    final isMe = slot.playerId == isLocalHost;

    final borderColor = isMe
        ? (slot.isReady ? AppTheme.success : AppTheme.accent)
        : slot.playerColor.withValues(alpha: 0.25);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
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
          _CommanderAvatar(slot: slot),
          const SizedBox(width: 14),
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
                    const SizedBox(width: 6),
                    Text(
                      slot.username,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (slot.isHost) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star,
                          size: 13, color: AppTheme.accentGold),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  slot.commanderName ?? 'No commander selected',
                    style: TextStyle(
                        color: slot.commanderName != null
                        ? AppTheme.textSecondary
                        : AppTheme.accent,
                    fontSize: 12,
                  ),
                ),
                if (slot.hasPartner && slot.partnerCommanderName != null)
                  Text(
                    '+ ${slot.partnerCommanderName}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          // Controls (for own slot: host and clients)
          if (isMe)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PartnerChip(slot: slot),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(95, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: slot.commanderName != null
                        ? AppTheme.accent
                        : Colors.transparent,
                    foregroundColor: slot.commanderName != null
                        ? Colors.white
                        : AppTheme.textSecondary,
                    side: BorderSide(
                      color: slot.commanderName != null
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    ),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(95, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    foregroundColor: slot.isReady
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                    side: BorderSide(
                      color: slot.isReady
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    final notifier = ref.read(lobbyProvider.notifier);
                    notifier.setReady(slot.playerId, ready: !slot.isReady);
                  },
                  child: Text(slot.isReady ? 'Ready' : 'Ready?'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CommanderAvatar extends StatelessWidget {
  final PlayerSlot slot;
  const _CommanderAvatar({required this.slot});

  @override
  Widget build(BuildContext context) {
    if (slot.commanderImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: slot.commanderImageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _ColorDot(color: slot.playerColor),
        ),
      );
    }
    return _ColorDot(color: slot.playerColor);
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(Icons.person, color: color, size: 28),
    );
  }
}

class _PartnerChip extends ConsumerWidget {
  final PlayerSlot slot;
  const _PartnerChip({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(95, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: slot.hasPartner
            ? AppTheme.accentGold.withValues(alpha: 0.15)
            : Colors.transparent,
        foregroundColor: slot.hasPartner
            ? AppTheme.accentGold
            : AppTheme.textSecondary,
        side: BorderSide(
          color: slot.hasPartner
              ? AppTheme.accentGold
              : AppTheme.textSecondary.withValues(alpha: 0.4),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          '$remaining open slot${remaining == 1 ? '' : 's'} — share your device to let friends join',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
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
    final notifier = ref.read(lobbyProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Settings',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          // Format
          Row(
            children: [
              const Icon(Icons.style, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              const Text('Format',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              Expanded(
                child: _FormatToggle(
                  current: config.format,
                  onChanged: (f) => notifier.updateConfig(config.copyWith(format: f)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Starting life — quick-select 20, 25, 30, 40, 60, Custom
          _StartingLifeRow(
            value: config.startingLife,
            onChanged: (v) =>
                notifier.updateConfig(config.copyWith(startingLife: v)),
          ),
          const SizedBox(height: 24),
          // Gameplay settings
          const Text(
            'Gameplay',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
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

  /// 100% rounded (pill shape)
  static const _radius = 999.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: current == GameFormat.commander
                ? AppTheme.accent
                : AppTheme.card,
            borderRadius: BorderRadius.circular(_radius),
            child: InkWell(
              onTap: () => onChanged(GameFormat.commander),
              borderRadius: BorderRadius.circular(_radius),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Commander',
                  style: TextStyle(
                    fontSize: 12,
                    color: current == GameFormat.commander
                        ? Colors.white
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: current == GameFormat.standard
                ? AppTheme.accent
                : AppTheme.card,
            borderRadius: BorderRadius.circular(_radius),
            child: InkWell(
              onTap: () => onChanged(GameFormat.standard),
              borderRadius: BorderRadius.circular(_radius),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Standard',
                  style: TextStyle(
                    fontSize: 12,
                    color: current == GameFormat.standard
                        ? Colors.white
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Starting life quick-select: 20, 25, 30, 40, 60, Custom ───────────────────

class _StartingLifeRow extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const _StartingLifeRow({required this.value, required this.onChanged});

  static const _presets = [20, 25, 30, 40, 60];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.favorite, size: 16, color: AppTheme.accent),
        const SizedBox(width: 8),
        const Text('Starting Life',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
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
            ],
          ),
        ),
      ],
    );
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Custom Starting Life',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter life total (1–999)',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
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
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
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
      ),
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
    final isCustomIcon = isCustom && !selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCustomIcon ? 10 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        child: isCustomIcon
            ? Icon(
                Icons.add,
                size: 20,
                color: AppTheme.textSecondary,
              )
            : Text(
                isCustom ? '$value' : '$value',
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Gameplay',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _GameplaySwitchTile(
          icon: Icons.public,
          title: 'Planechase',
          subtitle: 'Internet required for planar deck',
          value: config.planechaseEnabled,
          onChanged: (v) =>
              notifier.updateConfig(config.copyWith(planechaseEnabled: v)),
        ),
        _GameplaySwitchTile(
          icon: Icons.shield,
          title: 'Archenemy',
          subtitle: 'Internet required for scheme deck',
          value: config.archenemyEnabled,
          onChanged: (v) =>
              notifier.updateConfig(config.copyWith(archenemyEnabled: v)),
        ),
        _GameplaySwitchTile(
          iconWidget: GameIcon.bounty(size: 22, color: AppTheme.textSecondary),
          title: 'Bounty',
          subtitle: 'Internet required for bounty deck',
          value: config.bountyEnabled,
          onChanged: (v) =>
              notifier.updateConfig(config.copyWith(bountyEnabled: v)),
        ),
        _GameplaySwitchTile(
          icon: Icons.cancel_outlined,
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
          icon: Icons.shield_outlined,
          title: 'Commander damage life loss',
          subtitle: 'Commander damage also reduces life',
          value: config.commanderDamageReducesLife,
          onChanged: (v) => notifier.updateConfig(
              config.copyWith(commanderDamageReducesLife: v)),
        ),
        _GameplaySwitchTile(
          icon: Icons.schedule,
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
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GameplaySwitchTile({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: iconWidget ?? (icon != null ? Icon(icon, size: 22, color: AppTheme.textSecondary) : null),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: selected ? AppTheme.accent : AppTheme.card,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppTheme.accent
                    : AppTheme.textSecondary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
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
    final limit = config.turnTimeLimitSeconds;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 22, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Turn time limit',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  limit != null ? '${limit ~/ 60}m per turn' : 'No limit',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimerChip(
                label: 'Off',
                value: null,
                selected: limit == null,
                onTap: () => notifier.updateConfig(
                    config.copyWith(turnTimeLimitSeconds: null)),
              ),
              const SizedBox(width: 8),
              _TimerChip(
                label: '1m',
                value: 60,
                selected: limit == 60,
                onTap: () => notifier.updateConfig(
                    config.copyWith(turnTimeLimitSeconds: 60)),
              ),
              const SizedBox(width: 8),
              _TimerChip(
                label: '2m',
                value: 120,
                selected: limit == 120,
                onTap: () => notifier.updateConfig(
                    config.copyWith(turnTimeLimitSeconds: 120)),
              ),
              const SizedBox(width: 8),
              _TimerChip(
                label: '5m',
                value: 300,
                selected: limit == 300,
                onTap: () => notifier.updateConfig(
                    config.copyWith(turnTimeLimitSeconds: 300)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Start game button ─────────────────────────────────────────────────────

class _StartGameButton extends ConsumerWidget {
  final bool canStart;
  final String hint;
  const _StartGameButton({required this.canStart, required this.hint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: canStart ? AppTheme.success : AppTheme.textSecondary,
        disabledBackgroundColor: AppTheme.textSecondary.withValues(alpha: 0.3),
        minimumSize: const Size(double.infinity, 56),
      ),
      onPressed: canStart
          ? () async {
              await ref.read(lobbyProvider.notifier).broadcastGameStart();
              if (context.mounted) context.go(AppRoutes.game);
            }
          : null,
      child: Text(
        canStart ? 'Start Game' : hint,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
      ),
    );
  }
}
