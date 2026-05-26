import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects device shake gestures via accelerometer (mobile only).
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.shakeThreshold = 14.0,
    this.shakeSlopMs = 500,
    this.shakeCountResetMs = 2000,
  });

  final VoidCallback onShake;
  final double shakeThreshold;
  final int shakeSlopMs;
  final int shakeCountResetMs;

  StreamSubscription<UserAccelerometerEvent>? _sub;
  int _shakeCount = 0;
  DateTime? _lastShakeAt;

  void start() {
    if (kIsWeb) return;
    _sub ??= userAccelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude < shakeThreshold) return;

      final now = DateTime.now();
      if (_lastShakeAt != null &&
          now.difference(_lastShakeAt!) >
              Duration(milliseconds: shakeCountResetMs)) {
        _shakeCount = 0;
      }

      if (_lastShakeAt == null ||
          now.difference(_lastShakeAt!) > Duration(milliseconds: shakeSlopMs)) {
        _shakeCount++;
        _lastShakeAt = now;
      }

      if (_shakeCount >= 2) {
        _shakeCount = 0;
        onShake();
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _shakeCount = 0;
    _lastShakeAt = null;
  }
}
