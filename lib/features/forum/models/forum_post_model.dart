import 'dart:convert';

class ForumPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String title;
  final String content;
  final String category;
  final String? imageUrl;
  final int upvotes;
  final List<String> upvotedBy;
  final int commentCount;
  final bool isResolved;
  final String? resolvedCommentId;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ForumPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'Client',
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    this.upvotes = 0,
    this.upvotedBy = const [],
    this.commentCount = 0,
    this.isResolved = false,
    this.resolvedCommentId,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_role': authorRole,
      'title': title,
      'content': content,
      'category': category,
      'image_url': imageUrl,
      'upvotes': upvotes,
      'upvoted_by': jsonEncode(upvotedBy),
      'comment_count': commentCount,
      'is_resolved': isResolved ? 1 : 0,
      'resolved_comment_id': resolvedCommentId,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ForumPostModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedUpvotedBy = [];
    if (map['upvoted_by'] != null) {
      try {
        final decoded = jsonDecode(map['upvoted_by'] as String);
        if (decoded is List) {
          parsedUpvotedBy = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ForumPostModel(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      authorName: map['author_name'] as String,
      authorAvatar: map['author_avatar'] as String?,
      authorRole: (map['author_role'] as String?) ?? 'Client',
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      imageUrl: map['image_url'] as String?,
      upvotes: (map['upvotes'] as num?)?.toInt() ?? 0,
      upvotedBy: parsedUpvotedBy,
      commentCount: (map['comment_count'] as num?)?.toInt() ?? 0,
      isResolved: (map['is_resolved'] == 1 || map['is_resolved'] == true),
      resolvedCommentId: map['resolved_comment_id'] as String?,
      isPinned: (map['is_pinned'] == 1 || map['is_pinned'] == true),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  ForumPostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorRole,
    String? title,
    String? content,
    String? category,
    String? imageUrl,
    int? upvotes,
    List<String>? upvotedBy,
    int? commentCount,
    bool? isResolved,
    String? resolvedCommentId,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ForumPostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole ?? this.authorRole,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      upvotes: upvotes ?? this.upvotes,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      commentCount: commentCount ?? this.commentCount,
      isResolved: isResolved ?? this.isResolved,
      resolvedCommentId: resolvedCommentId ?? this.resolvedCommentId,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
