import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_chunker.dart';
import 'ble_message.dart';
import 'ble_protocol.dart';
import 'ble_service.dart';

/// Central (client) role — scans for the host, connects, performs handshake.
class BleClientService implements BleService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final _messageController = StreamController<BleMessage>.broadcast();
  final _connectionController = StreamController<BleConnectionEvent>.broadcast();
  final _reassembler = BleReassembler();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  String? _hostDeviceId;
  int _seqNum = 0;
  bool _ready = false;

  final String localPlayerId;
  final String localUsername;

  BleClientService({required this.localPlayerId, required this.localUsername});

  @override
  Stream<BleMessage> get messageStream => _messageController.stream;

  @override
  Stream<BleConnectionEvent> get connectionStream =>
      _connectionController.stream;

  @override
  List<String> get connectedPlayerIds =>
      _hostDeviceId != null ? [_hostDeviceId!] : [];

  @override
  bool get isReady => _ready;

  // ── Scanning ───────────────────────────────────────────────────────────────

  /// Starts scanning for a host advertising [kBleServiceUuid].
  /// Returns a stream of discovered host device IDs (for the lobby scan UI).
  Stream<DiscoveredDevice> scanForHosts() {
    return _ble.scanForDevices(
      withServices: [kBleServiceUuid],
      scanMode: ScanMode.lowLatency,
    );
  }

  // ── Connecting ────────────────────────────────────────────────────────────

  Future<void> connectToHost(String deviceId) async {
    _hostDeviceId = deviceId;

    _connectionSub = _ble
        .connectToDevice(
          id: deviceId,
          servicesWithCharacteristicsToDiscover: {
            kBleServiceUuid: [kBleTxCharUuid, kBleRxCharUuid],
          },
        )
        .listen(_onConnectionStateUpdate, onError: _onConnectionError);
  }

  void _onConnectionStateUpdate(ConnectionStateUpdate update) {
    if (update.connectionState == DeviceConnectionState.connected) {
      _subscribeToTx(update.deviceId);
      _performHandshake(update.deviceId);
    } else if (update.connectionState == DeviceConnectionState.disconnected) {
      _ready = false;
      _connectionController.add(BleConnectionEvent(
        playerId: update.deviceId,
        status: BleConnectionStatus.disconnected,
      ));
    }
  }

  void _onConnectionError(Object error) {
    _connectionController.add(BleConnectionEvent(
      playerId: _hostDeviceId ?? '',
      status: BleConnectionStatus.error,
      errorMessage: error.toString(),
    ));
  }

  void _subscribeToTx(String deviceId) {
    final txChar = QualifiedCharacteristic(
      serviceId: kBleServiceUuid,
      characteristicId: kBleTxCharUuid,
      deviceId: deviceId,
    );

    _notifySub = _ble.subscribeToCharacteristic(txChar).listen(
      (bytes) => _onBytesReceived(bytes, deviceId),
      onError: (e) => _connectionController.add(BleConnectionEvent(
        playerId: deviceId,
        status: BleConnectionStatus.error,
        errorMessage: e.toString(),
      )),
    );
  }

  void _onBytesReceived(List<int> bytes, String deviceId) {
    final fragment = BleFragment.fromBytes(bytes);
    if (fragment == null) return;

    final message = _reassembler.addFragment(fragment);
    if (message == null) return;

    if (message.type == BleMessageType.reject) {
      final required = message.payload['requiredVersion'] as String? ?? '';
      _ready = false;
      _connectionController.add(BleConnectionEvent(
        playerId: deviceId,
        status: BleConnectionStatus.rejected,
        errorMessage: 'Version mismatch. Required: $required',
      ));
      return;
    }

    if (message.type == BleMessageType.hello) {
      // Host acknowledged our hello — we are connected
      _ready = true;
      _connectionController.add(BleConnectionEvent(
        playerId: deviceId,
        status: BleConnectionStatus.connected,
      ));
      return;
    }

    _messageController.add(message);
  }

  // ── Handshake ─────────────────────────────────────────────────────────────

  Future<void> _performHandshake(String deviceId) async {
    await send(BleMessage.hello(_nextSeq()));
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  @override
  Future<void> send(BleMessage message, {String? targetPlayerId}) async {
    if (_hostDeviceId == null) return;

    final rxChar = QualifiedCharacteristic(
      serviceId: kBleServiceUuid,
      characteristicId: kBleRxCharUuid,
      deviceId: _hostDeviceId!,
    );

    final chunker = BleChunker(mtu: kDefaultMtu);
    final fragments = chunker.chunk(message);

    for (final fragment in fragments) {
      await _ble.writeCharacteristicWithResponse(rxChar, value: fragment.toBytes());
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    // flutter_reactive_ble initialises lazily; nothing needed here.
  }

  @override
  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connectionSub?.cancel();
    await _messageController.close();
    await _connectionController.close();
    _reassembler.clear();
    _ready = false;
  }

  int _nextSeq() => _seqNum++;
}
