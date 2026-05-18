/// Supported Magic: The Gathering formats for lobby / match configuration.
enum GameFormat {
  // Multiplayer / commander family
  commander,
  duelCommander,
  pauperCommander,
  brawl,
  oathbreaker,
  canadianHighlander,
  archon,

  // Constructed
  standard,
  pioneer,
  modern,
  legacy,
  vintage,
  pauper,
  historic,
  alchemy,
  timeless,
  pennyDreadful,
  premodern,
  oldSchool,
  magic9394,

  // Limited
  boosterDraft,
  sealedDeck,

  // Team / variant
  twoHeadedGiant,
  emperor,

  // Casual / special
  momirBasic,
  hordeMagic,
}

extension GameFormatDetails on GameFormat {
  /// Human-readable label for UI and match history.
  String get displayName => switch (this) {
    GameFormat.commander => 'Commander',
    GameFormat.duelCommander => 'Duel Commander',
    GameFormat.pauperCommander => 'Pauper Commander',
    GameFormat.brawl => 'Brawl',
    GameFormat.oathbreaker => 'Oathbreaker',
    GameFormat.canadianHighlander => 'Canadian Highlander',
    GameFormat.archon => 'Archon',
    GameFormat.standard => 'Standard',
    GameFormat.pioneer => 'Pioneer',
    GameFormat.modern => 'Modern',
    GameFormat.legacy => 'Legacy',
    GameFormat.vintage => 'Vintage',
    GameFormat.pauper => 'Pauper',
    GameFormat.historic => 'Historic',
    GameFormat.alchemy => 'Alchemy',
    GameFormat.timeless => 'Timeless',
    GameFormat.pennyDreadful => 'Penny Dreadful',
    GameFormat.premodern => 'Premodern',
    GameFormat.oldSchool => 'Old School',
    GameFormat.magic9394 => '93/94 Magic',
    GameFormat.boosterDraft => 'Booster Draft',
    GameFormat.sealedDeck => 'Sealed Deck',
    GameFormat.twoHeadedGiant => 'Two-Headed Giant',
    GameFormat.emperor => 'Emperor',
    GameFormat.momirBasic => 'Momir Basic',
    GameFormat.hordeMagic => 'Horde Magic',
  };

  /// Suggested default starting life when picking a format (host can override).
  int get defaultStartingLife => switch (this) {
    GameFormat.commander ||
    GameFormat.duelCommander ||
    GameFormat.pauperCommander ||
    GameFormat.canadianHighlander ||
    GameFormat.archon => 40,
    GameFormat.brawl || GameFormat.oathbreaker => 25,
    GameFormat.twoHeadedGiant => 30,
    GameFormat.standard ||
    GameFormat.pioneer ||
    GameFormat.modern ||
    GameFormat.legacy ||
    GameFormat.vintage ||
    GameFormat.pauper ||
    GameFormat.historic ||
    GameFormat.alchemy ||
    GameFormat.timeless ||
    GameFormat.pennyDreadful ||
    GameFormat.premodern ||
    GameFormat.oldSchool ||
    GameFormat.magic9394 ||
    GameFormat.boosterDraft ||
    GameFormat.sealedDeck ||
    GameFormat.emperor ||
    GameFormat.momirBasic ||
    GameFormat.hordeMagic => 20,
  };

  /// Formats where commander damage / partner selection is typical.
  bool get isCommanderStyle => switch (this) {
    GameFormat.commander ||
    GameFormat.duelCommander ||
    GameFormat.pauperCommander ||
    GameFormat.brawl ||
    GameFormat.oathbreaker ||
    GameFormat.canadianHighlander ||
    GameFormat.archon => true,
    _ => false,
  };

  /// Order shown in the host lobby format dropdown.
  static const List<GameFormat> lobbyPickerOrder = [
    GameFormat.commander,
    GameFormat.duelCommander,
    GameFormat.pauperCommander,
    GameFormat.brawl,
    GameFormat.oathbreaker,
    GameFormat.canadianHighlander,
    GameFormat.archon,
    GameFormat.standard,
    GameFormat.pioneer,
    GameFormat.modern,
    GameFormat.legacy,
    GameFormat.vintage,
    GameFormat.pauper,
    GameFormat.historic,
    GameFormat.alchemy,
    GameFormat.timeless,
    GameFormat.pennyDreadful,
    GameFormat.premodern,
    GameFormat.oldSchool,
    GameFormat.magic9394,
    GameFormat.boosterDraft,
    GameFormat.sealedDeck,
    GameFormat.twoHeadedGiant,
    GameFormat.emperor,
    GameFormat.momirBasic,
    GameFormat.hordeMagic,
  ];

  static GameFormat? fromName(String? name) {
    if (name == null) return null;
    for (final f in GameFormat.values) {
      if (f.name == name) return f;
    }
    return null;
  }
}
