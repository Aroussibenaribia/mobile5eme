import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ForumCategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const ForumCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });

  static List<ForumCategoryModel> get categories => const [
    ForumCategoryModel(
      id: 'plumbing',
      name: 'Plomberie',
      icon: Icons.plumbing_rounded,
      color: AppColors.catPlumbing,
      description: 'Fuites, tuyauterie, robinetterie, chauffe-eau',
    ),
    ForumCategoryModel(
      id: 'electricity',
      name: 'Électricité',
      icon: Icons.bolt_rounded,
      color: AppColors.catElectricity,
      description: 'Pannes de courant, prises, tableaux électriques',
    ),
    ForumCategoryModel(
      id: 'ac',
      name: 'Climatisation',
      icon: Icons.ac_unit_rounded,
      color: AppColors.catAC,
      description: 'Installation, entretien, recharge de gaz, dépannage',
    ),
    ForumCategoryModel(
      id: 'paint',
      name: 'Peinture',
      icon: Icons.format_paint_rounded,
      color: AppColors.catPaint,
      description: 'Peinture intérieure, extérieure, enduits, finitions',
    ),
    ForumCategoryModel(
      id: 'cleaning',
      name: 'Nettoyage',
      icon: Icons.cleaning_services_rounded,
      color: AppColors.catCleaning,
      description: 'Ménage régulier, grand nettoyage, vitres',
    ),
    ForumCategoryModel(
      id: 'it',
      name: 'Informatique',
      icon: Icons.devices_rounded,
      color: AppColors.catIT,
      description: 'Réseaux WiFi, PC, imprimantes, caméras IP',
    ),
  ];

  static Color getColorForCategory(String categoryName) {
    for (final cat in categories) {
      if (cat.name.toLowerCase() == categoryName.toLowerCase()) {
        return cat.color;
      }
    }
    return AppColors.primary;
  }

  static IconData getIconForCategory(String categoryName) {
    for (final cat in categories) {
      if (cat.name.toLowerCase() == categoryName.toLowerCase()) {
        return cat.icon;
      }
    }
    return Icons.forum_rounded;
  }
}
