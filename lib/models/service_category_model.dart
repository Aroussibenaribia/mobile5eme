import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ServiceCategoryModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int professionalCount;

  const ServiceCategoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.professionalCount = 12,
  });

  static List<ServiceCategoryModel> get defaultCategories => [
    const ServiceCategoryModel(
      id: 'plumbing',
      title: 'Plomberie',
      description: 'Fuites, tuyauterie, robinetterie, chauffe-eau',
      icon: Icons.plumbing_rounded,
      color: AppColors.catPlumbing,
      professionalCount: 24,
    ),
    const ServiceCategoryModel(
      id: 'electricity',
      title: 'Électricité',
      description: 'Pannes de courant, prises, tableaux électriques',
      icon: Icons.bolt_rounded,
      color: AppColors.catElectricity,
      professionalCount: 18,
    ),
    const ServiceCategoryModel(
      id: 'paint',
      title: 'Peinture',
      description: 'Peinture intérieure, extérieure, enduits, finitions',
      icon: Icons.format_paint_rounded,
      color: AppColors.catPaint,
      professionalCount: 15,
    ),
    const ServiceCategoryModel(
      id: 'cleaning',
      title: 'Nettoyage',
      description: 'Ménage régulier, grand nettoyage après travaux, vitres',
      icon: Icons.cleaning_services_rounded,
      color: AppColors.catCleaning,
      professionalCount: 30,
    ),
    const ServiceCategoryModel(
      id: 'ac',
      title: 'Climatisation',
      description: 'Installation, entretien, recharge de gaz, dépannage',
      icon: Icons.ac_unit_rounded,
      color: AppColors.catAC,
      professionalCount: 14,
    ),
    const ServiceCategoryModel(
      id: 'it',
      title: 'Informatique',
      description: 'Réparation PC/Mac, réseau Wi-Fi, imprimantes, virus',
      icon: Icons.computer_rounded,
      color: AppColors.catIT,
      professionalCount: 9,
    ),
  ];
}
