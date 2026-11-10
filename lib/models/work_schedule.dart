class WorkSchedule {
  static const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const labels = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];
  static List<String> ordered(Iterable<String> selected) =>
      days.where(selected.contains).toList();
}
