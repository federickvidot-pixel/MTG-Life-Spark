import 'dart:convert';
import 'ble_protocol.dart';

class BleMessage {
  final BleMessageType type;
  final Map<String, dynamic> payload;
  final int seqNum;
  final String? targetPlayerId; // null = broadcast to all

  BleMessage({
    required this.type,
    required this.payload,
    required this.seqNum,
    this.targetPlayerId,
  });

  Map<String, dynamic> toJson() => {
        't': type.name,
        'p': payload,
        'seq': seqNum,
        if (targetPlayerId != null) 'to': targetPlayerId,
      };

  factory BleMessage.fromJson(Map<String, dynamic> json) {
    return BleMessage(
      type: BleMessageType.values.firstWhere(
        (e) => e.name == json['t'],
        orElse: () => BleMessageType.stateDelta,
      ),
      payload: Map<String, dynamic>.from(json['p'] as Map? ?? {}),
      seqNum: (json['seq'] as num?)?.toInt() ?? 0,
      targetPlayerId: json['to'] as String?,
    );
  }

  List<int> toBytes() => utf8.encode(jsonEncode(toJson()));

  static BleMessage fromBytes(List<int> bytes) {
    return BleMessage.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
  }

  // ── Convenience factories ──────────────────────────────────────────────────

  static BleMessage hello(int seqNum) => BleMessage(
        type: BleMessageType.hello,
        payload: {'version': kBleProtocolVersion},
        seqNum: seqNum,
      );

  static BleMessage reject(int seqNum, {String reason = 'versionMismatch'}) =>
      BleMessage(
        type: BleMessageType.reject,
        payload: {'reason': reason, 'requiredVersion': kBleProtocolVersion},
        seqNum: seqNum,
      );

  static BleMessage stateDelta({
    required int seqNum,
    required String playerId,
    required String field, // 'life' | 'poison' | 'energy' | 'experience' | 'rad'
    required int newValue,
    required int delta,
  }) =>
      BleMessage(
        type: BleMessageType.stateDelta,
        payload: {
          'pid': playerId,
          'field': field,
          'val': newValue,
          'delta': delta,
        },
        seqNum: seqNum,
      );

  static BleMessage commanderDamage({
    required int seqNum,
    required String fromPlayerId,
    required int partnerIndex,
    required String toPlayerId,
    required int amount,
    required int lifeAfter,
    required int totalPartnerDamage,
  }) =>
      BleMessage(
        type: BleMessageType.commanderDamage,
        payload: {
          'from': fromPlayerId,
          'pi': partnerIndex,
          'to': toPlayerId,
          'amt': amount,
          'life': lifeAfter,
          'totalDmg': totalPartnerDamage,
        },
        seqNum: seqNum,
      );

  static BleMessage variantStateUpdate({
    required int seqNum,
    int? currentPlanarIndex,
    int? currentSchemeIndex,
    int? currentBountyIndex,
  }) =>
      BleMessage(
        type: BleMessageType.variantStateUpdate,
        payload: {
          if (currentPlanarIndex != null) 'planar': currentPlanarIndex,
          if (currentSchemeIndex != null) 'scheme': currentSchemeIndex,
          if (currentBountyIndex != null) 'bounty': currentBountyIndex,
        },
        seqNum: seqNum,
      );

  static BleMessage playerEliminated({
    required int seqNum,
    required String playerId,
    required String reason, // 'life' | 'poison' | 'commanderDamage' | 'deckEmpty' | 'concede' | 'disconnect'
    String? killedByPlayerId,
  }) =>
      BleMessage(
        type: BleMessageType.playerEliminated,
        payload: {
          'pid': playerId,
          'reason': reason,
          if (killedByPlayerId != null) 'killedBy': killedByPlayerId,
        },
        seqNum: seqNum,
      );
}
