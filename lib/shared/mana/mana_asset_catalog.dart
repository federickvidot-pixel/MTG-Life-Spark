// ignore_for_file: public_member_api_docs

/// Canonical association between bundled PNG paths (under `assets/mana/`) and Scryfall
/// `mana_cost` tokens. Same logical symbol may have multiple PNGs (e.g. root `W.png` vs `MYB/W.png`).
///
/// Scryfall prints mana as concatenated braced groups, e.g. `{3}{R/W}{R}` — each **inner**
/// string (without `{` `}`) is what we store per token: `3`, `R/W`, `R`.
///
/// Non-mana UI sprites (`Rules Text`, `Adventure`, template toggles) are listed separately;
/// they do not appear in card `mana_cost` JSON from Scryfall.

/// Inner token string(s) for a relative PNG path. Empty if the file is not a mana symbol.
typedef ManaPngAssociation = ({List<String> tokenInners, String? note});

/// Files used for frames / rules / templates — never part of `mana_cost`.
const Set<String> kManaFolderNonManaCostPng = {
  'Rules Text.png',
  'Adventure.png',
  'SymbolsToggle.png',
  'fullManaCost.png',
  'MYB/fullManaCost.png',
  'empty.png',
};

/// Relative path (no `assets/mana/` prefix) → which `{inner}` value(s) use this art.
///
/// **MYB/** folder: alternate art for the same Scryfall tokens as root/hybrid files.
/// **MYB/00.png … MYB/09.png**: alternate art for `{0}` … `{9}` (single-digit generic mana).
const Map<String, ManaPngAssociation> kManaPngToScryfall = {
  // Generic mana {0}–{20}
  '0.png': (tokenInners: ['0'], note: null),
  '1.png': (tokenInners: ['1'], note: null),
  '2.png': (tokenInners: ['2'], note: null),
  '3.png': (tokenInners: ['3'], note: null),
  '4.png': (tokenInners: ['4'], note: null),
  '5.png': (tokenInners: ['5'], note: null),
  '6.png': (tokenInners: ['6'], note: null),
  '7.png': (tokenInners: ['7'], note: null),
  '8.png': (tokenInners: ['8'], note: null),
  '9.png': (tokenInners: ['9'], note: null),
  '10.png': (tokenInners: ['10'], note: null),
  '11.png': (tokenInners: ['11'], note: null),
  '12.png': (tokenInners: ['12'], note: null),
  '13.png': (tokenInners: ['13'], note: null),
  '14.png': (tokenInners: ['14'], note: null),
  '15.png': (tokenInners: ['15'], note: null),
  '16.png': (tokenInners: ['16'], note: null),
  '17.png': (tokenInners: ['17'], note: null),
  '18.png': (tokenInners: ['18'], note: null),
  '19.png': (tokenInners: ['19'], note: null),
  '20.png': (tokenInners: ['20'], note: null),

  // Colored / colorless / snow / energy / tap / variable
  'W.png': (tokenInners: ['W'], note: null),
  'U.png': (tokenInners: ['U'], note: null),
  'B.png': (tokenInners: ['B'], note: null),
  'R.png': (tokenInners: ['R'], note: null),
  'G.png': (tokenInners: ['G'], note: null),
  'C.png': (tokenInners: ['C'], note: 'colorless'),
  'E.png': (tokenInners: ['E'], note: 'energy'),
  'T.png': (tokenInners: ['T'], note: 'tap; rarely in mana_cost'),
  'S.png': (tokenInners: ['S'], note: 'snow'),
  'symbol/mana/X.png': (tokenInners: ['X'], note: null),

  // Phyrexian colored
  'phy/WP.png': (tokenInners: ['W/P', 'P/W'], note: 'Scryfall uses {W/P}'),
  'phy/UP.png': (tokenInners: ['U/P', 'P/U'], note: null),
  'phy/BP.png': (tokenInners: ['B/P', 'P/B'], note: null),
  'phy/RP.png': (tokenInners: ['R/P', 'P/R'], note: null),
  'phy/GP.png': (tokenInners: ['G/P', 'P/G'], note: null),

  // Hybrid & {2/M}
  'hybrid/WU.png': (tokenInners: ['W/U', 'U/W'], note: null),
  'hybrid/WB.png': (tokenInners: ['W/B', 'B/W'], note: null),
  'hybrid/UB.png': (tokenInners: ['U/B', 'B/U'], note: null),
  'hybrid/UR.png': (tokenInners: ['U/R', 'R/U'], note: null),
  'hybrid/BR.png': (tokenInners: ['B/R', 'R/B'], note: null),
  'hybrid/BG.png': (tokenInners: ['B/G', 'G/B'], note: null),
  'hybrid/RG.png': (tokenInners: ['R/G', 'G/R'], note: null),
  'hybrid/RW.png': (tokenInners: ['R/W', 'W/R'], note: null),
  'hybrid/GW.png': (tokenInners: ['G/W', 'W/G'], note: null),
  'hybrid/GU.png': (tokenInners: ['G/U', 'U/G'], note: null),
  'hybrid/CU.png': (tokenInners: ['C/U', 'U/C'], note: null),
  'hybrid/CW.png': (tokenInners: ['C/W', 'W/C'], note: null),
  'hybrid/CB.png': (tokenInners: ['C/B', 'B/C'], note: null),
  'hybrid/CR.png': (tokenInners: ['C/R', 'R/C'], note: null),
  'hybrid/CG.png': (tokenInners: ['C/G', 'G/C'], note: null),
  'hybrid/2W.png': (tokenInners: ['2/W', 'W/2'], note: null),
  'hybrid/2U.png': (tokenInners: ['2/U', 'U/2'], note: null),
  'hybrid/2B.png': (tokenInners: ['2/B', 'B/2'], note: null),
  'hybrid/2R.png': (tokenInners: ['2/R', 'R/2'], note: null),
  'hybrid/2G.png': (tokenInners: ['2/G', 'G/2'], note: null),

  // MYB — same tokens as root, alternate art
  'MYB/W.png': (tokenInners: ['W'], note: 'MYB alt'),
  'MYB/U.png': (tokenInners: ['U'], note: 'MYB alt'),
  'MYB/B.png': (tokenInners: ['B'], note: 'MYB alt'),
  'MYB/R.png': (tokenInners: ['R'], note: 'MYB alt'),
  'MYB/G.png': (tokenInners: ['G'], note: 'MYB alt'),
  'MYB/T.png': (tokenInners: ['T'], note: 'MYB alt'),
  'MYB/00.png': (tokenInners: ['0'], note: 'MYB alt for {0}'),
  'MYB/01.png': (tokenInners: ['1'], note: 'MYB alt for {1}'),
  'MYB/02.png': (tokenInners: ['2'], note: null),
  'MYB/03.png': (tokenInners: ['3'], note: null),
  'MYB/04.png': (tokenInners: ['4'], note: null),
  'MYB/05.png': (tokenInners: ['5'], note: null),
  'MYB/06.png': (tokenInners: ['6'], note: null),
  'MYB/07.png': (tokenInners: ['7'], note: null),
  'MYB/08.png': (tokenInners: ['8'], note: null),
  'MYB/09.png': (tokenInners: ['9'], note: null),

  // Not mana_cost — documented for completeness
  'Rules Text.png': (tokenInners: [], note: 'UI, not mana_cost'),
  'Adventure.png': (tokenInners: [], note: 'UI, not mana_cost'),
  'SymbolsToggle.png': (tokenInners: [], note: 'UI, not mana_cost'),
  'fullManaCost.png': (tokenInners: [], note: 'UI, not mana_cost'),
  'empty.png': (tokenInners: [], note: 'UI, not mana_cost'),
  'MYB/fullManaCost.png': (tokenInners: [], note: 'UI, not mana_cost'),
};

/// Returns association for a path like `assets/mana/W.png` or `W.png`.
ManaPngAssociation? associationForBundledManaPath(String path) {
  var p = path.trim();
  if (p.startsWith('assets/mana/')) {
    p = p.substring('assets/mana/'.length);
  }
  return kManaPngToScryfall[p];
}
