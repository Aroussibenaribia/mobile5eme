import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../models/professional_model.dart';
import '../screens/pro_detail_screen.dart';

class ProCard extends StatelessWidget {
  final ProfessionalModel professional;
  final bool compact;

  const ProCard({
    super.key,
    required this.professional,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactProCard(professional: professional);
    }
    return _FullProCard(professional: professional);
  }
}

// ── COMPACT (horizontal scroll on Home) ────────────────────────────────────

class _CompactProCard extends StatelessWidget {
  final ProfessionalModel professional;
  const _CompactProCard({required this.professional});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProDetailScreen(professional: professional)),
      ),
      child: Container(
        width: 205,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored top accent bar
              Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0F766E)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProAvatar(
                          name: professional.name,
                          imageUrl: professional.avatarUrl,
                          radius: 22,
                          showVerifiedBadge: professional.isVerified,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                professional.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                professional.specialty,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RatingBadge(rating: professional.rating, compact: true),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${professional.hourlyRate.toStringAsFixed(0)} DT/h',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Availability dot
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: professional.isAvailable ? AppColors.success : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          professional.isAvailable ? 'Disponible' : 'Occupé',
                          style: TextStyle(
                            fontSize: 11,
                            color: professional.isAvailable ? AppColors.success : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FULL (list) ────────────────────────────────────────────────────────────

class _FullProCard extends StatelessWidget {
  final ProfessionalModel professional;
  const _FullProCard({required this.professional});

  Color get _specialtyColor {
    switch (professional.specialty.toLowerCase()) {
      case 'plomberie':
        return AppColors.catPlumbing;
      case 'électricité':
        return AppColors.catElectricity;
      case 'peinture':
        return AppColors.catPaint;
      case 'nettoyage':
        return AppColors.catCleaning;
      case 'informatique':
        return AppColors.catIT;
      case 'climatisation':
        return AppColors.catAC;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _specialtyColor;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProDetailScreen(professional: professional)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Left-colored accent
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProAvatar(
                                  name: professional.name,
                                  imageUrl: professional.avatarUrl,
                                  radius: 30,
                                  showVerifiedBadge: professional.isVerified,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              professional.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          // Availability badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: professional.isAvailable
                                                  ? AppColors.success.withValues(alpha: 0.1)
                                                  : AppColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: professional.isAvailable
                                                    ? AppColors.success.withValues(alpha: 0.3)
                                                    : AppColors.cardBorder,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: professional.isAvailable
                                                        ? AppColors.success
                                                        : AppColors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  professional.isAvailable ? 'Dispo' : 'Occupé',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: professional.isAvailable
                                                        ? AppColors.success
                                                        : AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              professional.specialty,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            professional.city,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Row(
                                        children: [
                                          RatingBadge(
                                            rating: professional.rating,
                                            reviewCount: professional.reviewCount,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '• ${professional.experienceYears} ans d\'exp.',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Bio snippet
                            if (professional.bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                professional.bio,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],

                            // Skills row
                            if (professional.skills.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 26,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: professional.skills
                                      .take(4)
                                      .map(
                                        (s) => Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceMuted,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),
                            Divider(height: 1, color: AppColors.cardBorder.withValues(alpha: 0.6)),
                            const SizedBox(height: 12),

                            // Bottom row: price + CTA
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tarif horaire',
                                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      '${professional.hourlyRate.toStringAsFixed(0)} DT / heure',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProDetailScreen(professional: professional),
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                                  label: const Text('Voir profil'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
