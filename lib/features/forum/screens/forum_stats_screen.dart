import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../providers/forum_provider.dart';
import '../widgets/forum_post_card.dart';
import 'post_detail_screen.dart';

class ForumStatsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;

  const ForumStatsScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userRole = 'Client',
  });

  @override
  State<ForumStatsScreen> createState() => _ForumStatsScreenState();
}

class _ForumStatsScreenState extends State<ForumStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ForumProvider>()
          .loadUserStats(widget.userId, userRole: widget.userRole);
    });
  }

  @override
  Widget build(BuildContext context) {
    final forumProvider = context.watch<ForumProvider>();
    final stats = forumProvider.userStats;
    final myPosts =
        forumProvider.posts.where((p) => p.authorId == widget.userId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Contributions & Stats'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Gamification Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ProAvatar(
                    name: widget.userName,
                    radius: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Gamification Badge
                  if (stats != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: stats.badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: stats.badgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(stats.badgeIcon,
                              size: 16, color: stats.badgeColor),
                          const SizedBox(width: 6),
                          Text(
                            stats.badgeTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: stats.badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Metrics Grid (3 cards)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Questions',
                    value: (stats?.questionsCount ?? myPosts.length).toString(),
                    icon: Icons.help_outline_rounded,
                    color: AppColors.catPlumbing,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Réponses',
                    value: (stats?.answersCount ?? 0).toString(),
                    icon: Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Solutions ★',
                    value: (stats?.solutionsAcceptedCount ?? 0).toString(),
                    icon: Icons.stars_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // My Discussions list
            Text(
              'Mes Questions Posées (${myPosts.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (myPosts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.post_add_rounded,
                        size: 40, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text(
                      'Vous n\'avez pas encore posé de question.',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...myPosts.map(
                (post) => ForumPostCard(
                  post: post,
                  currentUserId: widget.userId,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(postId: post.id),
                      ),
                    );
                  },
                  onUpvote: () =>
                      forumProvider.toggleUpvote(post.id, widget.userId),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
