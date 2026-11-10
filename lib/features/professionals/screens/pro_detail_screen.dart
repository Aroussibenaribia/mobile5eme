import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../../../models/professional_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/professional_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../messaging/screens/conversation_screen.dart';
import '../../search_and_booking/screens/booking_screens.dart';

class ProDetailScreen extends StatelessWidget {
  final ProfessionalModel professional;
  const ProDetailScreen({super.key, required this.professional});
  Future<void> _book(
      BuildContext context, ProfessionalModel pro, ServiceModel service) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (!user.isProfessional && !user.isAdmin) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  BookingFormScreen(professional: pro, service: service)));
    }
  }

  Future<void> _openMessage(
      BuildContext context, ProfessionalModel pro) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ConversationScreen(
                  otherUserId: pro.id,
                  otherUserName: pro.name,
                )));
  }

  @override
  Widget build(BuildContext context) {
    final source = context.watch<ProfessionalService>();
    final pro = source.getById(professional.id);
    final user = context.watch<AuthService>().currentUser;
    final canBook = user == null || (!user.isProfessional && !user.isAdmin);
    // Show message button only to clients (not to themselves, not to admins)
    final canMessage = user != null &&
        !user.isAdmin &&
        !user.isProfessional &&
        user.id != professional.id;
    return Scaffold(
        appBar: AppBar(title: const Text('Fiche artisan')),
        body: pro == null
            ? const FeatureEmpty(
                title: 'Cet artisan est indisponible',
                description:
                    'Revenez au catalogue pour choisir un autre professionnel.')
            : ContentWidth(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
                    children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProAvatar(
                              name: pro.name,
                              imageUrl: pro.avatarUrl,
                              radius: 39),
                          const SizedBox(width: 18),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(pro.specialty,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 7),
                                Text(pro.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                const SizedBox(height: 8),
                                Text(pro.city),
                              ])),
                        ]),
                    const SizedBox(height: 24),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      StatusBadge(pro.isAvailable
                          ? 'Planning ouvert'
                          : 'Planning en pause'),
                      StatusBadge('${pro.experienceYears} ans d’expérience',
                          color: AppColors.textSecondary),
                      if (pro.reviewCount > 0)
                        StatusBadge(
                            '${pro.rating.toStringAsFixed(1)} · ${pro.reviewCount} avis',
                            color: AppColors.warning),
                    ]),
                    // ── Message button ──────────────────────────────────────
                    const SizedBox(height: 16),
                    if (canMessage)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openMessage(context, pro),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Envoyer un message'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    else if (user == null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openMessage(context, pro),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Se connecter pour écrire'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    // ────────────────────────────────────────────────────────
                    if (pro.bio.isNotEmpty) ...[
                      const SectionHeading('Le savoir-faire'),
                      Text(pro.bio)
                    ],
                    const SectionHeading('Prestations & tarifs'),
                    const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: Text(
                            'Un prix et une durée pour chaque intervention.')),
                    if (pro.services.isEmpty)
                      const FeatureCard(
                          child: Text(
                              'Aucune prestation publiée pour le moment.')),
                    ...pro.services.map((service) => FeatureCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Text(service.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium)),
                                    const SizedBox(width: 12),
                                    Text(
                                        '${service.price.toStringAsFixed(2)} DT',
                                        style: const TextStyle(
                                            fontSize: 17,
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w800)),
                                  ]),
                              const SizedBox(height: 12),
                              Text(service.description),
                              const SizedBox(height: 14),
                              Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.schedule,
                                              size: 16,
                                              color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Text(service.duration,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ]),
                                    if (pro.isAvailable && canBook)
                                      TextButton.icon(
                                          onPressed: () =>
                                              _book(context, pro, service),
                                          icon: const Icon(Icons.arrow_forward,
                                              size: 17),
                                          label: Text(user == null
                                              ? 'Se connecter'
                                              : 'Réserver')),
                                  ]),
                            ]))),
                    const SectionHeading('Ses jours de travail'),
                    WeekDays(selected: pro.availableDays),
                    const SizedBox(height: 14),
                    const Text(
                        'Les créneaux sont proposés de 08h à 19h, selon les réservations déjà prises.'),
                    if (pro.skills.isNotEmpty) ...[
                      const SectionHeading('Ses spécialités'),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: pro.skills
                              .map((skill) => Chip(label: Text(skill)))
                              .toList()),
                    ],
                  ])));
  }
}
