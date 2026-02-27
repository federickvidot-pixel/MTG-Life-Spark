/// One reversible action in a player's undo stack (max depth 5).
class UndoAction {
  /// Player whose state was changed.
  final String playerId;

  /// Which field was changed: 'life' | 'poison' | 'energy' | 'experience' |
  /// 'rad' | 'commanderDamage' | 'commanderCast'
  final String field;

  /// The value *before* this action was applied.
  final int previousValue;

  /// Extra context needed to undo complex operations (e.g. commander damage).
  /// For commanderDamage: {'fromId': String, 'pi': int, 'prevLife': int}
  final Map<String, dynamic>? extra;

  final DateTime timestamp;

  UndoAction({
    required this.playerId,
    required this.field,
    required this.previousValue,
    this.extra,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'field': field,
        'previousValue': previousValue,
        if (extra != null) 'extra': extra,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UndoAction.fromJson(Map<String, dynamic> json) => UndoAction(
        playerId: json['playerId'] as String,
        field: json['field'] as String,
        previousValue: (json['previousValue'] as num).toInt(),
        extra: json['extra'] as Map<String, dynamic>?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
