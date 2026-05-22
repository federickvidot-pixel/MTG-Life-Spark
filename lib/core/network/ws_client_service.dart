import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../bluetooth/ble_message.dart';
import '../bluetooth/ble_protocol.dart';
import '../bluetooth/ble_service.dart';

/// WebSocket-based client service.
///
/// Connects to the host's WebSocket server at the URI encoded in the QR code
/// (`ws://<host-ip>:<port>`), performs the same version handshake as before,
/// then sends / receives [BleMessage] JSON frames.
class WsClientService implements BleService {
  final _messageController = StreamController<BleMessage>.broadcast();
  final _connectionController = StreamController<BleConnectionEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  String? _hostUri;
  int _seqNum = 0;
  bool _ready = false;

  final String localPlayerId;
  final String localUsername;

  WsClientService({required this.localPlayerId, required this.localUsername});

  @override
  Stream<BleMessage> get messageStream => _messageController.stream;

  @override
  Stream<BleConnectionEvent> get connectionStream =>
      _connectionController.stream;

  /// Clients only connect to the host; peer player IDs are not tracked here.
  @override
  List<String> get connectedPlayerIds => const [];

  @override
  bool get isReady => _ready;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    // Nothing to do until connectToHost is called.
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _ready = false;
    await _messageController.close();
    await _connectionController.close();
  }

  // ── Connection ────────────────────────────────────────────────────────────

  /// Connects to the WebSocket server at [wsUri] (e.g. `ws://192.168.1.5:27315`).
  Future<void> connectToHost(String wsUri) async {
    _hostUri = wsUri;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUri));

      // WebSocketChannel.connect is synchronous; we need to await the ready
      // future to detect immediate failures (e.g. connection refused).
      await _channel!.ready;

      _sub = _channel!.stream.listen(
        _onData,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: false,
      );

      // Kick off handshake
      _sendRaw(BleMessage.hello(_nextSeq()));
    } catch (e) {
      _connectionController.add(BleConnectionEvent(
        playerId: wsUri,
        status: BleConnectionStatus.error,
        errorMessage: 'Cannot reach host: $e',
      ));
    }
  }

  // ── Incoming data ─────────────────────────────────────────────────────────

  void _onData(dynamic data) {
    if (data is! String) return;
    BleMessage message;
    try {
      message = BleMessage.fromJson(
        jsonDecode(data) as Map<String, dynamic>,
      );
    } catch (_) {
      return;
    }

    if (message.type == BleMessageType.reject) {
      _ready = false;
      _connectionController.add(BleConnectionEvent(
        playerId: _hostUri ?? '',
        status: BleConnectionStatus.rejected,
        errorMessage:
            'Protocol version mismatch. Required: ${message.payload['requiredVersion']}',
      ));
      return;
    }

    if (message.type == BleMessageType.hello) {
      // Host acknowledged → send join announcement, mark ready
      _ready = true;
      _sendRaw(BleMessage(
        type: BleMessageType.lobbyPlayerJoined,
        payload: {
          'pid': localPlayerId,
          'username': localUsername,
        },
        seqNum: _nextSeq(),
      ));
      _connectionController.add(BleConnectionEvent(
        playerId: _hostUri ?? '',
        status: BleConnectionStatus.connected,
      ));
      return;
    }

    _messageController.add(message);
  }

  void _onDone() {
    _ready = false;
    _connectionController.add(BleConnectionEvent(
      playerId: _hostUri ?? '',
      status: BleConnectionStatus.disconnected,
    ));
  }

  void _onError(Object error) {
    _ready = false;
    _connectionController.add(BleConnectionEvent(
      playerId: _hostUri ?? '',
      status: BleConnectionStatus.error,
      errorMessage: error.toString(),
    ));
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  @override
  Future<void> send(BleMessage message, {String? targetPlayerId}) async {
    _sendRaw(message);
  }

  void _sendRaw(BleMessage message) {
    try {
      _channel?.sink.add(jsonEncode(message.toJson()));
    } catch (_) {}
  }

  int _nextSeq() => _seqNum++;
}
