import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/data/homefix_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/reclamation_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/homefix_data.dart';
import '../../auth/screens/login_screen.dart';
import '../../search_and_booking/screens/booking_screens.dart';

class HistoryAndReclamationsScreen extends StatelessWidget {
  const HistoryAndReclamationsScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
              title: const Text('Historique & Réclamations'),
              bottom: const TabBar(
                  tabs: [Tab(text: 'Historique'), Tab(text: 'Réclamations')])),
          body: const TabBarView(children: [
            BookingListScreen(embedded: true, historyOnly: true),
            ReclamationListScreen(embedded: true)
          ])));
}

class ReclamationListScreen extends StatefulWidget {
  final bool embedded;
  const ReclamationListScreen({super.key, this.embedded = false});
  @override
  State<ReclamationListScreen> createState() => _ReclamationListScreenState();
}

class _ReclamationListScreenState extends State<ReclamationListScreen> {
  ReclamationStatus? _filter;
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeFixData>();
    final user = context.watch<AuthService>().currentUser;
    final rows = data.reclamations
        .where((r) =>
            (_filter == null || r.status == _filter) &&
            ('${r.subject} ${r.clientName} ${r.proName} ${r.serviceTitle}')
                .toLowerCase()
                .contains(_search.toLowerCase()))
        .toList();
    final body = user == null
        ? FeatureEmpty(
            title: 'Suivez vos réclamations',
            description:
                'Connectez-vous pour consulter les réponses de l’administration.',
            action: FilledButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Se connecter')))
        : Column(children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  TextField(
                      decoration: const InputDecoration(
                          hintText: 'Rechercher une réclamation',
                          prefixIcon: Icon(Icons.search)),
                      onChanged: (v) => setState(() => _search = v)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: DropdownButtonFormField<ReclamationStatus?>(
                            initialValue: _filter,
                            decoration:
                                const InputDecoration(labelText: 'Statut'),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Tous les statuts')),
                              ...ReclamationStatus.values.map((s) =>
                                  DropdownMenuItem(
                                      value: s, child: Text(s.label)))
                            ],
                            onChanged: (v) => setState(() => _filter = v))),
                    if (!user.isProfessional && !user.isAdmin) ...[
                      const SizedBox(width: 8),
                      IconButton.filled(
                          tooltip: 'Nouvelle réclamation',
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ReclamationFormScreen())),
                          icon: const Icon(Icons.add))
                    ]
                  ]),
                  if (user.isAdmin) ...[
                    const SizedBox(height: 12),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            '${data.reclamations.where((r) => r.status == ReclamationStatus.pending).length} en attente · ${data.reclamations.length} au total',
                            style: const TextStyle(
                                color: AppColors.textSecondary)))
                  ]
                ])),
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.error != null)
              Padding(
                  padding: const EdgeInsets.all(12), child: Text(data.error!)),
            Expanded(
                child: rows.isEmpty
                    ? const FeatureEmpty(
                        title: 'Aucune réclamation',
                        description:
                            'Les réclamations et leur suivi apparaîtront ici.',
                        icon: Icons.support_agent)
                    : RefreshIndicator(
                        onRefresh: data.refresh,
                        child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final r = rows[i];
                              return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ReclamationDetailScreen(
                                                  id: r.id))),
                                  child: FeatureCard(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        StatusBadge(r.status.label,
                                            color: r.status ==
                                                    ReclamationStatus.rejected
                                                ? AppColors.error
                                                : AppColors.primary),
                                        const SizedBox(height: 10),
                                        Text(r.subject,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 6),
                                        Text(r.serviceTitle),
                                        if (user.isAdmin) ...[
                                          const SizedBox(height: 4),
                                          Text('${r.clientName} → ${r.proName}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary))
                                        ],
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  DateFormat('dd/MM/yyyy')
                                                      .format(r.createdAt),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textMuted))),
                                          const Icon(Icons.chevron_right)
                                        ])
                                      ])));
                            })))
          ]);
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Réclamations')), body: body);
  }
}

class ReclamationFormScreen extends StatefulWidget {
  final String? bookingId;
  final ReclamationModel? reclamation;
  const ReclamationFormScreen({super.key, this.bookingId, this.reclamation});
  @override
  State<ReclamationFormScreen> createState() => _ReclamationFormScreenState();
}

class _ReclamationFormScreenState extends State<ReclamationFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _subject, _description;
  String? _bookingId;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _subject = TextEditingController(text: widget.reclamation?.subject ?? '');
    _description =
        TextEditingController(text: widget.reclamation?.description ?? '');
    _bookingId = widget.reclamation?.bookingId ?? widget.bookingId;
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final ok = await runAction(
        context,
        () => context.read<HomeFixRepository>().saveReclamation(
            id: widget.reclamation?.id,
            bookingId: _bookingId!,
            subject: _subject.text,
            description: _description.text),
        success:
            'Réclamation enregistrée. L’administration pourra l’analyser.');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeFixData>();
    final user = context.watch<AuthService>().currentUser;
    final bookings =
        data.bookings.where((b) => b.clientId == user?.id).toList();
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.reclamation == null
                ? 'Nouvelle réclamation'
                : 'Modifier la réclamation')),
        body: user == null || user.isProfessional || user.isAdmin
            ? const FeatureEmpty(
                title: 'Espace client',
                description:
                    'Seul le client de la réservation peut déposer une réclamation.')
            : bookings.isEmpty
                ? const FeatureEmpty(
                    title: 'Une réservation est nécessaire',
                    description:
                        'Réservez une prestation avant de déposer une réclamation.')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                        key: _form,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const FeatureCard(
                                  child: Text(
                                      'Décrivez votre demande. La réservation identifie automatiquement le client et le professionnel concernés. Une fois l’analyse commencée, la réclamation ne peut plus être modifiée.')),
                              DropdownButtonFormField<String>(
                                  initialValue:
                                      bookings.any((b) => b.id == _bookingId)
                                          ? _bookingId
                                          : null,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Réservation concernée'),
                                  items: bookings
                                      .map((b) => DropdownMenuItem(
                                          value: b.id,
                                          child: Text(
                                              '${b.serviceTitle} · ${DateFormat('dd/MM/yyyy').format(b.scheduledDate)}',
                                              overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: widget.reclamation != null
                                      ? null
                                      : (v) => setState(() => _bookingId = v),
                                  validator: (v) => v == null
                                      ? 'Choisissez une réservation.'
                                      : null),
                              const SizedBox(height: 20),
                              CustomTextField(
                                  label: 'Objet',
                                  controller: _subject,
                                  validator: (v) => (v?.trim().length ?? 0) < 5
                                      ? 'Au moins 5 caractères.'
                                      : null),
                              const SizedBox(height: 16),
                              CustomTextField(
                                  label: 'Description détaillée',
                                  controller: _description,
                                  maxLines: 6,
                                  validator: (v) => (v?.trim().length ?? 0) < 20
                                      ? 'Au moins 20 caractères.'
                                      : null),
                              const SizedBox(height: 24),
                              CustomButton(
                                  text: 'Envoyer à l’administration',
                                  onPressed: _save,
                                  isLoading: _saving),
                              const SizedBox(height: 24)
                            ]))));
  }
}

class ReclamationDetailScreen extends StatefulWidget {
  final String id;
  const ReclamationDetailScreen({super.key, required this.id});
  @override
  State<ReclamationDetailScreen> createState() =>
      _ReclamationDetailScreenState();
}

class _ReclamationDetailScreenState extends State<ReclamationDetailScreen> {
  final _response = TextEditingController();
  ReclamationStatus _status = ReclamationStatus.inReview;
  bool _saving = false, _initialized = false;
  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeFixData>();
    final user = context.watch<AuthService>().currentUser;
    final rows = data.reclamations.where((r) => r.id == widget.id).toList();
    if (rows.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Réclamation')),
          body: const FeatureEmpty(title: 'Réclamation indisponible'));
    }
    final r = rows.single;
    final closed = [ReclamationStatus.resolved, ReclamationStatus.rejected]
        .contains(r.status);
    if (!_initialized) {
      _initialized = true;
      _response.text = r.adminResponse ?? '';
      _status = r.status == ReclamationStatus.pending
          ? ReclamationStatus.inReview
          : r.status;
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Détail de la réclamation')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          FeatureCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                StatusBadge(r.status.label),
                const SizedBox(height: 14),
                Text(r.subject, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SelectableText(r.description),
                const Divider(height: 28),
                DetailLine('Client', r.clientName),
                DetailLine('Professionnel', r.proName),
                DetailLine('Prestation', r.serviceTitle),
                DetailLine('Déposée le',
                    DateFormat('dd/MM/yyyy à HH:mm').format(r.createdAt)),
                TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailScreen(id: r.bookingId))),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Consulter la réservation')),
              ])),
          if (r.adminResponse?.isNotEmpty == true)
            FeatureCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Réponse de l’administration',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: 12),
                  SelectableText(r.adminResponse!),
                  if (r.reviewedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(DateFormat('dd/MM/yyyy à HH:mm').format(r.reviewedAt!),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted))
                  ]
                ])),
          if (user?.id == r.clientId &&
              r.status == ReclamationStatus.pending) ...[
            CustomButton(
                text: 'Modifier',
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ReclamationFormScreen(reclamation: r)))),
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: () async {
                  if (!await confirmAction(
                      context,
                      'Supprimer cette réclamation ?',
                      'Cette action concerne uniquement la réclamation en attente.')) {
                    return;
                  }
                  if (!context.mounted) return;
                  final ok = await runAction(
                      context,
                      () => context
                          .read<HomeFixRepository>()
                          .deleteReclamation(r.id),
                      success: 'Réclamation supprimée.');
                  if (context.mounted && ok) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer'))
          ],
          if (user?.isAdmin == true && !closed)
            FeatureCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Text('Analyse administrative',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ReclamationStatus>(
                      initialValue: _status,
                      decoration:
                          const InputDecoration(labelText: 'Décision / suivi'),
                      items: ReclamationStatus.values
                          .where((s) => s != ReclamationStatus.pending)
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged:
                          _saving ? null : (v) => setState(() => _status = v!)),
                  const SizedBox(height: 16),
                  CustomTextField(
                      label: 'Réponse et justification',
                      controller: _response,
                      maxLines: 5),
                  const SizedBox(height: 20),
                  CustomButton(
                      text: 'Enregistrer le traitement',
                      isLoading: _saving,
                      onPressed: () async {
                        if (_saving) return;
                        setState(() => _saving = true);
                        await runAction(
                            context,
                            () => context
                                .read<HomeFixRepository>()
                                .reviewReclamation(
                                    r.id, _status, _response.text),
                            success: 'Réclamation mise à jour.');
                        if (mounted) setState(() => _saving = false);
                      })
                ])),
          if (closed)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'Cette réclamation est clôturée. La décision administrative est conservée dans l’historique.')),
        ]));
  }
}
