import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../providers/forum_provider.dart';
import '../widgets/forum_search_bar.dart';
import '../widgets/forum_category_chips.dart';
import '../widgets/forum_post_card.dart';
import 'post_detail_screen.dart';
import 'create_edit_post_screen.dart';
import 'forum_stats_screen.dart';

class ForumFeedScreen extends StatelessWidget {
  const ForumFeedScreen({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const ForumFeedScreen());
  }

  void _showFilterBottomSheet(BuildContext context, ForumProvider forumProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtres & Tri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          forumProvider.setStatusFilter('all');
                          forumProvider.setSortBy('newest');
                          Navigator.pop(ctx);
                        },
                        child: const Text('Réinitialiser', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Statut de résolution
                  const Text(
                    'Statut de la question',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChoiceChip(
                        label: 'Toutes',
                        isSelected: forumProvider.selectedStatus == 'all',
                        onTap: () {
                          forumProvider.setStatusFilter('all');
                          setModalState(() {});
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Résolues uniquement',
                        isSelected: forumProvider.selectedStatus == 'resolved',
                        onTap: () {
                          forumProvider.setStatusFilter('resolved');
                          setModalState(() {});
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Sans réponse',
                        isSelected: forumProvider.selectedStatus == 'unresolved',
                        onTap: () {
                          forumProvider.setStatusFilter('unresolved');
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Ordre de tri
                  const Text(
                    'Trier par',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChoiceChip(
                        label: 'Plus récents',
                        isSelected: forumProvider.sortBy == 'newest',
                        onTap: () {
                          forumProvider.setSortBy('newest');
                          setModalState(() {});
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Plus populaires (votes)',
                        isSelected: forumProvider.sortBy == 'upvotes',
                        onTap: () {
                          forumProvider.setSortBy('upvotes');
                          setModalState(() {});
                        },
                      ),
                      _buildFilterChoiceChip(
                        label: 'Plus discutés',
                        isSelected: forumProvider.sortBy == 'comments',
                        onTap: () {
                          forumProvider.setSortBy('comments');
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Appliquer les filtres', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      backgroundColor: AppColors.surfaceMuted,
      labelStyle: TextStyle(
        fontSize: 12.5,
        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.cardBorder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final currentUserId = user?.id ?? 'guest_user';
    final currentUserName = user?.fullName ?? 'Utilisateur HomeFix';
    final currentUserRole = user?.role.label ?? 'Client';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forum & Entraide'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded, color: AppColors.primary),
            tooltip: 'Mes contributions & Stats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ForumStatsScreen(
                    userId: currentUserId,
                    userName: currentUserName,
                    userRole: currentUserRole,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateEditPostScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Poser une question',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        elevation: 3,
      ),
      body: Consumer<ForumProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search & Filter header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    ForumSearchBar(
                      onSearchChanged: provider.setSearchQuery,
                      onFilterTap: () => _showFilterBottomSheet(context, provider),
                      activeSort: provider.sortBy,
                      activeStatus: provider.selectedStatus,
                    ),
                    const SizedBox(height: 12),
                    ForumCategoryChips(
                      selectedCategory: provider.selectedCategory,
                      onSelected: provider.setCategory,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.cardBorder),

              // Posts list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => await provider.loadPosts(),
                  color: AppColors.primary,
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : provider.posts.isEmpty
                          ? _buildEmptyState(context, provider)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                              itemCount: provider.posts.length,
                              itemBuilder: (context, index) {
                                final post = provider.posts[index];
                                return ForumPostCard(
                                  post: post,
                                  currentUserId: currentUserId,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PostDetailScreen(postId: post.id),
                                      ),
                                    );
                                  },
                                  onUpvote: () => provider.toggleUpvote(post.id, currentUserId),
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ForumProvider provider) {
    final bool isSearching = provider.searchQuery.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              isSearching ? 'Aucun résultat trouvé' : 'Aucune question dans cette catégorie',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Essayez de modifier vos termes de recherche ou d\'effacer les filtres.'
                  : 'Soyez le premier à poser une question technique ou partager une astuce !',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (isSearching)
              OutlinedButton.icon(
                onPressed: () {
                  provider.setSearchQuery('');
                  provider.setCategory('Tous');
                  provider.setStatusFilter('all');
                },
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                label: const Text('Réinitialiser la recherche', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
