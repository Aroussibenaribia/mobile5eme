import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/service_category_model.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _phone = TextEditingController(),
      _city = TextEditingController(text: 'Tunis'),
      _password = TextEditingController(),
      _bio = TextEditingController(),
      _experience = TextEditingController(text: '1');
  UserRole _role = UserRole.client;
  String _trade = 'Plomberie';
  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _city,
      _password,
      _bio,
      _experience
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthService>();
    final ok = _role == UserRole.client
        ? await auth.registerClient(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            phone: _phone.text,
            city: _city.text)
        : await auth.registerProfessional(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            phone: _phone.text,
            city: _city.text,
            specialty: _trade,
            hourlyRate: 35,
            experienceYears: int.parse(_experience.text),
            bio: _bio.text);
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
        appBar: AppBar(title: const Text('Créer un compte')),
        body: ContentWidth(
            maxWidth: 560,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Form(
                    key: _form,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PageIntro(
                              title: 'Du projet\nau rendez-vous.',
                              description:
                                  'Choisissez votre espace pour commencer.'),
                          SegmentedButton<UserRole>(
                              segments: const [
                                ButtonSegment(
                                    value: UserRole.client,
                                    icon: Icon(Icons.home_outlined),
                                    label: Text('Client')),
                                ButtonSegment(
                                    value: UserRole.professional,
                                    icon: Icon(Icons.handyman_outlined),
                                    label: Text('Artisan')),
                              ],
                              selected: {
                                _role
                              },
                              onSelectionChanged: (value) =>
                                  setState(() => _role = value.single)),
                          const SizedBox(height: 24),
                          CustomTextField(
                              label: 'Nom complet',
                              controller: _name,
                              prefixIcon: Icons.person_outline,
                              validator: (v) => (v?.trim().length ?? 0) < 2
                                  ? 'Indiquez votre nom complet.'
                                  : null),
                          const SizedBox(height: 18),
                          CustomTextField(
                              label: 'Adresse e-mail',
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.alternate_email,
                              validator: (v) => (v?.contains('@') ?? false)
                                  ? null
                                  : 'Adresse e-mail invalide.'),
                          const SizedBox(height: 18),
                          CustomTextField(
                              label: 'Téléphone',
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (v) => (v?.trim().length ?? 0) < 8
                                  ? 'Au moins 8 caractères.'
                                  : null),
                          const SizedBox(height: 18),
                          CustomTextField(
                              label: 'Ville',
                              controller: _city,
                              prefixIcon: Icons.location_city_outlined,
                              validator: (v) => (v?.trim().length ?? 0) < 2
                                  ? 'Indiquez votre ville.'
                                  : null),
                          const SizedBox(height: 18),
                          CustomTextField(
                              label: 'Mot de passe',
                              controller: _password,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) => (v?.length ?? 0) < 8
                                  ? 'Au moins 8 caractères.'
                                  : null),
                          if (_role == UserRole.professional) ...[
                            const SectionHeading('Votre métier'),
                            DropdownButtonFormField<String>(
                                initialValue: _trade,
                                decoration: const InputDecoration(
                                    labelText: 'Spécialité'),
                                items: ServiceCategoryModel.defaultCategories
                                    .map((c) => DropdownMenuItem(
                                        value: c.title, child: Text(c.title)))
                                    .toList(),
                                onChanged: (v) => setState(() => _trade = v!)),
                            const SizedBox(height: 18),
                            CustomTextField(
                                label: 'Années d’expérience',
                                controller: _experience,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final years = int.tryParse(v ?? '');
                                  return years == null ||
                                          years < 0 ||
                                          years > 80
                                      ? 'De 0 à 80 ans.'
                                      : null;
                                }),
                            const SizedBox(height: 18),
                            CustomTextField(
                                label: 'Présentez votre savoir-faire',
                                controller: _bio,
                                maxLines: 3),
                            const SizedBox(height: 12),
                            const Text(
                                'Après inscription, ajoutez vos prestations et choisissez vos jours de travail dans votre profil.'),
                          ],
                          const SizedBox(height: 24),
                          if (auth.errorMessage != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(auth.errorMessage!,
                                    style: const TextStyle(
                                        color: AppColors.error))),
                          CustomButton(
                              text: 'Créer mon compte',
                              isLoading: auth.isLoading,
                              onPressed: _register),
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Déjà inscrit ? Se connecter')),
                        ])))));
  }
}
