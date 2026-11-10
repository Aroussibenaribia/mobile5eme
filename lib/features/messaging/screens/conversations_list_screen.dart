import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/message_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/homefix_data.dart';
import '../../auth/screens/login_screen.dart';
import '../../professionals/screens/pro_list_screen.dart';
import 'conversation_screen.dart';

/// Inbox – lists all conversations for the logged-in user.
class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final data = context.watch<HomeFixData>();
    final conversations = data.conversations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<HomeFixData>().refresh(),
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: user == null
          ? FeatureEmpty(
              icon: Icons.lock_outline,
              title: 'Connexion requise',
              description: 'Connectez-vous pour accéder à vos messages.',
              action: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Se connecter'),
              ),
            )
          : data.isLoading && conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : conversations.isEmpty
                  ? FeatureEmpty(
                      icon: Icons.chat_bubble_outline,
                      title: 'Aucune conversation',
                      description:
                          'Discutez en direct avec vos artisans pour poser vos questions avant ou après une prestation.',
                      action: FilledButton.icon(
                        icon: const Icon(Icons.search, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProListScreen(),
                            ),
                          );
                        },
                        label: const Text('Trouver un artisan'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => context.read<HomeFixData>().refresh(),
                      child: ListView.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (ctx, i) {
                          final c = conversations[i];
                          return _ConversationTile(
                            summary: c,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ConversationScreen(
                                    otherUserId: c.otherUserId,
                                    otherUserName: c.otherUserName,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                context.read<HomeFixData>().refresh();
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummary summary;
  final VoidCallback onTap;

  const _ConversationTile({required this.summary, required this.onTap});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = summary.unreadCount > 0;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          summary.otherUserName.isNotEmpty
              ? summary.otherUserName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        summary.otherUserName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          summary.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(summary.lastMessageAt),
            style: TextStyle(
              fontSize: 11,
              color: hasUnread ? AppColors.primary : AppColors.textMuted,
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${summary.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
