import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/data/homefix_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/booking_model.dart';
import '../../../models/work_schedule.dart';
import '../../../models/professional_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/homefix_data.dart';
import '../../auth/screens/login_screen.dart';
import '../../reviews_and_history/screens/reclamation_screens.dart';

class BookingListScreen extends StatefulWidget {
  final bool embedded, historyOnly;
  const BookingListScreen(
      {super.key, this.embedded = false, this.historyOnly = false});
  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  BookingStatus? _filter;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeFixData>();
    final user = context.watch<AuthService>().currentUser;
    final rows = data.bookings
        .where((b) =>
            (!widget.historyOnly ||
                [BookingStatus.completed, BookingStatus.cancelled]
                    .contains(b.status)) &&
            (_filter == null || b.status == _filter))
        .toList();
    final body = user == null
        ? FeatureEmpty(
            title: 'Vos réservations, au même endroit',
            description:
                'Connectez-vous pour réserver une prestation et suivre vos interventions.',
            action: FilledButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Se connecter')))
        : Column(children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<BookingStatus?>(
                    initialValue: _filter,
                    decoration:
                        const InputDecoration(labelText: 'Filtrer par statut'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Tous les statuts')),
                      ...BookingStatus.values.map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.label)))
                    ],
                    onChanged: (v) => setState(() => _filter = v))),
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.error != null)
              Padding(
                  padding: const EdgeInsets.all(16), child: Text(data.error!)),
            Expanded(
                child: rows.isEmpty
                    ? const FeatureEmpty(
                        title: 'Aucune réservation',
                        description:
                            'Les interventions correspondant à ce filtre apparaîtront ici.',
                        icon: Icons.calendar_month_outlined)
                    : RefreshIndicator(
                        onRefresh: data.refresh,
                        child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final b = rows[i];
                              return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              BookingDetailScreen(id: b.id))),
                                  child: FeatureCard(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Row(children: [
                                          Expanded(
                                              child: Text(b.serviceTitle,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium)),
                                          StatusBadge(b.status.label)
                                        ]),
                                        const SizedBox(height: 8),
                                        Text(user.isProfessional
                                            ? b.clientName
                                            : b.proName),
                                        const SizedBox(height: 4),
                                        Text(DateFormat('dd/MM/yyyy · HH:mm')
                                            .format(b.scheduledDate)),
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  '${b.estimatedPrice.toStringAsFixed(2)} DT',
                                                  style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                          const Icon(Icons.chevron_right)
                                        ])
                                      ])));
                            })))
          ]);
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Réservations')), body: body);
  }
}

class BookingFormScreen extends StatefulWidget {
  final ProfessionalModel professional;
  final ServiceModel service;
  const BookingFormScreen(
      {super.key, required this.professional, required this.service});
  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController(), _notes = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false, _addressInitialized = false;
  @override
  void initState() {
    super.initState();
    for (var i = 1; i <= 7; i++) {
      final candidate =
          DateUtils.dateOnly(DateTime.now().add(Duration(days: i)));
      if (widget.professional.availableDays
          .contains(WorkSchedule.days[candidate.weekday - 1])) {
        _date = candidate;
        break;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_addressInitialized) {
      _addressInitialized = true;
      final user = context.read<AuthService>().currentUser;
      _address.text = [user?.address ?? '', user?.city ?? '']
          .where((x) => x.isNotEmpty)
          .join(', ');
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    String? id;
    final success = await runAction(context, () async {
      id = await context.read<HomeFixRepository>().book(
          serviceId: widget.service.id,
          expectedPrice: widget.service.price,
          scheduledDate: DateTime(
              _date.year, _date.month, _date.day, _time.hour, _time.minute),
          address: _address.text,
          notes: _notes.text);
    }, success: 'Votre demande de réservation a été enregistrée.');
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => BookingDetailScreen(id: id!)));
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Réserver une prestation')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FeatureCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(widget.service.title,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                              '${widget.professional.name} · ${widget.professional.specialty}'),
                          const SizedBox(height: 8),
                          Text(
                              '${widget.service.price.toStringAsFixed(2)} DT · ${widget.service.duration}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              'Disponibilités : ${widget.professional.availableDays.join(', ')}')
                        ])),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Date'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: () async {
                          final d = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              selectableDayPredicate: (day) => widget
                                  .professional.availableDays
                                  .contains(WorkSchedule.days[day.weekday - 1]),
                              firstDate: DateUtils.dateOnly(DateTime.now()),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)));
                          if (d != null && mounted) setState(() => _date = d);
                        }),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: const Text('Heure'),
                        subtitle: Text(_time.format(context)),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () async {
                          final t = await showTimePicker(
                              context: context, initialTime: _time);
                          if (t != null && mounted) setState(() => _time = t);
                        }),
                    const SizedBox(height: 16),
                    CustomTextField(
                        label: 'Adresse de l’intervention',
                        controller: _address,
                        prefixIcon: Icons.location_on_outlined,
                        validator: (v) => (v?.trim().length ?? 0) < 5
                            ? 'Indiquez une adresse complète.'
                            : null),
                    const SizedBox(height: 16),
                    CustomTextField(
                        label: 'Informations complémentaires (facultatif)',
                        controller: _notes,
                        maxLines: 3),
                    const SizedBox(height: 24),
                    CustomButton(
                        text: 'Confirmer la demande',
                        onPressed: _submit,
                        isLoading: _saving),
                    const SizedBox(height: 20)
                  ]))));
}

class BookingDetailScreen extends StatelessWidget {
  final String id;
  const BookingDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeFixData>();
    final user = context.watch<AuthService>().currentUser;
    final matches = data.bookings.where((b) => b.id == id).toList();
    if (matches.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Réservation')),
          body: const FeatureEmpty(title: 'Réservation indisponible'));
    }
    final b = matches.single;
    final transitions = <BookingStatus, BookingStatus>{
      BookingStatus.pending: BookingStatus.confirmed,
      BookingStatus.confirmed: BookingStatus.inProgress,
      BookingStatus.inProgress: BookingStatus.completed
    };
    final labels = <BookingStatus, String>{
      BookingStatus.confirmed: 'Confirmer la réservation',
      BookingStatus.inProgress: 'Démarrer l’intervention',
      BookingStatus.completed: 'Terminer l’intervention'
    };
    return Scaffold(
        appBar: AppBar(title: const Text('Détail de la réservation')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          FeatureCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                StatusBadge(b.status.label),
                const SizedBox(height: 16),
                Text(b.serviceTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                DetailLine('Professionnel', '${b.proName} · ${b.proSpecialty}'),
                DetailLine('Client', b.clientName),
                DetailLine('Rendez-vous',
                    DateFormat('dd/MM/yyyy à HH:mm').format(b.scheduledDate)),
                DetailLine('Adresse', b.address),
                DetailLine('Tarif convenu',
                    '${b.estimatedPrice.toStringAsFixed(2)} DT'),
                DetailLine('Durée estimée', '${b.durationMinutes} min'),
                if (b.clientNotes?.isNotEmpty == true)
                  DetailLine('Informations complémentaires', b.clientNotes!),
              ])),
          if (user?.isProfessional == true &&
              transitions.containsKey(b.status)) ...[
            CustomButton(
                text: labels[transitions[b.status]]!,
                onPressed: () => runAction(
                    context,
                    () => context
                        .read<HomeFixRepository>()
                        .updateBookingStatus(b.id, transitions[b.status]!),
                    success: 'Statut mis à jour.')),
            const SizedBox(height: 12)
          ],
          if ([BookingStatus.pending, BookingStatus.confirmed]
                  .contains(b.status) &&
              user?.isAdmin != true) ...[
            CustomButton(
                text: 'Annuler la réservation',
                variant: ButtonVariant.outline,
                onPressed: () async {
                  if (await confirmAction(context, 'Annuler la réservation ?',
                      'Le créneau sera libéré.')) {
                    if (context.mounted) {
                      await runAction(
                          context,
                          () => context
                              .read<HomeFixRepository>()
                              .updateBookingStatus(
                                  b.id, BookingStatus.cancelled),
                          success: 'Réservation annulée.');
                    }
                  }
                }),
            const SizedBox(height: 12)
          ],
          if (user?.id == b.clientId)
            CustomButton(
                text: 'Déposer une réclamation',
                variant: ButtonVariant.outline,
                icon: Icons.support_agent,
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ReclamationFormScreen(bookingId: b.id)))),
          const SizedBox(height: 16),
          const Text(
              'Le tarif convenu reste associé à cette réservation. Les réclamations sont analysées par l’administration.',
              style: TextStyle(color: AppColors.textSecondary)),
        ]));
  }
}
