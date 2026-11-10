import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../services/auth_service.dart';
import '../../../services/professional_service.dart';
import '../../services/screens/services_screen.dart';
import '../../search_and_booking/screens/booking_screens.dart';
import '../../reviews_and_history/screens/reclamation_screens.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../auth/screens/forgot_password_screen.dart';
import '../../messaging/screens/conversations_list_screen.dart';
import '../../messaging/screens/conversation_screen.dart';
import '../../../services/homefix_data.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final source = context.watch<ProfessionalService>();
    final pro = user == null ? null : source.getById(user.id);
    final data = context.watch<HomeFixData>();
    final conversations = data.conversations;
    final totalUnread =
        conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
    return Scaffold(
        appBar: AppBar(title: const Text('Mon espace')),
        body: ContentWidth(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
                children: user == null
                    ? [
                        const SizedBox(height: 30),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: CraftMark(size: 66)),
                        const SizedBox(height: 28),
                        const PageIntro(
                            title: 'Votre prochain\nprojet commence ici.',
                            description:
                                'Connectez-vous pour réserver une prestation et retrouver vos interventions.'),
                        FilledButton(
                            onPressed: () =>
                                _open(context, const LoginScreen()),
                            child: const Text('Se connecter')),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: () =>
                                _open(context, const RegisterScreen()),
                            child: const Text('Créer un compte')),
                      ]
                    : [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProAvatar(
                                  name: user.fullName,
                                  imageUrl: user.avatarUrl,
                                  radius: 34),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(user.role.label,
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text(user.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                    const SizedBox(height: 6),
                                    Text(user.email),
                                  ])),
                            ]),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                            onPressed: () =>
                                _open(context, const EditProfileScreen()),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Modifier mon profil')),
                        const SectionHeading('Coordonnées'),
                        FeatureCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              DetailLine('Ville', user.city),
                              DetailLine('Téléphone', user.phone),
                              DetailLine('Adresse', user.address),
                            ])),
                        if (user.isProfessional && pro != null) ...[
                          SectionHeading('Mon activité',
                              action: TextButton(
                                  onPressed: () =>
                                      _open(context, const ServicesScreen()),
                                  child: const Text('Prestations'))),
                          FeatureCard(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(pro.specialty,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                if (pro.bio.isNotEmpty) Text(pro.bio),
                                const Divider(height: 32),
                                Row(children: [
                                  Expanded(
                                      child: Text(
                                          pro.isAvailable
                                              ? 'Planning ouvert'
                                              : 'Réservations en pause',
                                          style: const TextStyle(
                                              color: AppColors.primaryDark,
                                              fontWeight: FontWeight.w700))),
                                  const Icon(Icons.calendar_month_outlined,
                                      color: AppColors.primary),
                                ]),
                                const SizedBox(height: 14),
                                WeekDays(selected: pro.availableDays),
                                const SizedBox(height: 12),
                                const Text('Interventions entre 08h et 19h.'),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                    onPressed: () => _open(
                                        context, const EditProfileScreen()),
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: const Text(
                                        'Modifier mes jours de travail')),
                              ])),
                        ],
                        const SectionHeading('Mon suivi'),
                        FeatureCard(
                            child: Column(children: [
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading:
                                  const Icon(Icons.calendar_month_outlined),
                              title: const Text('Mes réservations'),
                              trailing:
                                  const Icon(Icons.arrow_forward, size: 18),
                              onTap: () =>
                                  _open(context, const BookingListScreen())),
                          const Divider(),
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.support_agent_outlined),
                              title: const Text('Mes réclamations'),
                              trailing:
                                  const Icon(Icons.arrow_forward, size: 18),
                              onTap: () => _open(
                                  context, const ReclamationListScreen())),
                          const Divider(),
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.chat_bubble_outline),
                              title: const Text('Mes messages'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (totalUnread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$totalUnread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                              onTap: () => _open(
                                  context, const ConversationsListScreen())),
                          const Divider(),
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.lock_outline),
                              title: const Text('Changer mon mot de passe'),
                              trailing:
                                  const Icon(Icons.arrow_forward, size: 18),
                              onTap: () =>
                                  _open(context, const ForgotPasswordScreen())),
                        ])),
                        if (conversations.isNotEmpty) ...[
                          SectionHeading(
                            'Messages récents',
                            action: TextButton(
                              onPressed: () => _open(
                                  context, const ConversationsListScreen()),
                              child: const Text('Voir tout'),
                            ),
                          ),
                          FeatureCard(
                            child: Column(
                              children: [
                                for (var i = 0;
                                    i < conversations.take(2).length;
                                    i++) ...[
                                  if (i > 0) const Divider(),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        conversations[i].otherUserName.isNotEmpty
                                            ? conversations[i]
                                                .otherUserName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      conversations[i].otherUserName,
                                      style: TextStyle(
                                        fontWeight: conversations[i].unreadCount > 0
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      conversations[i].lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: conversations[i].unreadCount > 0
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: conversations[i].unreadCount > 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: conversations[i].unreadCount > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${conversations[i].unreadCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.arrow_forward,
                                            size: 16),
                                    onTap: () => _open(
                                      context,
                                      ConversationScreen(
                                        otherUserId:
                                            conversations[i].otherUserId,
                                        otherUserName:
                                            conversations[i].otherUserName,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextButton.icon(
                            onPressed: () => runAction(context, auth.logout),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Se déconnecter')),
                      ])));
  }
}
