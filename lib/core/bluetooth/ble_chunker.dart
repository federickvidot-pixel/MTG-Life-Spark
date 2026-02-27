import 'dart:convert';
import 'dart:math';
import 'ble_message.dart';

/// A single BLE transport fragment.
class BleFragment {
  final String msgId;
  final int fragmentIndex;
  final int totalFragments;
  final List<int> payload; // raw bytes of this fragment's data portion

  BleFragment({
    required this.msgId,
    required this.fragmentIndex,
    required this.totalFragments,
    required this.payload,
  });

  List<int> toBytes() {
    final header = utf8.encode(
      '${msgId}_${fragmentIndex}_${totalFragments}_',
    );
    return [...header, ...payload];
  }

  static BleFragment? fromBytes(List<int> bytes) {
    try {
      // Header ends at the 4th underscore-delimited field
      final str = utf8.decode(bytes);
      final headerEnd = _findHeaderEnd(str);
      if (headerEnd == -1) return null;

      final headerStr = str.substring(0, headerEnd);
      final parts = headerStr.split('_');
      if (parts.length < 3) return null;

      final payloadBytes = bytes.sublist(utf8.encode('${headerStr}_').length);
      return BleFragment(
        msgId: parts[0],
        fragmentIndex: int.parse(parts[1]),
        totalFragments: int.parse(parts[2]),
        payload: payloadBytes,
      );
    } catch (_) {
      return null;
    }
  }

  static int _findHeaderEnd(String s) {
    int underscoreCount = 0;
    for (int i = 0; i < s.length; i++) {
      if (s[i] == '_') {
        underscoreCount++;
        if (underscoreCount == 3) return i;
      }
    }
    return -1;
  }
}

/// Splits a [BleMessage] into MTU-sized [BleFragment]s.
class BleChunker {
  final int mtu;

  BleChunker({this.mtu = 185});

  List<BleFragment> chunk(BleMessage message) {
    final fullBytes = message.toBytes();
    final msgId = _generateMsgId();

    // Estimate header overhead: msgId (36) + 3 underscores + index digits (up to 3) + total digits (up to 3) = ~50 bytes
    const headerOverhead = 50;
    final chunkSize = max(1, mtu - headerOverhead);

    final fragments = <BleFragment>[];
    final totalFragments = (fullBytes.length / chunkSize).ceil();

    for (int i = 0; i < totalFragments; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, fullBytes.length);
      fragments.add(BleFragment(
        msgId: msgId,
        fragmentIndex: i,
        totalFragments: totalFragments,
        payload: fullBytes.sublist(start, end),
      ));
    }

    return fragments;
  }

  String _generateMsgId() {
    final rand = Random();
    return List.generate(8, (_) => rand.nextInt(16).toRadixString(16)).join();
  }
}

/// Buffers incoming [BleFragment]s and reassembles them into [BleMessage]s.
class BleReassembler {
  // msgId → list of received fragments (indexed by fragmentIndex)
  final Map<String, List<BleFragment?>> _buffer = {};

  /// Returns a complete [BleMessage] when all fragments have arrived, otherwise null.
  BleMessage? addFragment(BleFragment fragment) {
    final msgId = fragment.msgId;
    final total = fragment.totalFragments;

    _buffer.putIfAbsent(msgId, () => List.filled(total, null));
    _buffer[msgId]![fragment.fragmentIndex] = fragment;

    // Check if all fragments arrived
    final frags = _buffer[msgId]!;
    if (frags.any((f) => f == null)) return null;

    // Reassemble
    final allBytes = frags.expand((f) => f!.payload).toList();
    _buffer.remove(msgId);

    try {
      return BleMessage.fromBytes(allBytes);
    } catch (_) {
      return null;
    }
  }

  void clear() => _buffer.clear();
}
