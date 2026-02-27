import 'ble_message.dart';

enum BleConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  rejected, // protocol version mismatch
  error,
}

class BleConnectionEvent {
  final String playerId;
  final BleConnectionStatus status;
  final String? errorMessage;

  const BleConnectionEvent({
    required this.playerId,
    required this.status,
    this.errorMessage,
  });
}

/// Abstract contract for both host and client BLE roles.
/// Swap implementations for tests (mock) or production (native GATT).
abstract class BleService {
  /// Stream of messages received from the network.
  Stream<BleMessage> get messageStream;

  /// Stream of connection state changes (player joined / dropped / rejected).
  Stream<BleConnectionEvent> get connectionStream;

  /// Ordered list of currently connected player IDs.
  List<String> get connectedPlayerIds;

  bool get isReady;

  Future<void> initialize();

  Future<void> dispose();

  /// Send a message. [targetPlayerId] = null broadcasts to all.
  Future<void> send(BleMessage message, {String? targetPlayerId});
}
