import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AllianceUiEventKind {
  inviteReceived,
  allianceFormed,
  allianceDeclined,
  allianceRevealed,
  allianceBroken,
}

class AllianceUiEvent {
  final AllianceUiEventKind kind;
  final String? allyUsername;
  final String? otherUsername;
  final String? durationLabel;
  final bool betrayal;

  const AllianceUiEvent({
    required this.kind,
    this.allyUsername,
    this.otherUsername,
    this.durationLabel,
    this.betrayal = false,
  });
}

final allianceUiEventProvider =
    StateProvider<AllianceUiEvent?>((ref) => null);
