import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../models/forum_post_model.dart';
import '../models/forum_category_model.dart';
import '../utils/relative_time_formatter.dart';

class ForumPostCard extends StatelessWidget {
  final ForumPostModel post;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onUpvote;

  const ForumPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onTap,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUpvoted = post.upvotedBy.contains(currentUserId);
    final categoryColor = ForumCategoryModel.getColorForCategory(post.category);
    final categoryIcon = ForumCategoryModel.getIconForCategory(post.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: post.isResolved ? const Color(0xFFBBF7D0) : AppColors.cardBorder,
          width: post.isResolved ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Category Badge & Status Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 13, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            post.category,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (post.isResolved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7), // Emerald 100
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                            SizedBox(width: 3),
                            Text(
                              'Résolu',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (post.commentCount == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sans réponse',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Question Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Excerpt of the problem
                Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Attached Photo Preview if available
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.surfaceMuted,
                      child: !kIsWeb && File(post.imageUrl!).existsSync()
                          ? Image.file(
                              File(post.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              alignment: Alignment.center,
                              color: AppColors.primaryLight,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_rounded, color: AppColors.primary, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Photo du diagnostic jointe',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 10),

                // Author and Interaction Footer
                Row(
                  children: [
                    ProAvatar(
                      name: post.authorName,
                      imageUrl: post.authorAvatar,
                      radius: 13,
                      showVerifiedBadge: post.authorRole.toLowerCase().contains('artisan'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            RelativeTimeFormatter.format(post.createdAt),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Upvote button
                    InkWell(
                      onTap: onUpvote,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hasUpvoted ? AppColors.primaryLight : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                              size: 14,
                              color: hasUpvoted ? AppColors.primaryDark : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              post.upvotes.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: hasUpvoted ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Comments counter badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            post.commentCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
