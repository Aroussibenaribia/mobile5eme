import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showVerifiedBadge;
  final bool showOnlineIndicator;
  final bool isOnline;

  const ProAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 28,
    this.showVerifiedBadge = false,
    this.showOnlineIndicator = false,
    this.isOnline = true,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Text(
                  _initials,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.75,
                  ),
                )
              : null,
        ),
        if (showVerifiedBadge)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (showOnlineIndicator && !showVerifiedBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.textMuted,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
