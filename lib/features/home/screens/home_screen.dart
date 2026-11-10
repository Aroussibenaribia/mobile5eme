import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../../../models/service_category_model.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/homefix_data.dart';
import '../../../services/professional_service.dart';
import '../../professionals/screens/pro_list_screen.dart';
import '../../professionals/widgets/pro_card.dart';
import '../../profile/screens/profile_screen.dart';
import '../../forum/screens/forum_feed_screen.dart';
import '../../services/screens/services_screen.dart';
import '../../search_and_booking/screens/booking_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final source = context.watch<ProfessionalService>();
    final data = context.watch<HomeFixData>();
    final professional = user?.isProfessional == true;
    final pending =
        data.bookings.where((b) => b.status == BookingStatus.pending).length;
    final upcoming = data.bookings
        .where((b) =>
            [
              BookingStatus.pending,
              BookingStatus.confirmed,
              BookingStatus.inProgress
            ].contains(b.status) &&
            b.scheduledDate.isAfter(DateUtils.dateOnly(DateTime.now())))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return Scaffold(
        body: SafeArea(
            child: ContentWidth(
                child: RefreshIndicator(
                    onRefresh: () async {
                      await source.loadProfessionals();
                      await data.refresh();
                    },
                    child: ListView(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                        children: [
                          Row(children: [
                            const CraftMark(size: 36),
                            const SizedBox(width: 10),
                            const Text('HomeFix',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.7)),
                            const Spacer(),
                            IconButton(
                                tooltip: 'Mon profil',
                                onPressed: () =>
                                    _open(context, const ProfileScreen()),
                                icon: ProAvatar(
                                    name: user?.fullName ?? 'Invité',
                                    imageUrl: user?.avatarUrl,
                                    radius: 19)),
                          ]),
                          const SizedBox(height: 28),
                          PageIntro(
                              eyebrow: professional
                                  ? 'Votre espace professionnel'
                                  : 'Services à domicile · ${user?.city ?? 'Tunisie'}',
                              title: professional
                                  ? 'Bonjour,\n${user!.fullName.split(' ').first}.'
                                  : 'Un projet\nà la maison ?',
                              description: professional
                                  ? 'Gardez le fil de vos interventions et de votre activité.'
                                  : 'Trouvez le bon savoir-faire. Choisissez une prestation, puis votre rendez-vous.'),
                          if (professional) ...[
                            Row(children: [
                              Expanded(
                                  child: _Metric(
                                      value: '$pending',
                                      label: 'Demandes à confirmer')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _Metric(
                                      value:
                                          '${data.services.where((s) => s.isActive).length}',
                                      label: 'Prestations publiées')),
                            ]),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                onPressed: () =>
                                    _open(context, const ServiceEditorScreen()),
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter une prestation')),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                                onPressed: () =>
                                    _open(context, const ServicesScreen()),
                                icon: const Icon(Icons.handyman_outlined),
                                label: const Text('Gérer mon catalogue')),
                          ] else ...[
                            Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        _open(context, const ProListScreen()),
                                    child: const Padding(
                                        padding: EdgeInsets.all(18),
                                        child: Row(children: [
                                          Icon(Icons.search,
                                              color: AppColors.primary),
                                          SizedBox(width: 12),
                                          Expanded(
                                              child: Text(
                                                  'Un métier, une prestation, une ville…',
                                                  style:
                                                      TextStyle(fontSize: 13))),
                                          Icon(Icons.arrow_forward,
                                              size: 18,
                                              color: AppColors.primary),
                                        ])))),
                            const SectionHeading(
                                'De quel métier avez-vous besoin ?'),
                            LayoutBuilder(builder: (context, constraints) {
                              final columns =
                                  constraints.maxWidth >= 600 ? 3 : 2;
                              return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final category in ServiceCategoryModel
                                        .defaultCategories)
                                      SizedBox(
                                          width: (constraints.maxWidth -
                                                  (columns - 1) * 10) /
                                              columns,
                                          child: Material(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  onTap: () => _open(
                                                      context,
                                                      ProListScreen(
                                                          initialCategory:
                                                              category.title)),
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              14),
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Icon(category.icon,
                                                                color: AppColors
                                                                    .primary,
                                                                size: 25),
                                                            const SizedBox(
                                                                height: 16),
                                                            Text(category.title,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700)),
                                                            const SizedBox(
                                                                height: 3),
                                                            Text(
                                                                '${source.allProfessionals.where((p) => p.specialty == category.title).length} artisan(s)',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: AppColors
                                                                        .textMuted)),
                                                          ]))))),
                                  ]);
                            }),
                          ],
                          if (user != null) ...[
                            SectionHeading('À votre agenda',
                                action: TextButton(
                                    onPressed: () => _open(
                                        context, const BookingListScreen()),
                                    child: const Text('Tout voir'))),
                            if (upcoming.isEmpty)
                              FeatureCard(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    const Icon(Icons.calendar_month_outlined,
                                        color: AppColors.primary),
                                    const SizedBox(height: 12),
                                    Text('Un peu de place dans votre agenda.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 6),
                                    Text(professional
                                        ? 'Les nouvelles demandes apparaîtront ici.'
                                        : 'Vos prochains rendez-vous apparaîtront ici.'),
                                  ]))
                            else
                              Material(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _open(
                                          context,
                                          BookingDetailScreen(
                                              id: upcoming.first.id)),
                                      child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    DateFormat('dd/MM · HH:mm')
                                                        .format(upcoming.first
                                                            .scheduledDate),
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .primaryDark,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(height: 10),
                                                Text(
                                                    upcoming.first.serviceTitle,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge),
                                                const SizedBox(height: 6),
                                                Text(professional
                                                    ? upcoming.first.clientName
                                                    : upcoming.first.proName),
                                                const SizedBox(height: 14),
                                                Row(children: [
                                                  Expanded(
                                                      child: Text(upcoming
                                                          .first.status.label)),
                                                  const Icon(
                                                      Icons.arrow_forward,
                                                      size: 19)
                                                ]),
                                              ])))),
                          ],
                          if (!professional) ...[
                            SectionHeading('Les artisans HomeFix',
                                action: TextButton(
                                    onPressed: () =>
                                        _open(context, const ProListScreen()),
                                    child: const Text('Explorer'))),
                            if (source.isLoading)
                              const LinearProgressIndicator()
                            else if (source.errorMessage != null)
                              FeatureEmpty(
                                  title: source.errorMessage!,
                                  action: TextButton(
                                      onPressed: source.loadProfessionals,
                                      child: const Text('Réessayer')))
                            else if (source.allProfessionals.isEmpty)
                              const FeatureCard(
                                  child: Text(
                                      'Aucun artisan ne propose de prestation pour le moment.'))
                            else
                              ...source.allProfessionals
                                  .take(3)
                                  .map((p) => ProCard(professional: p)),
                          ],
                          const SizedBox(height: 24),
                          Material(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () =>
                                      _open(context, const ForumFeedScreen()),
                                  child: Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Row(children: [
                                        const Icon(Icons.forum_outlined,
                                            color: Colors.white, size: 28),
                                        const SizedBox(width: 16),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              const Text(
                                                  'Un conseil entre deux travaux ?',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15)),
                                              const SizedBox(height: 7),
                                              Text(
                                                  'Posez votre question à la communauté.',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: .7),
                                                      fontSize: 12)),
                                            ])),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward,
                                            color: Colors.white, size: 20),
                                      ])))),
                        ])))));
  }
}

class _Metric extends StatelessWidget {
  final String value, label;
  const _Metric({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]));
}
