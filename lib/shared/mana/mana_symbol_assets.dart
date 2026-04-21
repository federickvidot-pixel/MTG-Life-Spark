/// Maps Scryfall-style mana strings (e.g. `{2}{W}{U}`, `{R}`, `{G/U}`) to bundled PNG
/// paths under `assets/mana/` (MTG mana symbol set bundled with the app).
///
/// Full table of each PNG vs mana tokens: [kManaPngToScryfall] in `mana_asset_catalog.dart`
/// (matches `Magic The Gathering Mana` on Desktop when synced into `assets/mana/`).

/// Must match `pubspec.yaml` asset prefixes.
const String kManaAssetPrefix = 'assets/mana/';

/// Scryfall `mana_cost` has no spaces; Hive/user input sometimes has `{1} {U}` or a missing `}`.
/// Canonicalizes so token parsing and PNG mapping match bundled assets.
String normalizeScryfallManaCost(String? raw) {
  if (raw == null) return '';
  var s = raw.trim();
  if (s.isEmpty) return '';
  s = s.replaceAll(RegExp(r'\s+'), '');
  var open = 0;
  var close = 0;
  for (final r in s.runes) {
    if (r == 0x7B) open++;
    if (r == 0x7D) close++;
  }
  if (open > close) {
    s += List.filled(open - close, '}').join();
  }
  return s;
}

/// One braced Scryfall token (inner text without `{` `}`) and its bundled image path, if any.
typedef ManaCostToken = ({String inner, String? assetPath});

/// Parses [manaCost] into ordered tokens. [assetPath] is null when the symbol is unknown
/// or has no mapped PNG (caller may show `{inner}` as text).
List<ManaCostToken> manaCostTokens(String? manaCost) {
  if (manaCost == null || manaCost.trim().isEmpty) return [];
  final normalized = normalizeScryfallManaCost(manaCost);
  if (normalized.isEmpty) return [];
  final out = <ManaCostToken>[];
  for (final m in RegExp(r'\{([^}]*)\}').allMatches(normalized)) {
    final inner = m.group(1);
    if (inner == null) continue;
    final trimmed = inner.trim();
    if (trimmed.isEmpty) continue;
    final rel = _symbolInnerToRelativePath(trimmed);
    final path = rel != null ? '$kManaAssetPrefix$rel' : null;
    out.add((inner: trimmed, assetPath: path));
  }
  return out;
}

/// Readable fallback: `{2}{W}` → `2W`
String manaCostPlainText(String manaCost) =>
    normalizeScryfallManaCost(manaCost).replaceAll(RegExp(r'[\{\}]'), '');

String? _symbolInnerToRelativePath(String inner) {
  final s = inner.trim();
  if (s.isEmpty) return null;

  final asInt = int.tryParse(s);
  if (asInt != null && asInt >= 0 && asInt <= 20) {
    return '$asInt.png';
  }

  if (!s.contains('/')) {
    return _atomicSymbolPath(s);
  }

  final parts = s.split('/');
  if (parts.length != 2) return null;
  var a = parts[0].trim();
  var b = parts[1].trim();
  if (a.isEmpty || b.isEmpty) return null;

  // Phyrexian mana: {W/P} or {P/W}
  if (a == 'P' && _isPhyrexianColored(b)) return 'phy/${b}P.png';
  if (b == 'P' && _isPhyrexianColored(a)) return 'phy/${a}P.png';

  // Hybrid with generic 2: {2/W}, {W/2}
  if (a == '2' && _isWubrg(b)) return 'hybrid/2$b.png';
  if (b == '2' && _isWubrg(a)) return 'hybrid/2$a.png';

  if (a.length == 1 && b.length == 1) {
    final key = '$a$b';
    final rev = '$b$a';
    final h = _hybridRelative[key] ?? _hybridRelative[rev];
    if (h != null) return h;
  }

  return null;
}

bool _isWubrg(String c) => c.length == 1 && 'WUBRG'.contains(c);

bool _isPhyrexianColored(String c) =>
    c.length == 1 && 'WUBRG'.contains(c);

String? _atomicSymbolPath(String s) {
  if (s.length == 1) {
    switch (s) {
      case 'W':
      case 'U':
      case 'B':
      case 'R':
      case 'G':
      case 'C':
      case 'E':
      case 'T':
      case 'S':
        return '$s.png';
      case 'X':
        return 'symbol/mana/X.png';
      default:
        return null;
    }
  }
  return null;
}

/// Guild / two-color + [{C/x}] + {2/x} filenames under `assets/mana/hybrid/`.
const _hybridRelative = <String, String>{
  'WU': 'hybrid/WU.png',
  'WB': 'hybrid/WB.png',
  'UB': 'hybrid/UB.png',
  'UR': 'hybrid/UR.png',
  'BR': 'hybrid/BR.png',
  'BG': 'hybrid/BG.png',
  'RG': 'hybrid/RG.png',
  'RW': 'hybrid/RW.png',
  'GW': 'hybrid/GW.png',
  'GU': 'hybrid/GU.png',
  'CU': 'hybrid/CU.png',
  'CW': 'hybrid/CW.png',
  'CB': 'hybrid/CB.png',
  'CR': 'hybrid/CR.png',
  'CG': 'hybrid/CG.png',
};
