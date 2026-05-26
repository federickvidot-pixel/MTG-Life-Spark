import 'dart:async';

import 'package:flutter/services.dart';

import 'ble_chunker.dart';
import 'ble_message.dart';
import 'ble_protocol.dart';
import 'ble_service.dart';

/// Peripheral (host) role — advertises the game service, manages connected
/// clients, performs version handshake, and broadcasts game state.
///
/// The GATT server (advertising + characteristic serving) is implemented
/// natively on Android (GattServerPlugin) and iOS (CBPeripheralManager)
/// and bridged here via [MethodChannel] / [EventChannel].
///
/// Native implementation required:
///   Android: android/app/src/main/kotlin/.../GattServerPlugin.kt
///   iOS:     ios/Runner/GattServerPlugin.swift
class BleHostService implements BleService {
  static const _methodChannel = MethodChannel('mgt_life_spark/ble_host');
  static const _eventChannel = EventChannel('mgt_life_spark/ble_host/events');

  final _messageController = StreamController<BleMessage>.broadcast();
  final _connectionController = StreamController<BleConnectionEvent>.broadcast();
  final _reassemblers = <String, BleReassembler>{};

  /// clientDeviceId → verified playerId (after handshake)
  final Map<String, String> _verifiedClients = {};

  StreamSubscription<dynamic>? _eventSub;
  int _seqNum = 0;
  bool _ready = false;

  final String hostPlayerId;
  final String hostUsername;

  BleHostService({required this.hostPlayerId, required this.hostUsername});

  @override
  Stream<BleMessage> get messageStream => _messageController.stream;

  @override
  Stream<BleConnectionEvent> get connectionStream =>
      _connectionController.stream;

  @override
  List<String> get connectedPlayerIds => _verifiedClients.values.toList();

  @override
  bool get isReady => _ready;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    // Subscribe to native events (client connected, data received, etc.)
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (e) => _connectionController.add(BleConnectionEvent(
        playerId: '',
        status: BleConnectionStatus.error,
        errorMessage: e.toString(),
      )),
    );

    try {
      await _methodChannel.invokeMethod('startServer', {
        'serviceUuid': kBleServiceUuid.toString(),
        'txCharUuid': kBleTxCharUuid.toString(),
        'rxCharUuid': kBleRxCharUuid.toString(),
        'localName': 'MTG Life Spark',
      });
      _ready = true;
    } on PlatformException catch (e) {
      _connectionController.add(BleConnectionEvent(
        playerId: '',
        status: BleConnectionStatus.error,
        errorMessage: 'Failed to start GATT server: ${e.message}',
      ));
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _methodChannel.invokeMethod('stopServer');
    } catch (_) {}
    await _eventSub?.cancel();
    await _messageController.close();
    await _connectionController.close();
    _reassemblers.clear();
    _verifiedClients.clear();
    _ready = false;
  }

  // ── Native event handling ─────────────────────────────────────────────────

  void _onNativeEvent(dynamic event) {
    if (event is! Map) return;
    final type = event['type'] as String?;

    switch (type) {
      case 'clientConnected':
        final deviceId = event['deviceId'] as String;
        _reassemblers[deviceId] = BleReassembler();
        // Wait for HELLO message; don't mark connected yet.
        break;

      case 'clientDisconnected':
        final deviceId = event['deviceId'] as String;
        final playerId = _verifiedClients.remove(deviceId);
        _reassemblers.remove(deviceId);
        if (playerId != null) {
          _connectionController.add(BleConnectionEvent(
            playerId: playerId,
            status: BleConnectionStatus.disconnected,
          ));
          _broadcastExcept(
            BleMessage(
              type: BleMessageType.playerDisconnected,
              payload: {'pid': playerId},
              seqNum: _nextSeq(),
            ),
            excludeDeviceId: deviceId,
          );
        }
        break;

      case 'dataReceived':
        final deviceId = event['deviceId'] as String;
        final bytes = List<int>.from(event['data'] as List);
        _onBytesFromClient(bytes, deviceId);
        break;
    }
  }

  void _onBytesFromClient(List<int> bytes, String deviceId) {
    final reassembler =
        _reassemblers.putIfAbsent(deviceId, () => BleReassembler());
    final fragment = BleFragment.fromBytes(bytes);
    if (fragment == null) return;

    final message = reassembler.addFragment(fragment);
    if (message == null) return;

    _handleClientMessage(message, deviceId);
  }

  void _handleClientMessage(BleMessage message, String clientDeviceId) {
    if (message.type == BleMessageType.hello) {
      final version = message.payload['version'] as String?;
      if (version != kBleProtocolVersion) {
        _sendToDevice(
          BleMessage.reject(_nextSeq()),
          clientDeviceId,
        );
        return;
      }
      // Acknowledge; the lobby PLAYER_JOINED flow sets the playerId.
      _sendToDevice(BleMessage.hello(_nextSeq()), clientDeviceId);
      return;
    }

    if (message.type == BleMessageType.lobbyPlayerJoined) {
      final playerId = message.payload['pid'] as String? ?? clientDeviceId;
      _verifiedClients[clientDeviceId] = playerId;
      _connectionController.add(BleConnectionEvent(
        playerId: playerId,
        status: BleConnectionStatus.connected,
      ));
    }

    // All other messages: route to GameStateNotifier via messageStream.
    _messageController.add(message);
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  @override
  Future<void> send(BleMessage message, {String? targetPlayerId}) async {
    if (targetPlayerId == null) {
      await _broadcastToAll(message);
    } else {
      final deviceId = _deviceIdFor(targetPlayerId);
      if (deviceId != null) {
        await _sendToDevice(message, deviceId);
      }
    }
  }

  Future<void> _broadcastToAll(BleMessage message) async {
    final chunker = BleChunker(mtu: kDefaultMtu);
    final fragments = chunker.chunk(message);
    for (final deviceId in _verifiedClients.keys) {
      for (final fragment in fragments) {
        await _sendFragmentToDevice(fragment, deviceId);
      }
    }
  }

  Future<void> _broadcastExcept(
    BleMessage message, {
    required String excludeDeviceId,
  }) async {
    final chunker = BleChunker(mtu: kDefaultMtu);
    final fragments = chunker.chunk(message);
    for (final entry in _verifiedClients.entries) {
      if (entry.key == excludeDeviceId) continue;
      for (final fragment in fragments) {
        await _sendFragmentToDevice(fragment, entry.key);
      }
    }
  }

  Future<void> _sendToDevice(BleMessage message, String deviceId) async {
    final chunker = BleChunker(mtu: kDefaultMtu);
    final fragments = chunker.chunk(message);
    for (final fragment in fragments) {
      await _sendFragmentToDevice(fragment, deviceId);
    }
  }

  Future<void> _sendFragmentToDevice(
    BleFragment fragment,
    String deviceId,
  ) async {
    try {
      await _methodChannel.invokeMethod('notifyClient', {
        'deviceId': deviceId,
        'data': fragment.toBytes(),
      });
    } on PlatformException {
      // Client may have dropped mid-send; disconnection event will handle it.
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  String? _deviceIdFor(String playerId) {
    for (final entry in _verifiedClients.entries) {
      if (entry.value == playerId) return entry.key;
    }
    return null;
  }

  int _nextSeq() => _seqNum++;
}
