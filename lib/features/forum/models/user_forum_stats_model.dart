import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class UserForumStatsModel {
  final String userId;
  final int questionsCount;
  final int answersCount;
  final int solutionsAcceptedCount;
  final String userRole; // 'client' ou 'pro'

  const UserForumStatsModel({
    required this.userId,
    this.questionsCount = 0,
    this.answersCount = 0,
    this.solutionsAcceptedCount = 0,
    this.userRole = 'client',
  });

  bool get isClient => userRole.toLowerCase().contains('client');

  String get badgeTitle {
    if (solutionsAcceptedCount >= 2 || (questionsCount + answersCount) >= 4) {
      return isClient ? 'Membre Émérite 🏆' : 'Artisan Référent ⭐';
    } else if (solutionsAcceptedCount >= 1 ||
        answersCount >= 1 ||
        questionsCount >= 2) {
      return isClient ? 'Client Actif 💬' : 'Bricoleur Actif 🔧';
    } else {
      return 'Nouveau Membre 🌱';
    }
  }

  Color get badgeColor {
    if (solutionsAcceptedCount >= 2 || (questionsCount + answersCount) >= 4) {
      return AppColors.accent; // Amber gold
    } else if (solutionsAcceptedCount >= 1 ||
        answersCount >= 1 ||
        questionsCount >= 2) {
      return AppColors.primary; // Teal
    } else {
      return AppColors.textSecondary; // Slate
    }
  }

  IconData get badgeIcon {
    if (solutionsAcceptedCount >= 2 || (questionsCount + answersCount) >= 4) {
      return isClient
          ? Icons.emoji_events_rounded
          : Icons.military_tech_rounded;
    } else if (solutionsAcceptedCount >= 1 ||
        answersCount >= 1 ||
        questionsCount >= 2) {
      return isClient ? Icons.forum_rounded : Icons.verified_user_rounded;
    } else {
      return Icons.eco_rounded;
    }
  }
}
