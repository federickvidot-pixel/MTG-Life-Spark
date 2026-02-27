/// The 12 steps of a Magic: The Gathering turn in order.
enum GamePhase {
  untap,
  upkeep,
  draw,
  preCombatMain,
  beginningOfCombat,
  declareAttackers,
  declareBlockers,
  combatDamage,
  endOfCombat,
  postCombatMain,
  endStep,
  cleanup,
}

extension GamePhaseX on GamePhase {
  String get displayName => switch (this) {
        GamePhase.untap => 'Untap',
        GamePhase.upkeep => 'Upkeep',
        GamePhase.draw => 'Draw',
        GamePhase.preCombatMain => 'Main 1',
        GamePhase.beginningOfCombat => 'Begin Combat',
        GamePhase.declareAttackers => 'Attackers',
        GamePhase.declareBlockers => 'Blockers',
        GamePhase.combatDamage => 'Combat Damage',
        GamePhase.endOfCombat => 'End Combat',
        GamePhase.postCombatMain => 'Main 2',
        GamePhase.endStep => 'End Step',
        GamePhase.cleanup => 'Cleanup',
      };

  String get shortName => switch (this) {
        GamePhase.untap => 'Untap',
        GamePhase.upkeep => 'Upkeep',
        GamePhase.draw => 'Draw',
        GamePhase.preCombatMain => 'M1',
        GamePhase.beginningOfCombat => 'BCombat',
        GamePhase.declareAttackers => 'Attack',
        GamePhase.declareBlockers => 'Block',
        GamePhase.combatDamage => 'Damage',
        GamePhase.endOfCombat => 'ECombat',
        GamePhase.postCombatMain => 'M2',
        GamePhase.endStep => 'End',
        GamePhase.cleanup => 'Clean',
      };

  /// Untap and Cleanup auto-advance without player priority.
  bool get autoAdvance =>
      this == GamePhase.untap || this == GamePhase.cleanup;

  bool get isCombatPhase =>
      index >= GamePhase.beginningOfCombat.index &&
      index <= GamePhase.endOfCombat.index;

  bool get isMainPhase =>
      this == GamePhase.preCombatMain || this == GamePhase.postCombatMain;

  GamePhase get next {
    final phases = GamePhase.values;
    return phases[(index + 1) % phases.length];
  }

  GamePhase get previous {
    final phases = GamePhase.values;
    return phases[(index - 1 + phases.length) % phases.length];
  }

  bool get isFinalPhase => this == GamePhase.cleanup;

  int get stepNumber => index + 1;
}
