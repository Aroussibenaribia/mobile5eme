import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'forum_database.dart';
import '../models/forum_post_model.dart';
import '../models/forum_comment_model.dart';
import '../models/user_forum_stats_model.dart';

class ForumRepository {
  final ForumDatabase _dbProvider = ForumDatabase.instance;

  /// Récupère la liste des questions avec filtres combinés et recherche plein-texte
  Future<List<ForumPostModel>> getPosts({
    String? category,
    String? searchQuery,
    String? statusFilter, // 'all', 'resolved', 'unresolved'
    String? sortBy, // 'newest', 'upvotes', 'comments'
  }) async {
    final db = await _dbProvider.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    // Filtre par catégorie
    if (category != null && category.isNotEmpty && category != 'Tous') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    // Filtre par statut de résolution
    if (statusFilter == 'resolved') {
      whereClauses.add('is_resolved = 1');
    } else if (statusFilter == 'unresolved') {
      whereClauses.add('is_resolved = 0');
    }

    // Recherche plein-texte dans titre, contenu et catégorie
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR content LIKE ? OR category LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.add(term);
      whereArgs.add(term);
      whereArgs.add(term);
    }

    // Tri SQL
    String orderBy = 'is_pinned DESC, created_at DESC';
    if (sortBy == 'upvotes') {
      orderBy = 'is_pinned DESC, upvotes DESC, created_at DESC';
    } else if (sortBy == 'comments') {
      orderBy = 'is_pinned DESC, comment_count DESC, created_at DESC';
    }

    final whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'forum_posts',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return maps.map((map) => ForumPostModel.fromMap(map)).toList();
  }

  /// Récupère une question par son identifiant
  Future<ForumPostModel?> getPostById(String id) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'forum_posts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ForumPostModel.fromMap(maps.first);
    }
    return null;
  }

  /// Création d'une nouvelle question
  Future<ForumPostModel> createPost(ForumPostModel post) async {
    final db = await _dbProvider.database;
    await db.insert(
      'forum_posts',
      post.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return post;
  }

  /// Mise à jour d'une question existante
  Future<void> updatePost(ForumPostModel post) async {
    final db = await _dbProvider.database;
    await db.update(
      'forum_posts',
      post.toMap(),
      where: 'id = ?',
      whereArgs: [post.id],
    );
  }

  /// Suppression d'une question et de tous ses commentaires en cascade
  Future<void> deletePost(String postId) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete(
        'forum_comments',
        where: 'post_id = ?',
        whereArgs: [postId],
      );
      await txn.delete(
        'forum_posts',
        where: 'id = ?',
        whereArgs: [postId],
      );
    });
  }

  /// Toggle Upvote sur un post (Métier 2: Anti-Triche et Vote Unique)
  Future<ForumPostModel?> togglePostUpvote(String postId, String userId) async {
    final db = await _dbProvider.database;
    final post = await getPostById(postId);
    if (post == null) return null;

    final updatedVoters = List<String>.from(post.upvotedBy);
    int newUpvotes = post.upvotes;

    if (updatedVoters.contains(userId)) {
      // Annulation du vote existant
      updatedVoters.remove(userId);
      newUpvotes = (newUpvotes - 1).clamp(0, 999999);
    } else {
      // Ajout du nouveau vote unique
      updatedVoters.add(userId);
      newUpvotes += 1;
    }

    final updatedPost = post.copyWith(
      upvotes: newUpvotes,
      upvotedBy: updatedVoters,
    );

    await db.update(
      'forum_posts',
      {
        'upvotes': newUpvotes,
        'upvoted_by': jsonEncode(updatedVoters),
      },
      where: 'id = ?',
      whereArgs: [postId],
    );

    return updatedPost;
  }

  /// Récupère la liste des commentaires pour une question (la solution validée en premier)
  Future<List<ForumCommentModel>> getComments(String postId) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'forum_comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'is_accepted_solution DESC, likes DESC, created_at ASC',
    );

    return maps.map((map) => ForumCommentModel.fromMap(map)).toList();
  }

  /// Ajoute un nouveau commentaire et incrémente atomiquement le compteur du post
  Future<ForumCommentModel> addComment(ForumCommentModel comment) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.insert('forum_comments', comment.toMap());
      await txn.rawUpdate(
        'UPDATE forum_posts SET comment_count = comment_count + 1 WHERE id = ?',
        [comment.postId],
      );
    });
    return comment;
  }

  /// Supprime un commentaire et décrémente atomiquement le compteur
  Future<void> deleteComment(String commentId, String postId) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete(
        'forum_comments',
        where: 'id = ?',
        whereArgs: [commentId],
      );
      await txn.rawUpdate(
        'UPDATE forum_posts SET comment_count = MAX(0, comment_count - 1) WHERE id = ?',
        [postId],
      );
    });
  }

  /// Toggle Like sur un commentaire
  Future<ForumCommentModel?> toggleCommentLike(
      String commentId, String userId) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'forum_comments',
      where: 'id = ?',
      whereArgs: [commentId],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final comment = ForumCommentModel.fromMap(maps.first);
    final updatedLikers = List<String>.from(comment.likedBy);
    int newLikes = comment.likes;

    if (updatedLikers.contains(userId)) {
      updatedLikers.remove(userId);
      newLikes = (newLikes - 1).clamp(0, 999999);
    } else {
      updatedLikers.add(userId);
      newLikes += 1;
    }

    await db.update(
      'forum_comments',
      {
        'likes': newLikes,
        'liked_by': jsonEncode(updatedLikers),
      },
      where: 'id = ?',
      whereArgs: [commentId],
    );

    return comment.copyWith(likes: newLikes, likedBy: updatedLikers);
  }

  /// Marque une réponse comme Solution Validée (Métier 1)
  Future<void> markAcceptedSolution(String postId, String commentId) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      // 1. Réinitialise toute autre solution sur ce post
      await txn.update(
        'forum_comments',
        {'is_accepted_solution': 0},
        where: 'post_id = ?',
        whereArgs: [postId],
      );

      // 2. Active la solution validée sur le commentaire choisi
      await txn.update(
        'forum_comments',
        {'is_accepted_solution': 1},
        where: 'id = ?',
        whereArgs: [commentId],
      );

      // 3. Passe le post à l'état Résolu
      await txn.update(
        'forum_posts',
        {
          'is_resolved': 1,
          'resolved_comment_id': commentId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [postId],
      );
    });
  }

  /// Récupère les statistiques de gamification d'un utilisateur (Métier 6)
  Future<UserForumStatsModel> getUserStats(String userId,
      {String userRole = 'client'}) async {
    final db = await _dbProvider.database;

    // Nombre de questions posées
    final postsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM forum_posts WHERE author_id = ?',
      [userId],
    );
    final questionsCount = Sqflite.firstIntValue(postsResult) ?? 0;

    // Nombre de réponses apportées
    final answersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM forum_comments WHERE author_id = ?',
      [userId],
    );
    final answersCount = Sqflite.firstIntValue(answersResult) ?? 0;

    // Nombre de solutions acceptées
    final solutionsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM forum_comments WHERE author_id = ? AND is_accepted_solution = 1',
      [userId],
    );
    final solutionsAcceptedCount = Sqflite.firstIntValue(solutionsResult) ?? 0;

    return UserForumStatsModel(
      userId: userId,
      questionsCount: questionsCount,
      answersCount: answersCount,
      solutionsAcceptedCount: solutionsAcceptedCount,
      userRole: userRole,
    );
  }
}
