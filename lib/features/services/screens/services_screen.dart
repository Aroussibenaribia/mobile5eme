import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/homefix_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/service_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/homefix_data.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeFixData>();
    final user = context.watch<AuthService>().currentUser;
    return Scaffold(
        appBar: AppBar(title: const Text('Mes prestations')),
        floatingActionButton: user?.isProfessional == true
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ServiceEditorScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une prestation'))
            : null,
        body: user?.isProfessional != true
            ? const FeatureEmpty(
                title: 'Espace professionnel',
                description:
                    'Connectez-vous avec un compte professionnel pour gérer vos prestations.')
            : data.isLoading && data.services.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : data.error != null
                    ? FeatureEmpty(
                        title: data.error!,
                        action: TextButton(
                            onPressed: data.refresh,
                            child: const Text('Réessayer')))
                    : data.services.isEmpty
                        ? const FeatureEmpty(
                            title: 'Votre catalogue commence ici',
                            description:
                                'Ajoutez votre première prestation, son tarif et sa durée.',
                            icon: Icons.home_repair_service_outlined)
                        : RefreshIndicator(
                            onRefresh: data.refresh,
                            child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                itemCount: data.services.length,
                                itemBuilder: (context, index) {
                                  final service = data.services[index];
                                  return FeatureCard(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Row(children: [
                                          Expanded(
                                              child: Text(service.title,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium)),
                                          StatusBadge(
                                              service.isActive
                                                  ? 'Active'
                                                  : 'Archivée',
                                              color: service.isActive
                                                  ? AppColors.primary
                                                  : AppColors.textMuted)
                                        ]),
                                        const SizedBox(height: 8),
                                        Text(service.description),
                                        const SizedBox(height: 12),
                                        Text(
                                            '${service.price.toStringAsFixed(2)} DT · ${service.duration}',
                                            style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold)),
                                        const Divider(height: 24),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                  onPressed: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (_) =>
                                                              ServiceEditorScreen(
                                                                  service:
                                                                      service))),
                                                  icon: const Icon(
                                                      Icons.edit_outlined),
                                                  label:
                                                      const Text('Modifier')),
                                              TextButton.icon(
                                                  onPressed: () async {
                                                    if (!await confirmAction(
                                                        context,
                                                        'Retirer cette prestation ?',
                                                        'Une prestation déjà réservée sera archivée pour conserver les réservations.')) {
                                                      return;
                                                    }
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    await runAction(context,
                                                        () async {
                                                      await context
                                                          .read<
                                                              HomeFixRepository>()
                                                          .deleteService(
                                                              service.id);
                                                    },
                                                        success:
                                                            'Catalogue mis à jour.');
                                                  },
                                                  icon: const Icon(
                                                      Icons.delete_outline),
                                                  label: const Text('Retirer'))
                                            ])
                                      ]));
                                })));
  }
}

class ServiceEditorScreen extends StatefulWidget {
  final ServiceModel? service;
  const ServiceEditorScreen({super.key, this.service});
  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _description, _price, _duration;
  late bool _active;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _title = TextEditingController(text: s?.title ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _price = TextEditingController(text: s?.price.toStringAsFixed(2) ?? '');
    _duration =
        TextEditingController(text: (s?.durationMinutes ?? 60).toString());
    _active = s?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _duration]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final success = await runAction(
        context,
        () => context.read<HomeFixRepository>().saveService(
            id: widget.service?.id,
            title: _title.text,
            description: _description.text,
            price: double.parse(_price.text.replaceAll(',', '.')),
            durationMinutes: int.parse(_duration.text),
            isActive: _active),
        success: 'Prestation enregistrée.');
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.service == null
              ? 'Nouvelle prestation'
              : 'Modifier la prestation')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
              key: _form,
              child: Column(children: [
                const FeatureCard(
                    child: Text(
                        'Présentez clairement votre intervention. Les réservations conserveront le tarif convenu, même si vous le modifiez ensuite.')),
                CustomTextField(
                    label: 'Titre',
                    controller: _title,
                    validator: (v) => (v?.trim().length ?? 0) < 3
                        ? 'Au moins 3 caractères.'
                        : null),
                const SizedBox(height: 16),
                CustomTextField(
                    label: 'Description',
                    controller: _description,
                    maxLines: 4,
                    validator: (v) => (v?.trim().length ?? 0) < 10
                        ? 'Au moins 10 caractères.'
                        : null),
                const SizedBox(height: 16),
                CustomTextField(
                    label: 'Prix de la prestation (DT)',
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return n == null || !n.isFinite || n <= 0
                          ? 'Indiquez un prix positif.'
                          : null;
                    }),
                const SizedBox(height: 16),
                CustomTextField(
                    label: 'Durée estimée (minutes)',
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return n == null || n < 15 || n > 480
                          ? 'Entre 15 et 480 minutes.'
                          : null;
                    }),
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible à la réservation'),
                    value: _active,
                    onChanged:
                        _saving ? null : (v) => setState(() => _active = v)),
                const SizedBox(height: 16),
                CustomButton(
                    text: 'Enregistrer', onPressed: _save, isLoading: _saving),
                const SizedBox(height: 24)
              ]))));
}
