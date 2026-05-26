import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Bumped on any breaking change to the message format.
/// Host rejects clients on mismatch with a REJECT message.
const kBleProtocolVersion = '1.0';

/// Custom GATT service UUID for MGT Life Spark.
final kBleServiceUuid = Uuid.parse('19B10000-E8F2-537E-4F6C-D104768A1214');

/// TX characteristic: host → clients (NOTIFY).
/// Clients subscribe to this to receive broadcasts.
final kBleTxCharUuid = Uuid.parse('19B10001-E8F2-537E-4F6C-D104768A1214');

/// RX characteristic: clients → host (WRITE).
/// Host reads incoming actions from clients here.
final kBleRxCharUuid = Uuid.parse('19B10002-E8F2-537E-4F6C-D104768A1214');

/// Maximum BLE NOTIFY payload before chunking kicks in (conservative default).
/// Negotiated MTU at runtime may allow larger; this is the safe fallback.
const kDefaultMtu = 185;

/// Legacy BLE constant (undo depth is no longer capped in app logic).
const kUndoStackDepth = 5;

/// Reconnection window in seconds after a client drops.
const kReconnectWindowSeconds = 60;

enum BleMessageType {
  // Handshake
  hello,
  reject,

  // Game lifecycle
  gameStart,
  gameEnd,
  stateSnapshot,

  // Game state
  stateDelta,
  commanderDamage,
  commanderCastFromZone,
  undoAction,
  proliferate,

  // Turn & phase
  phaseAdvance,
  turnEnd,
  priorityHold,
  priorityRelease,
  timeoutStart,
  timeoutEnd,

  // Political
  alliancePropose,
  allianceRespond,
  allianceBreak,
  allianceReveal,
  allianceDeclined,
  monarchChange,
  initiativeChange,
  dayNightChange,

  // Lobby
  lobbyRoll,
  lobbyPlayerJoined,
  lobbyPlayerReady,

  // First player roll (at game start)
  firstPlayerRollSubmit,
  firstPlayerTurnOrder,

  // Player events
  concede,
  playerEliminated,
  playerDisconnected,
  reconnectRequest,

  // Rematch
  rematchPropose,
  rematchRespond,
  rematchConfirm,

  // Teams
  teamAssign,

  // Variant modes (Planechase, Archenemy, Bounty)
  variantStateUpdate,

  // Stack tracker
  stackUpdate,
}
