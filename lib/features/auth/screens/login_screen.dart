import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../widgets/demo_accounts_card.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _remember = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<AuthService>().login(
        email: _email.text, password: _password.text, rememberMe: _remember);
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
        appBar: AppBar(),
        body: ContentWidth(
            maxWidth: 500,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Form(
                    key: _form,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(children: [
                            CraftMark(),
                            SizedBox(width: 12),
                            Text('HomeFix',
                                style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.8))
                          ]),
                          const SizedBox(height: 36),
                          const PageIntro(
                              title: 'Ravi de\nvous retrouver.',
                              description:
                                  'Votre maison, vos artisans, vos rendez-vous.'),
                          AutofillGroup(
                              child: Column(children: [
                            CustomTextField(
                                label: 'Adresse e-mail',
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.alternate_email,
                                validator: (v) => (v?.contains('@') ?? false)
                                    ? null
                                    : 'Indiquez votre adresse e-mail.'),
                            const SizedBox(height: 18),
                            CustomTextField(
                                label: 'Mot de passe',
                                controller: _password,
                                isPassword: true,
                                prefixIcon: Icons.lock_outline,
                                validator: (v) => (v?.isNotEmpty ?? false)
                                    ? null
                                    : 'Indiquez votre mot de passe.'),
                          ])),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('Se souvenir de moi',
                                  style: TextStyle(fontSize: 13)),
                              value: _remember,
                              onChanged: (v) =>
                                  setState(() => _remember = v ?? true)),
                          if (auth.errorMessage != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(auth.errorMessage!,
                                    style: const TextStyle(
                                        color: AppColors.error))),
                          CustomButton(
                              text: 'Se connecter',
                              isLoading: auth.isLoading,
                              onPressed: _login),
                          TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen())),
                              child: const Text('Mot de passe oublié ?')),
                          const Divider(height: 32),
                          const DemoAccountsCard(),
                          const SizedBox(height: 20),
                          TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                              child:
                                  const Text('Nouveau ici ? Créer un compte')),
                        ])))));
  }
}
