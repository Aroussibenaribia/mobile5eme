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
        ClipRRect(
          borderRadius: BorderRadius.circular(radius * .55),
          child: Container(
            width: radius * 2,
            height: radius * 2,
            color: AppColors.primaryLight,
            alignment: Alignment.center,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(imageUrl!,
                    fit: BoxFit.cover,
                    width: radius * 2,
                    height: radius * 2,
                    errorBuilder: (_, __, ___) => Text(_initials,
                        style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: radius * .75,
                            fontWeight: FontWeight.w700)))
                : Text(_initials,
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: radius * .75,
                        fontWeight: FontWeight.w700)),
          ),
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
