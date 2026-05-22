import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../bluetooth/ble_message.dart';
import '../bluetooth/ble_protocol.dart';
import '../bluetooth/ble_service.dart';

/// WebSocket-based host service.
///
/// Runs a plain [HttpServer] on a random port and upgrades incoming HTTP
/// connections to WebSocket. Each connected socket maps to one game client.
///
/// Message format: UTF-8 JSON strings (BleMessage.toJson / fromJson).
/// No chunking needed — WiFi MTU is far larger than any game message.
class WsHostService implements BleService {
  final _messageController = StreamController<BleMessage>.broadcast();
  final _connectionController = StreamController<BleConnectionEvent>.broadcast();

  /// clientKey (remote address string) → verified playerId (after handshake)
  final Map<String, String> _verified = {};

  /// clientKey → open WebSocket
  final Map<String, WebSocket> _sockets = {};

  HttpServer? _server;
  int _seqNum = 0;
  int _nextClientId = 0;
  bool _ready = false;

  final String hostPlayerId;
  final String hostUsername;

  WsHostService({required this.hostPlayerId, required this.hostUsername});

  /// Port the server is bound to; available after [initialize].
  int get port => _server?.port ?? 0;

  @override
  Stream<BleMessage> get messageStream => _messageController.stream;

  @override
  Stream<BleConnectionEvent> get connectionStream =>
      _connectionController.stream;

  @override
  List<String> get connectedPlayerIds => _verified.values.toList();

  @override
  bool get isReady => _ready;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    try {
      // Bind to any available port on all IPv4 interfaces
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _ready = true;
      _server!.transform(WebSocketTransformer()).listen(
        _onNewSocket,
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (e) {
      _connectionController.add(BleConnectionEvent(
        playerId: '',
        status: BleConnectionStatus.error,
        errorMessage: 'Failed to start WebSocket server: $e',
      ));
    }
  }

  @override
  Future<void> dispose() async {
    await _server?.close(force: true);
    _server = null;
    for (final ws in _sockets.values) {
      await ws.close();
    }
    _sockets.clear();
    _verified.clear();
    await _messageController.close();
    await _connectionController.close();
    _ready = false;
  }

  // ── Incoming connections ──────────────────────────────────────────────────

  void _onNewSocket(WebSocket ws) {
    final key = '${_nextClientId++}';
    _sockets[key] = ws;

    ws.listen(
      (data) => _onData(data, key),
      onDone: () => _onDisconnect(key),
      onError: (_) => _onDisconnect(key),
      cancelOnError: false,
    );
  }

  void _onData(dynamic data, String key) {
    if (data is! String) return;
    BleMessage message;
    try {
      message = BleMessage.fromJson(
        jsonDecode(data) as Map<String, dynamic>,
      );
    } catch (_) {
      return;
    }
    _handleClientMessage(message, key);
  }

  void _handleClientMessage(BleMessage message, String clientKey) {
    if (message.type == BleMessageType.hello) {
      final version = message.payload['version'] as String?;
      if (version != kBleProtocolVersion) {
        _sendToKey(BleMessage.reject(_nextSeq()), clientKey);
        _sockets[clientKey]?.close();
        _sockets.remove(clientKey);
        return;
      }
      _sendToKey(BleMessage.hello(_nextSeq()), clientKey);
      return;
    }

    if (message.type == BleMessageType.lobbyPlayerJoined) {
      final playerId =
          message.payload['pid'] as String? ?? clientKey;
      _verified[clientKey] = playerId;
      _connectionController.add(BleConnectionEvent(
        playerId: playerId,
        status: BleConnectionStatus.connected,
      ));
    }

    _messageController.add(message);
  }

  void _onDisconnect(String clientKey) {
    _sockets.remove(clientKey);
    final playerId = _verified.remove(clientKey);
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
        excludeKey: clientKey,
      );
    }
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  @override
  Future<void> send(BleMessage message, {String? targetPlayerId}) async {
    final encoded = jsonEncode(message.toJson());
    if (targetPlayerId == null) {
      for (final ws in _sockets.values) {
        _trySend(ws, encoded);
      }
    } else {
      final key = _keyFor(targetPlayerId);
      if (key != null) _trySend(_sockets[key]!, encoded);
    }
  }

  void _sendToKey(BleMessage message, String clientKey) {
    final ws = _sockets[clientKey];
    if (ws != null) _trySend(ws, jsonEncode(message.toJson()));
  }

  void _broadcastExcept(BleMessage message,
      {required String excludeKey}) {
    final encoded = jsonEncode(message.toJson());
    for (final entry in _sockets.entries) {
      if (entry.key != excludeKey) _trySend(entry.value, encoded);
    }
  }

  void _trySend(WebSocket ws, String data) {
    try {
      if (ws.readyState == WebSocket.open) ws.add(data);
    } catch (_) {}
  }

  String? _keyFor(String playerId) {
    for (final entry in _verified.entries) {
      if (entry.value == playerId) return entry.key;
    }
    return null;
  }

  int _nextSeq() => _seqNum++;
}
