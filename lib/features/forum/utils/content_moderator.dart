class ContentModerator {
  // ─── Blacklist étendue : insultes, discours haineux, variantes ───────────
  static const List<String> _blacklist = [
    // Insultes françaises courantes
    'merde', 'merd',
    'connard', 'conard', 'con', 'conne', 'connasse',
    'salope', 'salaud',
    'putain', 'pute',
    'batard', 'bâtard', 'batards',
    'foutre',
    'bordel',
    'encule', 'enculé', 'enculer', 'enculés',
    'chier', 'chie', 'chieur',
    'ta gueule', 'ferme ta gueule', 'tg',
    'va te faire', 'vtff', 'vtf',
    'nique', 'niquer', 'niqué', 'niqueur',
    'fdp', 'fils de pute', 'fils de p',
    'pd', 'pédé', 'pede',
    'grosse vache', 'gros con',
    'imbecile', 'imbécile',
    'idiot', 'idiote', 'idiotre',
    'abruti', 'abrutie',
    'cretin', 'crétin', 'cretine',
    'débile', 'debile',
    'trouduc', 'troudu',
    'couillon',
    'cul',
    'ostie', 'tabarnak', 'crisse', 'câlice', 'calice',
    'salopard',
    'ordure',
    'enfoiré', 'enfoire',
    'branler', 'branleur', 'branlette',
    'baiser',
    'bite', 'bites',
    'couille', 'couilles',
    'fesse', 'fesses',
    'nichon', 'nichons',
    'pénis', 'penis', 'vagin',
    'sexe',
    // Discours haineux / discrimination
    'raciste', 'racism',
    'nazi', 'hitler',
    'terrorist', 'terroriste',
    'negre', 'nègre', 'negro',
    'arabe sale', 'sale arabe',
    'juif sale', 'sale juif',
    'islamophobie',
    // Injures arabes phonétisées en latin (maghrébin)
    'kahba', 'qahba',
    'weld lhram', 'weld el hram',
    'bezdiz', 'bezdi',
    'sharmouta', 'charmuta', 'charmouta',
    'hmar', 'hmara',
    'zebi', 'zbi', 'zbib',
    'khara', 'khra',
    'manyak', 'manyaka',
    'nik', 'niqha',
    'weld lqahba',
    // Escroqueries / accusations
    'arnaque', 'escroc', 'voleur',
    // Variantes leet speak / contournement
    'm3rde', 'c0nnard', 'put1n', 'put@in', 'enc*le',
    // ─── English profanity & hate speech ────────────────────────────────────
    'fuck', 'fucker', 'fucking', 'fucked', 'fck', 'f*ck', 'fuk',
    'shit', 'sh1t', 'sh*t', 'shitty',
    'bitch', 'b1tch', 'btch',
    'asshole', 'assh0le', 'ass hole',
    'bastard', 'b@stard',
    'cunt', 'c*nt',
    'dick', 'd1ck',
    'cock', 'c0ck',
    'pussy', 'pussy',
    'whore', 'wh0re',
    'slut', 'sl*t',
    'nigger', 'n1gger', 'nig',
    'nigga',
    'faggot', 'fag', 'f@ggot',
    'retard', 'ret@rd',
    'idiot', 'stupid', 'moron', 'dumbass', 'dumb ass',
    'motherfucker', 'mf', 'motherf',
    'son of a bitch', 'sob',
    'go to hell', 'go fuck',
    'kill yourself', 'kys',
    'shut up', 'stfu',
    'piece of shit', 'pos',
    'jackass', 'jack ass',
    'wanker', 'w@nker',
    'twat', 'tw@t',
    'prick', 'pr1ck',
    'arse', '@rse',
    'bollocks',
    'bloody hell',
    'tosser',
    'hate you', 'i hate',
  ];

  // Map en mémoire pour le rate-limiting (Anti-Spam 30s)
  static final Map<String, DateTime> _lastActionTimestamps = {};

  /// Normalise le texte pour détecter les contournements (accents, casse, espaces)
  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('@', 'a')
        .replaceAll('\$', 's')
        .replaceAll('+', 't');
  }

  /// Détecte si le texte contient au moins un terme interdit
  static bool containsProhibitedWords(String input) {
    final normalized = _normalize(input);
    for (final word in _blacklist) {
      final normalizedWord = _normalize(word);
      if (normalized.contains(normalizedWord)) {
        return true;
      }
    }
    return false;
  }

  /// Masque automatiquement les mots inappropriés avec des astérisques (fallback)
  static String sanitizeText(String input) {
    String sanitized = input;
    for (final word in _blacklist) {
      final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        final length = match.group(0)?.length ?? 3;
        return '*' * length;
      });
    }
    return sanitized;
  }

  /// Vérifie si l'utilisateur est sous le coup d'un cooldown anti-flood (30 secondes)
  /// Retourne le nombre de secondes restantes, ou 0 si l'action est autorisée.
  static int checkRateLimitSecondsRemaining(String userId,
      {int cooldownSeconds = 30}) {
    if (userId.isEmpty) return 0;
    final lastTime = _lastActionTimestamps[userId];
    if (lastTime == null) return 0;

    final elapsed = DateTime.now().difference(lastTime).inSeconds;
    if (elapsed < cooldownSeconds) {
      return cooldownSeconds - elapsed;
    }
    return 0;
  }

  /// Enregistre une action pour démarrer le délai de cooldown
  static void registerAction(String userId) {
    if (userId.isNotEmpty) {
      _lastActionTimestamps[userId] = DateTime.now();
    }
  }
}
