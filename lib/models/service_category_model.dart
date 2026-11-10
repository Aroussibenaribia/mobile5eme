import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ServiceCategoryModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const ServiceCategoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static List<ServiceCategoryModel> get defaultCategories => [
        const ServiceCategoryModel(
          id: 'construction',
          title: 'Maçonnerie',
          description: 'Murs, petits travaux, réparation et finitions',
          icon: Icons.construction_rounded,
          color: AppColors.secondary,
        ),
        const ServiceCategoryModel(
          id: 'plumbing',
          title: 'Plomberie',
          description: 'Fuites, tuyauterie, robinetterie, chauffe-eau',
          icon: Icons.plumbing_rounded,
          color: AppColors.catPlumbing,
        ),
        const ServiceCategoryModel(
          id: 'electricity',
          title: 'Électricité',
          description: 'Pannes de courant, prises, tableaux électriques',
          icon: Icons.bolt_rounded,
          color: AppColors.catElectricity,
        ),
        const ServiceCategoryModel(
          id: 'paint',
          title: 'Peinture',
          description: 'Peinture intérieure, extérieure, enduits, finitions',
          icon: Icons.format_paint_rounded,
          color: AppColors.catPaint,
        ),
        const ServiceCategoryModel(
          id: 'cleaning',
          title: 'Nettoyage',
          description: 'Ménage régulier, grand nettoyage après travaux, vitres',
          icon: Icons.cleaning_services_rounded,
          color: AppColors.catCleaning,
        ),
        const ServiceCategoryModel(
          id: 'ac',
          title: 'Climatisation',
          description: 'Installation, entretien, recharge de gaz, dépannage',
          icon: Icons.ac_unit_rounded,
          color: AppColors.catAC,
        ),
        const ServiceCategoryModel(
          id: 'it',
          title: 'Informatique',
          description: 'Réparation PC/Mac, réseau Wi-Fi, imprimantes, virus',
          icon: Icons.computer_rounded,
          color: AppColors.catIT,
        ),
      ];
}
