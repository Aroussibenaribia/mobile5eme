class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'senderName': senderName,
        'receiverName': receiverName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead ? 1 : 0,
      };

  factory MessageModel.fromMap(Map<String, dynamic> m) => MessageModel(
        id: m['id'] as String,
        senderId: m['senderId'] as String,
        receiverId: m['receiverId'] as String,
        senderName: m['senderName'] as String? ?? '',
        receiverName: m['receiverName'] as String? ?? '',
        content: m['content'] as String,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isRead: m['isRead'] == 1,
      );
}

/// A lightweight summary of a conversation (the last message + the other person).
class ConversationSummary {
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ConversationSummary({
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });
}

