import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Debug session logging. POSTs to ingest endpoint; server writes to log file.
void debugLog({
  required String location,
  required String message,
  Map<String, dynamic>? data,
  String? hypothesisId,
}) {
  if (!kDebugMode) return;
  final payload = {
    'sessionId': '62c891',
    'location': location,
    'message': message,
    if (data != null) 'data': data,
    if (hypothesisId != null) 'hypothesisId': hypothesisId,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  unawaited(http
      .post(
    Uri.parse(
        'http://127.0.0.1:7734/ingest/7a36c8a7-64dc-407e-a5f6-835f7b7b1d88'),
    headers: {
      'Content-Type': 'application/json',
      'X-Debug-Session-Id': '62c891',
    },
    body: jsonEncode(payload),
  )
      .catchError((_) {}));
}
