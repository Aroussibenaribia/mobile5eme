import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/homefix_repository.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _old = TextEditingController(), _next = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    return Scaffold(
        appBar: AppBar(title: const Text('Mot de passe')),
        body: user == null
            ? const FeatureEmpty(
                title: 'Récupération de compte',
                icon: Icons.lock_reset,
                description:
                    'Contactez l’administration pour réinitialiser votre mot de passe sur cet appareil. Les comptes de démonstration utilisent HomeFix123!.')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  CustomTextField(
                      label: 'Mot de passe actuel',
                      controller: _old,
                      isPassword: true),
                  const SizedBox(height: 20),
                  CustomTextField(
                      label: 'Nouveau mot de passe (8 caractères minimum)',
                      controller: _next,
                      isPassword: true),
                  const SizedBox(height: 24),
                  CustomButton(
                      text: 'Modifier le mot de passe',
                      isLoading: _saving,
                      onPressed: () async {
                        if (_saving) return;
                        setState(() => _saving = true);
                        final ok = await runAction(
                            context,
                            () => context
                                .read<HomeFixRepository>()
                                .changePassword(_old.text, _next.text),
                            success: 'Mot de passe modifi?.');
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _saving = false);
                        }
                      })
                ])));
  }
}
