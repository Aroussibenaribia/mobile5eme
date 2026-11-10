import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

class DemoAccountsCard extends StatelessWidget {
  const DemoAccountsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Material(
            color: AppColors.primaryLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
                title: const Text('Découvrir les comptes de démonstration'),
                subtitle: const Text('Client · Professionnel · Administrateur'),
                children: [
                  const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                          'Mot de passe : HomeFix123!\nLes comptes et les données sont stockés sur cet appareil.')),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final account in const [
                      ('Client', 'client@homefix.com'),
                      ('Professionnel', 'pro@homefix.com'),
                      ('Admin', 'admin@homefix.com')
                    ])
                      OutlinedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  final ok = await auth.login(
                                      email: account.$2,
                                      password: 'HomeFix123!');
                                  if (context.mounted && ok) {
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(auth.errorMessage ??
                                              'Connexion impossible. Réessayez.')),
                                    );
                                  }
                                },
                          child: Text(account.$1)),
                  ]),
                  const SizedBox(height: 12)
                ])));
  }
}
