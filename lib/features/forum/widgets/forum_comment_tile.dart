import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../models/forum_comment_model.dart';
import '../utils/relative_time_formatter.dart';
import 'delete_confirm_dialog.dart';

class ForumCommentTile extends StatelessWidget {
  final ForumCommentModel comment;
  final String currentUserId;
  final bool isPostAuthor;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback onMarkSolution;

  const ForumCommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isPostAuthor,
    required this.onLike,
    required this.onDelete,
    required this.onMarkSolution,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMyComment = comment.authorId == currentUserId;
    final bool hasLiked = comment.likedBy.contains(currentUserId);
    final bool isArtisan = comment.authorRole.toLowerCase().contains('artisan');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: comment.isAcceptedSolution ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: comment.isAcceptedSolution ? const Color(0xFF86EFAC) : AppColors.cardBorder,
          width: comment.isAcceptedSolution ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Role, Date, Options
          Row(
            children: [
              ProAvatar(
                name: comment.authorName,
                imageUrl: comment.authorAvatar,
                radius: 17,
                showVerifiedBadge: isArtisan,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.authorName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (comment.isAcceptedSolution) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 10),
                                SizedBox(width: 2),
                                Text(
                                  'Solution',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          comment.authorRole,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isArtisan ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${RelativeTimeFormatter.format(comment.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isMyComment)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final confirm = await DeleteConfirmDialog.show(
                      context,
                      title: 'Supprimer la réponse',
                      message: 'Voulez-vous supprimer votre réponse ?',
                    );
                    if (confirm == true) {
                      onDelete();
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Content
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 12),

          // Footer: Like button & Mark as Solution Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Like button
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        hasLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        size: 15,
                        color: hasLiked ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        comment.likes.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasLiked ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mark as accepted solution button (Visible only for post author)
              if (isPostAuthor && !comment.isAcceptedSolution)
                TextButton.icon(
                  onPressed: onMarkSolution,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                  label: const Text(
                    'Valider comme solution',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
