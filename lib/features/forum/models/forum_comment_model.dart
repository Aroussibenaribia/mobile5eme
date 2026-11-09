import 'dart:convert';

class ForumCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String content;
  final int likes;
  final List<String> likedBy;
  final bool isAcceptedSolution;
  final DateTime createdAt;

  const ForumCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'Client',
    required this.content,
    this.likes = 0,
    this.likedBy = const [],
    this.isAcceptedSolution = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_role': authorRole,
      'content': content,
      'likes': likes,
      'liked_by': jsonEncode(likedBy),
      'is_accepted_solution': isAcceptedSolution ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ForumCommentModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedLikedBy = [];
    if (map['liked_by'] != null) {
      try {
        final decoded = jsonDecode(map['liked_by'] as String);
        if (decoded is List) {
          parsedLikedBy = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ForumCommentModel(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      authorId: map['author_id'] as String,
      authorName: map['author_name'] as String,
      authorAvatar: map['author_avatar'] as String?,
      authorRole: (map['author_role'] as String?) ?? 'Client',
      content: map['content'] as String,
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      likedBy: parsedLikedBy,
      isAcceptedSolution: (map['is_accepted_solution'] == 1 || map['is_accepted_solution'] == true),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  ForumCommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorRole,
    String? content,
    int? likes,
    List<String>? likedBy,
    bool? isAcceptedSolution,
    DateTime? createdAt,
  }) {
    return ForumCommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole ?? this.authorRole,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      isAcceptedSolution: isAcceptedSolution ?? this.isAcceptedSolution,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
