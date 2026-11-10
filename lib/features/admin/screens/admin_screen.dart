import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/homefix_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/homefix_data.dart';
import '../../reviews_and_history/screens/reclamation_screens.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthService>().currentUser?.isAdmin != true) {
      return const Scaffold(
          body: FeatureEmpty(title: 'Accès administrateur requis'));
    }
    return Scaffold(
        appBar: AppBar(
            title: Text(_index == 0 ? 'Réclamations' : 'Utilisateurs'),
            leading: const Icon(Icons.admin_panel_settings_outlined,
                color: AppColors.primary),
            actions: [
              IconButton(
                  tooltip: 'Actualiser',
                  onPressed: context.read<HomeFixData>().refresh,
                  icon: const Icon(Icons.refresh)),
              IconButton(
                  tooltip: 'Se déconnecter',
                  onPressed: () => runAction(
                      context, () => context.read<AuthService>().logout()),
                  icon: const Icon(Icons.logout))
            ]),
        body: IndexedStack(index: _index, children: const [
          ReclamationListScreen(embedded: true),
          AdminUsersScreen()
        ]),
        bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (v) => setState(() => _index = v),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.support_agent), label: 'Réclamations'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline), label: 'Utilisateurs')
            ]));
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _query = '';
  UserRole? _role;
  Future<void> _details(UserModel user) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        ProAvatar(
                            name: user.fullName,
                            imageUrl: user.avatarUrl,
                            radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(user.fullName,
                                style: Theme.of(ctx).textTheme.titleLarge))
                      ]),
                      const SizedBox(height: 16),
                      StatusBadge(user.role.label),
                      DetailLine('Adresse e-mail', user.email),
                      DetailLine('Téléphone', user.phone),
                      DetailLine('Ville', user.city),
                      DetailLine('Adresse', user.address),
                      DetailLine(
                          'Compte', user.isActive ? 'Actif' : 'Suspendu'),
                      if (!user.isAdmin) ...[
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                            icon: Icon(user.isActive
                                ? Icons.block
                                : Icons.check_circle_outline),
                            label: Text(user.isActive
                                ? 'Suspendre le compte'
                                : 'Réactiver le compte'),
                            onPressed: () async {
                              if (!await confirmAction(
                                  ctx,
                                  user.isActive
                                      ? 'Suspendre ce compte ?'
                                      : 'Réactiver ce compte ?',
                                  'Les réservations et réclamations seront conservées.')) {
                                return;
                              }
                              if (!ctx.mounted) return;
                              final ok = await runAction(
                                  ctx,
                                  () => ctx
                                      .read<HomeFixRepository>()
                                      .setUserActive(user.id, !user.isActive),
                                  success: 'Compte mis à jour.');
                              if (ctx.mounted && ok) Navigator.pop(ctx);
                            }),
                        OutlinedButton.icon(
                            icon: const Icon(Icons.lock_reset),
                            label: const Text('Réinitialiser le mot de passe'),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _reset(user);
                            })
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Fermer'))
                    ]))));
  }

  Future<void> _reset(UserModel user) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Nouveau mot de passe'),
                content: TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: '8 caractères minimum')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      child: const Text('Enregistrer'))
                ]));
    controller.dispose();
    if (password == null || !mounted) return;
    await runAction(
        context,
        () => context
            .read<HomeFixRepository>()
            .resetUserPassword(user.id, password),
        success: 'Mot de passe réinitialisé.');
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HomeFixData>();
    if (context.watch<AuthService>().currentUser?.isAdmin != true) {
      return const FeatureEmpty(title: 'Accès non autorisé');
    }
    final users = data.users
        .where((u) =>
            (_role == null || u.role == _role) &&
            ('${u.fullName} ${u.email} ${u.city}')
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                decoration: const InputDecoration(
                    hintText: 'Nom, e-mail ou ville',
                    prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole?>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Type de compte'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Tous les utilisateurs')),
                  ...UserRole.values.map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.label)))
                ],
                onChanged: (v) => setState(() => _role = v))
          ])),
      if (data.isLoading) const LinearProgressIndicator(),
      if (data.error != null)
        Padding(padding: const EdgeInsets.all(12), child: Text(data.error!)),
      Expanded(
          child: users.isEmpty
              ? const FeatureEmpty(title: 'Aucun utilisateur trouvé')
              : RefreshIndicator(
                  onRefresh: data.refresh,
                  child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final user = users[i];
                        return FeatureCard(
                            child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: ProAvatar(
                                    name: user.fullName,
                                    imageUrl: user.avatarUrl,
                                    radius: 22),
                                title: Text(user.fullName),
                                subtitle: Text(
                                    '${user.role.label} · ${user.city}${user.isActive ? '' : ' · Suspendu'}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _details(user)));
                      })))
    ]);
  }
}
