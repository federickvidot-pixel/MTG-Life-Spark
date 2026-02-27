import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/bluetooth/ble_providers.dart';
import '../../core/bluetooth/ble_service.dart';
import '../../core/game/lobby_state.dart';
import '../../core/models/player_slot.dart';
import '../../core/network/ws_client_service.dart';
import '../../core/persistence/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_router.dart';

enum _JoinPhase { scanning, connecting, waitingRoom }

class JoinScanScreen extends ConsumerStatefulWidget {
  const JoinScanScreen({super.key});

  @override
  ConsumerState<JoinScanScreen> createState() => _JoinScanScreenState();
}

class _JoinScanScreenState extends ConsumerState<JoinScanScreen> {
  _JoinPhase _phase = _JoinPhase.scanning;
  bool _cameraPermissionGranted = false;
  bool _scanned = false;

  StreamSubscription<BleConnectionEvent>? _connectionSub;
  MobileScannerController? _scannerController;

  WsClientService? get _client {
    final svc = ref.read(bleServiceProvider);
    return svc is WsClientService ? svc : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _scannerController?.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() => _cameraPermissionGranted = true);
      await startClientSession(ref);
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      setState(() {}); // rebuild to show scanner
    } else {
      _showSnackbar('Camera permission is required to scan the host QR code.',
          isError: true);
    }
  }

  // ── QR code handling ──────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || _phase != _JoinPhase.scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;

    // Expected format: mgtlifespark://<ip>:<port>
    if (!raw.startsWith('mgtlifespark://')) {
      _showSnackbar('Not a valid MGT Life Spark QR code.', isError: true);
      return;
    }

    _scanned = true;
    _scannerController?.stop();

    final wsUri = raw.replaceFirst('mgtlifespark://', 'ws://');
    _connectTo(wsUri);
  }

  // ── Connection ────────────────────────────────────────────────────────────

  Future<void> _connectTo(String wsUri) async {
    setState(() => _phase = _JoinPhase.connecting);

    final client = _client;
    if (client == null) return;

    _connectionSub = ref
        .read(bleServiceProvider)!
        .connectionStream
        .listen(_onConnectionEvent);

    await client.connectToHost(wsUri);
  }

  void _onConnectionEvent(BleConnectionEvent event) {
    if (!mounted) return;
    switch (event.status) {
      case BleConnectionStatus.connected:
        ref.read(lobbyProvider.notifier).initAsClient();
        setState(() => _phase = _JoinPhase.waitingRoom);

      case BleConnectionStatus.rejected:
        _showSnackbar(
          event.errorMessage ?? 'Host rejected connection (version mismatch).',
          isError: true,
        );
        _resetToScan();

      case BleConnectionStatus.disconnected:
        if (_phase == _JoinPhase.waitingRoom) {
          _showSnackbar('Disconnected from host.');
          _resetToScan();
        }

      case BleConnectionStatus.error:
        _showSnackbar(event.errorMessage ?? 'Connection error.', isError: true);
        _resetToScan();

      default:
        break;
    }
  }

  void _resetToScan() {
    setState(() {
      _phase = _JoinPhase.scanning;
      _scanned = false;
    });
    _scannerController?.start();
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.surface,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Join a Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await endSession(ref);
            if (context.mounted) context.go(AppRoutes.home);
          },
        ),
      ),
      body: switch (_phase) {
        _JoinPhase.scanning => _cameraPermissionGranted &&
                _scannerController != null
            ? _QrScanView(
                controller: _scannerController!,
                onDetect: _onDetect,
              )
            : const _PermissionDeniedView(),
        _JoinPhase.connecting => const _ConnectingView(),
        _JoinPhase.waitingRoom => const _WaitingRoomView(),
      },
    );
  }
}

// ── QR scan view ──────────────────────────────────────────────────────────

class _QrScanView extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  const _QrScanView({required this.controller, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(controller: controller, onDetect: onDetect),
        // Overlay with cut-out guide
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accent, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: const Text(
            'Point the camera at the host\'s QR code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Camera permission denied.\nGo to Settings → App → Permissions to enable.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Connecting view ───────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.accent),
          SizedBox(height: 20),
          Text(
            'Connecting to host…',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── Waiting room ──────────────────────────────────────────────────────────

class _WaitingRoomView extends ConsumerStatefulWidget {
  const _WaitingRoomView();

  @override
  ConsumerState<_WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends ConsumerState<_WaitingRoomView> {
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<LobbyState>(lobbyProvider, (previous, next) {
      if (next.isGameStarted && !(previous?.isGameStarted ?? false)) {
        context.go(AppRoutes.game);
      }
    });

    final lobby = ref.watch(lobbyProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Waiting for host to start…',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...lobby.players.map((slot) => _WaitingSlotRow(slot: slot)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.style),
                label: const Text('Select Commander'),
                onPressed: () {
                  final profile =
                      ref.read(profileRepositoryProvider).getProfile();
                  if (profile == null) return;
                  context.push(AppRoutes.commanderSelect, extra: {
                    'playerId': profile.username,
                    'hasPartner': lobby.players
                        .firstWhere(
                          (p) => p.playerId == profile.username,
                          orElse: () => lobby.players.first,
                        )
                        .hasPartner,
                  });
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isReady ? AppTheme.success : AppTheme.accent,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  setState(() => _isReady = !_isReady);
                  ref
                      .read(lobbyProvider.notifier)
                      .sendReadyToHost(ready: _isReady);
                },
                child: Text(
                  _isReady ? 'Ready! (tap to cancel)' : 'Mark as Ready',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaitingSlotRow extends StatelessWidget {
  final PlayerSlot slot;
  const _WaitingSlotRow({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (slot.commanderImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: slot.commanderImageUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _dot(slot.playerColor),
              ),
            )
          else
            _dot(slot.playerColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.username,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
                if (slot.commanderName != null)
                  Text(slot.commanderName!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (slot.isReady ? AppTheme.success : AppTheme.textSecondary)
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: slot.isReady
                      ? AppTheme.success
                      : AppTheme.textSecondary),
            ),
            child: Text(
              slot.isReady ? 'Ready' : 'Waiting',
              style: TextStyle(
                color: slot.isReady
                    ? AppTheme.success
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Icon(Icons.person, color: color, size: 20),
      );
}
