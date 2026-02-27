class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String icon;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class AchievementDefinitions {
  AchievementDefinitions._();

  static const all = <AchievementDef>[
    // Wins
    AchievementDef(
      id: 'first_win',
      title: 'First Blood',
      description: 'Win your first game.',
      icon: '⚔️',
    ),
    AchievementDef(
      id: 'win_streak_3',
      title: 'On a Roll',
      description: 'Win 3 games in a row.',
      icon: '🔥',
    ),
    AchievementDef(
      id: 'win_streak_5',
      title: 'Unstoppable',
      description: 'Win 5 games in a row.',
      icon: '🏆',
    ),
    // Games played
    AchievementDef(
      id: 'games_10',
      title: 'Regular',
      description: 'Play 10 games.',
      icon: '🎴',
    ),
    AchievementDef(
      id: 'games_50',
      title: 'Veteran',
      description: 'Play 50 games.',
      icon: '🛡️',
    ),
    AchievementDef(
      id: 'games_100',
      title: 'Legend',
      description: 'Play 100 games.',
      icon: '👑',
    ),
    // Poison
    AchievementDef(
      id: 'poison_50',
      title: 'Infectious',
      description: 'Deal 50 poison counters across all games.',
      icon: '☠️',
    ),
    AchievementDef(
      id: 'poison_100',
      title: 'Plague Bearer',
      description: 'Deal 100 poison counters across all games.',
      icon: '🧪',
    ),
    // Commander kills
    AchievementDef(
      id: 'commander_kill_1',
      title: 'Commander Slayer',
      description: 'Eliminate a player with commander damage.',
      icon: '⚡',
    ),
    AchievementDef(
      id: 'commander_kill_5',
      title: 'Warlord',
      description: 'Eliminate 5 players with commander damage.',
      icon: '🗡️',
    ),
    // Commander loyalty
    AchievementDef(
      id: 'same_commander_5',
      title: 'True Champion',
      description: 'Win 5 games with the same commander.',
      icon: '🎖️',
    ),
    // Political
    AchievementDef(
      id: 'alliance_3',
      title: 'Diplomat',
      description: 'Form 3 alliances in a single game.',
      icon: '🤝',
    ),
    // Levels
    AchievementDef(
      id: 'reach_silver',
      title: 'Silver Tongue',
      description: 'Reach Silver tier (Level 11).',
      icon: '🥈',
    ),
    AchievementDef(
      id: 'reach_gold',
      title: 'Golden General',
      description: 'Reach Gold tier (Level 26).',
      icon: '🥇',
    ),
    AchievementDef(
      id: 'reach_diamond',
      title: 'Diamond Mind',
      description: 'Reach Diamond tier (Level 76).',
      icon: '💎',
    ),
  ];

  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
