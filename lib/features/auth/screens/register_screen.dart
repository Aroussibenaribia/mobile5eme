import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  UserRole _selectedRole = UserRole.client;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController(text: 'Tunis');
  final _passwordController = TextEditingController();

  // Pro specific controllers
  String _selectedSpecialty = 'Plomberie';
  final _hourlyRateController = TextEditingController(text: '35');
  final _experienceController = TextEditingController(text: '5');
  final _bioController = TextEditingController();

  final List<String> _specialties = [
    'Plomberie',
    'Électricité',
    'Climatisation',
    'Nettoyage',
    'Peinture',
    'Informatique',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    bool success;

    if (_selectedRole == UserRole.client) {
      success = await auth.registerClient(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        city: _cityController.text,
      );
    } else {
      success = await auth.registerProfessional(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        specialty: _selectedSpecialty,
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 30.0,
        experienceYears: int.tryParse(_experienceController.text) ?? 3,
        bio: _bioController.text,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte ${_selectedRole.label} créé avec succès !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenue sur HomeFix',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sélectionnez votre profil pour commencer.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),

                const SizedBox(height: 20),

                // Role Selector Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = UserRole.client;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.client
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedRole == UserRole.client
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: _selectedRole == UserRole.client
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Je suis un Client',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _selectedRole == UserRole.client
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = UserRole.professional;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.professional
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedRole == UserRole.professional
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.handyman_outlined,
                                    size: 18,
                                    color: _selectedRole == UserRole.professional
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Je suis un Pro',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _selectedRole == UserRole.professional
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Common fields
                CustomTextField(
                  label: 'Nom complet',
                  hint: _selectedRole == UserRole.client ? 'Ex: Sarra Mansouri' : 'Ex: Karim Ben Ali',
                  controller: _fullNameController,
                  prefixIcon: Icons.person_outline,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Ce champ est requis' : null,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Adresse e-mail',
                  hint: 'nom@exemple.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Adresse e-mail requise';
                    if (!val.contains('@')) return 'E-mail non valide';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Téléphone',
                        hint: '+216 22 000 000',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Ville',
                        hint: 'Tunis',
                        controller: _cityController,
                        prefixIcon: Icons.location_city_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Mot de passe',
                  hint: 'Au moins 6 caractères',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (val) => val == null || val.length < 6 ? 'Au moins 6 caractères' : null,
                ),

                // If Professional: display specialized business fields
                if (_selectedRole == UserRole.professional) ...[
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 16),
                  const Text(
                    'Informations Professionnelles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specialty dropdown
                  const Text(
                    'Corps de métier / Spécialité',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSpecialty,
                    items: _specialties.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSpecialty = val;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Tarif horaire (DT)',
                          hint: '35',
                          controller: _hourlyRateController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Expérience (ans)',
                          hint: '5',
                          controller: _experienceController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.history_edu_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Bio / Présentation de vos services',
                    hint: 'Décrivez brièvement vos compétences, vos garanties de travail...',
                    controller: _bioController,
                    maxLines: 3,
                  ),
                ],

                const SizedBox(height: 28),

                CustomButton(
                  text: _selectedRole == UserRole.client
                      ? 'Créer mon compte Client'
                      : 'Créer mon compte Professionnel',
                  isLoading: auth.isLoading,
                  onPressed: _handleRegister,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte ? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
