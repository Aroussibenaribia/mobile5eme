import 'package:flutter/material.dart';
import '../data/forum_repository.dart';
import '../models/forum_post_model.dart';
import '../models/forum_comment_model.dart';
import '../models/user_forum_stats_model.dart';
import '../utils/content_moderator.dart';

class ForumProvider extends ChangeNotifier {
  final ForumRepository _repository = ForumRepository();

  List<ForumPostModel> _posts = [];
  List<ForumCommentModel> _comments = [];
  UserForumStatsModel? _userStats;

  bool _isLoading = false;
  String? _errorMessage;

  // Filtres actifs
  String _selectedCategory = 'Tous';
  String _selectedStatus = 'all'; // 'all', 'resolved', 'unresolved'
  String _sortBy = 'newest'; // 'newest', 'upvotes', 'comments'
  String _searchQuery = '';

  // Getters
  List<ForumPostModel> get posts => _posts;
  List<ForumCommentModel> get comments => _comments;
  UserForumStatsModel? get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;
  String get sortBy => _sortBy;
  String get searchQuery => _searchQuery;

  ForumProvider() {
    loadPosts();
  }

  /// Chargement des posts avec filtres actifs
  Future<void> loadPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _repository.getPosts(
        category: _selectedCategory,
        searchQuery: _searchQuery,
        statusFilter: _selectedStatus,
        sortBy: _sortBy,
      );
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des questions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changement de catégorie
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadPosts();
    }
  }

  /// Changement de filtre de statut (Tous / Résolus / Sans réponse)
  void setStatusFilter(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      loadPosts();
    }
  }

  /// Changement de l'ordre de tri (Plus récents / Plus votés / Plus discutés)
  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      loadPosts();
    }
  }

  /// Recherche avec mise à jour du filtre
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPosts();
  }

  /// Création d'un post avec modération et vérification anti-spam
  Future<String?> createPost({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    String authorRole = 'Client',
    required String title,
    required String content,
    required String category,
    String? imageUrl,
  }) async {
    // Vérification Cooldown 30s
    final remainingCooldown =
        ContentModerator.checkRateLimitSecondsRemaining(authorId);
    if (remainingCooldown > 0) {
      return 'Veuillez patienter $remainingCooldown secondes avant de publier à nouveau.';
    }

    // Blocage des mots inappropriés
    if (ContentModerator.containsProhibitedWords(title.trim()) ||
        ContentModerator.containsProhibitedWords(content.trim())) {
      return 'Votre publication contient des mots inappropriés. Veuillez la reformuler.';
    }

    // Modération automatique des mots inappropriés
    final sanitizedTitle = ContentModerator.sanitizeText(title.trim());
    final sanitizedContent = ContentModerator.sanitizeText(content.trim());

    final now = DateTime.now();
    final newPost = ForumPostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorRole: authorRole,
      title: sanitizedTitle,
      content: sanitizedContent,
      category: category,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.createPost(newPost);
      ContentModerator.registerAction(authorId);
      await loadPosts();
      return null; // Succès
    } catch (e) {
      return 'Erreur lors de la publication : $e';
    }
  }

  /// Mise à jour d'un post
  Future<String?> updatePost(ForumPostModel post) async {
    try {
      final sanitizedTitle = ContentModerator.sanitizeText(post.title.trim());
      final sanitizedContent =
          ContentModerator.sanitizeText(post.content.trim());
      final updated = post.copyWith(
        title: sanitizedTitle,
        content: sanitizedContent,
        updatedAt: DateTime.now(),
      );

      await _repository.updatePost(updated);
      await loadPosts();
      return null;
    } catch (e) {
      return 'Erreur lors de la modification : $e';
    }
  }

  /// Suppression d'un post
  Future<void> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression : $e';
      notifyListeners();
    }
  }

  /// Toggle Upvote optimiste
  Future<void> toggleUpvote(String postId, String userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final currentPost = _posts[index];
    final hasVoted = currentPost.upvotedBy.contains(userId);
    final updatedVoters = List<String>.from(currentPost.upvotedBy);
    int newCount = currentPost.upvotes;

    if (hasVoted) {
      updatedVoters.remove(userId);
      newCount = (newCount - 1).clamp(0, 999999);
    } else {
      updatedVoters.add(userId);
      newCount += 1;
    }

    // Mise à jour optimiste immédiate dans l'UI
    _posts[index] = currentPost.copyWith(
      upvotes: newCount,
      upvotedBy: updatedVoters,
    );
    notifyListeners();

    try {
      await _repository.togglePostUpvote(postId, userId);
    } catch (e) {
      // Rollback en cas d'erreur
      _posts[index] = currentPost;
      notifyListeners();
    }
  }

  /// Chargement des commentaires d'un post
  Future<void> loadComments(String postId) async {
    try {
      _comments = await _repository.getComments(postId);
      notifyListeners();
    } catch (e) {
      _comments = [];
      notifyListeners();
    }
  }

  /// Ajout d'une réponse / commentaire avec modération et anti-spam
  Future<String?> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    String authorRole = 'Artisan',
    required String content,
  }) async {
    // Vérification Cooldown 30s
    final remainingCooldown =
        ContentModerator.checkRateLimitSecondsRemaining(authorId);
    if (remainingCooldown > 0) {
      return 'Veuillez patienter $remainingCooldown secondes avant de répondre à nouveau.';
    }

    // Blocage des mots inappropriés
    if (ContentModerator.containsProhibitedWords(content.trim())) {
      return 'Votre commentaire contient des mots inappropriés. Veuillez le reformuler.';
    }

    final sanitizedContent = ContentModerator.sanitizeText(content.trim());
    final newComment = ForumCommentModel(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorRole: authorRole,
      content: sanitizedContent,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.addComment(newComment);
      ContentModerator.registerAction(authorId);
      await loadComments(postId);

      // Met à jour le compteur du post dans la liste locale
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          commentCount: _posts[postIndex].commentCount + 1,
        );
        notifyListeners();
      }
      return null; // Succès
    } catch (e) {
      return 'Erreur lors de l\'ajout du commentaire : $e';
    }
  }

  /// Suppression d'un commentaire
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _repository.deleteComment(commentId, postId);
      _comments.removeWhere((c) => c.id == commentId);

      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          commentCount: (_posts[postIndex].commentCount - 1).clamp(0, 999999),
        );
      }
      notifyListeners();
    } catch (e) {
      // Silencieux ou affichage
    }
  }

  /// Toggle Like sur un commentaire
  Future<void> toggleCommentLike(String commentId, String userId) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final currentComment = _comments[index];
    final hasLiked = currentComment.likedBy.contains(userId);
    final updatedLikers = List<String>.from(currentComment.likedBy);
    int newLikes = currentComment.likes;

    if (hasLiked) {
      updatedLikers.remove(userId);
      newLikes = (newLikes - 1).clamp(0, 999999);
    } else {
      updatedLikers.add(userId);
      newLikes += 1;
    }

    _comments[index] = currentComment.copyWith(
      likes: newLikes,
      likedBy: updatedLikers,
    );
    notifyListeners();

    try {
      await _repository.toggleCommentLike(commentId, userId);
    } catch (_) {
      _comments[index] = currentComment;
      notifyListeners();
    }
  }

  /// Marquer une réponse comme Solution Validée (Métier 1)
  Future<void> markAcceptedSolution(String postId, String commentId) async {
    try {
      await _repository.markAcceptedSolution(postId, commentId);

      // Recharger commentaires et post
      await loadComments(postId);
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          isResolved: true,
          resolvedCommentId: commentId,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la validation de la solution: $e';
      notifyListeners();
    }
  }

  /// Charger les statistiques de l'utilisateur (Métier 6)
  Future<void> loadUserStats(String userId,
      {String userRole = 'client'}) async {
    try {
      _userStats = await _repository.getUserStats(userId, userRole: userRole);
      notifyListeners();
    } catch (_) {
      _userStats = null;
    }
  }
}
