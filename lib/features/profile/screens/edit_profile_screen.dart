import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/work_schedule.dart';
import '../../../services/auth_service.dart';
import '../../../services/professional_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _phone, _city, _address;
  final _bio = TextEditingController();
  final Set<String> _days = {};
  bool _acceptsBookings = true, _ready = false, _saving = false;
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _name = TextEditingController(text: user?.fullName);
    _phone = TextEditingController(text: user?.phone);
    _city = TextEditingController(text: user?.city);
    _address = TextEditingController(text: user?.address);
    if (user?.isProfessional != true) {
      _ready = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProfessional();
      });
    }
  }

  Future<void> _loadProfessional() async {
    final source = context.read<ProfessionalService>();
    await source.loadProfessionals();
    if (!mounted) return;
    final pro = source.getById(context.read<AuthService>().currentUser!.id);
    if (pro == null) {
      setState(() {});
      return;
    }
    _bio.text = pro.bio;
    _days.addAll(pro.availableDays);
    setState(() {
      _acceptsBookings = pro.isAvailable;
      _ready = true;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _address, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    final auth = context.read<AuthService>();
    final professional = auth.currentUser?.isProfessional == true;
    if (professional && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Choisissez au moins un jour de travail.')));
      return;
    }
    setState(() => _saving = true);
    final ok = await runAction(
        context,
        () => auth.updateProfile(
            fullName: _name.text,
            phone: _phone.text,
            city: _city.text,
            address: _address.text,
            bio: professional ? _bio.text : null,
            availableDays: professional ? WorkSchedule.ordered(_days) : null,
            isAvailable: professional ? _acceptsBookings : null),
        success: 'Profil et disponibilités enregistrés.');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    return Scaffold(
        appBar: AppBar(title: const Text('Modifier mon profil')),
        body: user == null
            ? const FeatureEmpty(
                title: 'Connectez-vous pour modifier votre profil')
            : !_ready
                ? Center(
                    child: TextButton(
                        onPressed: _loadProfessional,
                        child: const Text('Charger mon profil professionnel')))
                : ContentWidth(
                    child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
                        child: Form(
                            key: _form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const PageIntro(
                                      title: 'Vos informations,\nà jour.',
                                      description:
                                          'Les clients retrouvent ces informations sur votre fiche.'),
                                  CustomTextField(
                                      label: 'Nom complet',
                                      controller: _name,
                                      prefixIcon: Icons.person_outline,
                                      validator: (v) =>
                                          (v?.trim().length ?? 0) < 2
                                              ? 'Indiquez votre nom complet.'
                                              : null),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                      label: 'Numéro de téléphone',
                                      controller: _phone,
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: Icons.phone_outlined,
                                      validator: (v) =>
                                          (v?.trim().length ?? 0) < 8
                                              ? 'Au moins 8 caractères.'
                                              : null),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                      label: 'Ville',
                                      controller: _city,
                                      prefixIcon: Icons.location_city_outlined,
                                      validator: (v) =>
                                          (v?.trim().length ?? 0) < 2
                                              ? 'Indiquez votre ville.'
                                              : null),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                      label: 'Adresse complète',
                                      controller: _address,
                                      maxLines: 2,
                                      prefixIcon: Icons.home_outlined),
                                  if (user.isProfessional) ...[
                                    const SectionHeading('Votre activité'),
                                    CustomTextField(
                                        label: 'Présentation',
                                        controller: _bio,
                                        maxLines: 4),
                                    const SectionHeading('Jours de travail'),
                                    const Text(
                                        'Sélectionnez les jours où vous acceptez de nouvelles interventions.'),
                                    const SizedBox(height: 14),
                                    WeekDays(
                                        selected: WorkSchedule.ordered(_days),
                                        onToggle: (day) => setState(() {
                                              if (!_days.add(day)) {
                                                _days.remove(day);
                                              }
                                            })),
                                    const SizedBox(height: 16),
                                    const Text(
                                        'Créneaux de réservation : 08h–19h. Les rendez-vous déjà acceptés restent à honorer.'),
                                    const SizedBox(height: 12),
                                    SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                            'Accepter de nouvelles réservations'),
                                        subtitle: Text(_acceptsBookings
                                            ? 'Votre planning est ouvert.'
                                            : 'Les nouvelles réservations sont en pause.'),
                                        value: _acceptsBookings,
                                        onChanged: (v) => setState(
                                            () => _acceptsBookings = v)),
                                  ],
                                  const SizedBox(height: 28),
                                  CustomButton(
                                      text: 'Enregistrer les modifications',
                                      isLoading: _saving,
                                      onPressed: _save),
                                ])))));
  }
}
