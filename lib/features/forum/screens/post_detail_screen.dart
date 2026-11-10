import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../../../services/auth_service.dart';
import '../models/forum_post_model.dart';
import '../models/forum_comment_model.dart';
import '../models/forum_category_model.dart';
import '../providers/forum_provider.dart';
import '../utils/relative_time_formatter.dart';
import '../utils/forum_validators.dart';
import '../widgets/accepted_solution_banner.dart';
import '../widgets/forum_comment_tile.dart';
import '../widgets/delete_confirm_dialog.dart';
import 'create_edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().loadComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sharePost(ForumPostModel post) {
    Share.share(
      '💡 Question HomeFix Entraide :\n\n'
      '${post.title} (${post.category})\n\n'
      '${post.content}\n\n'
      'Retrouvez les conseils et solutions sur l\'application HomeFix !',
      subject: post.title,
    );
  }

  Future<void> _submitComment(ForumPostModel post, String currentUserId,
      String currentUserName, String currentUserRole) async {
    final validationError =
        ForumValidators.validateComment(_commentController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(validationError), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSending = true);

    final provider = context.read<ForumProvider>();
    final error = await provider.addComment(
      postId: post.id,
      authorId: currentUserId,
      authorName: currentUserName,
      authorRole: currentUserRole,
      content: _commentController.text,
    );

    setState(() => _isSending = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.warning),
      );
    } else {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre réponse a été publiée avec succès !'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final currentUserId = user?.id ?? 'guest_user';
    final currentUserName = user?.fullName ?? 'Utilisateur HomeFix';
    final currentUserRole = user?.isProfessional == true ? 'Artisan' : 'Client';

    final forumProvider = context.watch<ForumProvider>();
    final postIndex =
        forumProvider.posts.indexWhere((p) => p.id == widget.postId);

    if (postIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du sujet')),
        body: const Center(child: Text('Cette question n\'existe plus.')),
      );
    }

    final post = forumProvider.posts[postIndex];
    final bool isAuthor = post.authorId == currentUserId;
    final categoryColor = ForumCategoryModel.getColorForCategory(post.category);

    // Look for accepted solution comment
    ForumCommentModel? acceptedComment;
    if (post.isResolved && post.resolvedCommentId != null) {
      try {
        acceptedComment = forumProvider.comments.firstWhere(
          (c) => c.id == post.resolvedCommentId,
        );
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Partager',
            onPressed: () => _sharePost(post),
          ),
          if (isAuthor)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateEditPostScreen(postToEdit: post),
                    ),
                  );
                } else if (value == 'delete') {
                  final confirm = await DeleteConfirmDialog.show(
                    context,
                    title: 'Supprimer la question ?',
                    message:
                        'Cette action supprimera définitivement la question et toutes ses réponses.',
                  );
                  if (confirm == true && context.mounted) {
                    await forumProvider.deletePost(post.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Supprimer',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Question Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Status row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                post.category,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (post.isResolved)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF86EFAC)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text('Résolu',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Full Content
                        Text(
                          post.content,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),

                        // Attached Image if exists
                        if (post.imageUrl != null &&
                            post.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: !kIsWeb && File(post.imageUrl!).existsSync()
                                ? Image.file(
                                    File(post.imageUrl!),
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 160,
                                    color: AppColors.primaryLight,
                                    alignment: Alignment.center,
                                    child: const Text('Photo du diagnostic'),
                                  ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        const SizedBox(height: 12),

                        // Author Footer
                        Row(
                          children: [
                            ProAvatar(
                              name: post.authorName,
                              imageUrl: post.authorAvatar,
                              radius: 17,
                              showVerifiedBadge: post.authorRole
                                  .toLowerCase()
                                  .contains('artisan'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.authorName,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    'Posté ${RelativeTimeFormatter.format(post.createdAt)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),

                            // Upvote Toggle
                            InkWell(
                              onTap: () => forumProvider.toggleUpvote(
                                  post.id, currentUserId),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: post.upvotedBy.contains(currentUserId)
                                      ? AppColors.primaryLight
                                      : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      post.upvotedBy.contains(currentUserId)
                                          ? Icons.thumb_up_rounded
                                          : Icons.thumb_up_outlined,
                                      size: 16,
                                      color:
                                          post.upvotedBy.contains(currentUserId)
                                              ? AppColors.primaryDark
                                              : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      post.upvotes.toString(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: post.upvotedBy
                                                .contains(currentUserId)
                                            ? AppColors.primaryDark
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Accepted Solution Banner (Pinned under post)
                  if (acceptedComment != null)
                    AcceptedSolutionBanner(comment: acceptedComment),

                  const SizedBox(height: 20),

                  // Comments section title
                  Row(
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Réponses & Conseils (${forumProvider.comments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Comments List
                  if (forumProvider.comments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.mark_chat_unread_outlined,
                              size: 38, color: AppColors.textMuted),
                          SizedBox(height: 10),
                          Text(
                            'Aucune réponse pour le moment.',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Partagez votre expertise ou posez une précision ci-dessous.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ...forumProvider.comments.map(
                      (c) => ForumCommentTile(
                        comment: c,
                        currentUserId: currentUserId,
                        isPostAuthor: isAuthor,
                        onLike: () => forumProvider.toggleCommentLike(
                            c.id, currentUserId),
                        onDelete: () =>
                            forumProvider.deleteComment(c.id, post.id),
                        onMarkSolution: () async {
                          await forumProvider.markAcceptedSolution(
                              post.id, c.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '★ Solution validée avec succès ! Le sujet est maintenant résolu.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Sticky Reply Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Partagez votre conseil ou solution...',
                          hintStyle: TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _isSending
                        ? null
                        : () => _submitComment(post, currentUserId,
                            currentUserName, currentUserRole),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
