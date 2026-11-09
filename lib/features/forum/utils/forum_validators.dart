class ForumValidators {
  /// Validation du titre de la question
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le titre de la question est obligatoire.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 6) {
      return 'Le titre doit comporter au moins 6 caractères.';
    }
    if (trimmed.length > 90) {
      return 'Le titre ne peut pas dépasser 90 caractères (${trimmed.length}/90).';
    }
    // Anti-répétition abusive (ex: aaaaaa) — 5+ same char in a row
    if (RegExp(r'(.)\1{4,}').hasMatch(trimmed)) {
      return 'Veuillez écrire un titre compréhensible sans répétition abusive.';
    }
    // Vérification que ce ne sont pas seulement des symboles
    if (!RegExp(r'[a-zA-ZÀ-ÿ0-9]').hasMatch(trimmed)) {
      return 'Le titre doit contenir des mots valides.';
    }
    return null;
  }

  /// Validation de la catégorie
  static String? validateCategory(String? category) {
    if (category == null || category.trim().isEmpty || category == 'Tous') {
      return 'Veuillez sélectionner un corps de métier / catégorie.';
    }
    return null;
  }

  /// Validation de la description du problème
  static String? validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez décrire votre problème en détail.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 15) {
      return 'La description est trop courte (min 15 caractères).';
    }
    if (trimmed.length > 2000) {
      return 'La description ne doit pas dépasser 2000 caractères.';
    }
    // Anti-répétition abusive de lettres (ex: aaaaaaaaaaaaaa) — 5+ same char in a row
    if (RegExp(r'(.)\1{4,}').hasMatch(trimmed)) {
      return 'Veuillez écrire une description compréhensible sans répétition abusive.';
    }
    return null;
  }

  /// Validation du commentaire ou réponse
  static String? validateComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Votre réponse ne peut pas être vide.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Votre réponse est trop courte.';
    }
    if (trimmed.length > 600) {
      return 'Le commentaire ne peut pas dépasser 600 caractères.';
    }
    return null;
  }
}
