import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/professional_model.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/forgot_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfessionalModel? _proProfile;
  bool _loadingPro = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null && user.isProfessional) {
        _loadProProfile(user.id);
      }
    });
  }

  Future<void> _loadProProfile(String uid) async {
    setState(() => _loadingPro = true);
    try {
      if (Firebase.apps.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('professionals')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null && mounted) {
          setState(() => _proProfile = ProfessionalModel.fromMap(doc.data()!, doc.id));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPro = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthService>().currentUser;
    if (user != null && user.isProfessional && _proProfile == null && !_loadingPro) {
      _loadProProfile(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    if (user == null) {
      return _buildNotLoggedIn(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Gradient SliverAppBar ──
          SliverAppBar(
            expandedHeight: user.isProfessional ? 260 : 200,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildProfileHeader(context, user, auth),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) {
                  if (user.isProfessional) _loadProProfile(user.id);
                }),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (user.isProfessional) ...[
                    _buildProStats(user),
                    const SizedBox(height: 16),
                    if (_loadingPro)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_proProfile != null)
                      _buildProDetails(context, _proProfile!)
                    else
                      _buildSetupProBanner(context, user),
                    const SizedBox(height: 16),
                  ],


                  // ── Settings Menu ──
                  _buildSettingsSection(context, user, auth),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NOT LOGGED IN ──────────────────────────────────────────────────────────

  Widget _buildNotLoggedIn(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, Color(0xFF134E4A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.person_outline_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Rejoignez HomeFix',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connectez-vous pour accéder à vos réservations,\nvotre profil et vos artisans favoris.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.secondary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context, UserModel user, AuthService auth) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, Color(0xFF0D9488)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                          ? Text(
                              _initials(user.fullName),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRoleBadge(user),
                      ],
                    ),
                  ),
                ],
              ),

              if (user.city.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      user.city,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.phone_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        user.phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: user.isProfessional
            ? Colors.amber.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: user.isProfessional
              ? Colors.amber.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user.isProfessional ? Icons.handyman_rounded : Icons.verified_user_rounded,
            size: 12,
            color: user.isProfessional ? Colors.amber : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            user.isProfessional ? 'Artisan Certifié' : 'Client Particulier',
            style: TextStyle(
              color: user.isProfessional ? Colors.amber : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── PRO STATS ────────────────────────────────────────────────────────────────

  Widget _buildProStats(UserModel user) {
    final pro = _proProfile;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCol(
            pro?.rating.toStringAsFixed(1) ?? '—',
            '${pro?.reviewCount ?? 0} avis',
            Icons.star_rounded,
            Colors.amber,
          ),
          Container(width: 1, height: 40, color: AppColors.cardBorder),
          _statCol(
            '${pro?.experienceYears ?? '—'}',
            'ans d\'exp.',
            Icons.work_rounded,
            AppColors.primary,
          ),
          Container(width: 1, height: 40, color: AppColors.cardBorder),
          _statCol(
            pro != null ? '${pro.hourlyRate.toStringAsFixed(0)} DT' : '—',
            'par heure',
            Icons.payments_rounded,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _statCol(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  // ── PRO DETAILS ────────────────────────────────────────────────────────────

  Widget _buildProDetails(BuildContext context, ProfessionalModel pro) {
    return Column(
      children: [
        // Specialty & bio
        _sectionCard(
          title: 'Votre Profil Professionnel',
          icon: Icons.badge_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF0F766E)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pro.specialty,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (pro.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 13, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Vérifié',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (pro.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  pro.bio,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.55),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Skills
        if (pro.skills.isNotEmpty)
          _sectionCard(
            title: 'Compétences',
            icon: Icons.construction_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pro.skills.map((s) => _skillChip(s)).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // Services
        if (pro.services.isNotEmpty)
          _sectionCard(
            title: 'Prestations & Tarifs',
            icon: Icons.receipt_long_rounded,
            child: Column(
              children: pro.services.map((s) => _serviceRow(s)).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // Availability
        _sectionCard(
          title: 'Disponibilités',
          icon: Icons.calendar_today_rounded,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) {
              final isAvailable = pro.availableDays.contains(day);
              return Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isAvailable ? AppColors.primary : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        day[0],
                        style: TextStyle(
                          color: isAvailable ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.substring(0, 1),
                    style: TextStyle(
                      fontSize: 9,
                      color: isAvailable ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _skillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _serviceRow(ProServiceItem service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_circle_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                ),
                Text(
                  service.duration,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${service.price.toStringAsFixed(0)} DT',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupProBanner(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF134E4A), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.white70, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complétez votre profil professionnel pour être visible sur la plateforme.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
            child: const Text('Compléter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── SETTINGS SECTION ──────────────────────────────────────────────────────

  Widget _buildSettingsSection(BuildContext context, UserModel user, AuthService auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
        children: [
          _settingsItem(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            title: 'Modifier mes informations',
            subtitle: 'Nom, téléphone, ville, adresse',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const Divider(height: 1, indent: 60, endIndent: 16, color: AppColors.cardBorder),
          _settingsItem(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Sécurité & mot de passe',
            subtitle: 'Modifier votre mot de passe',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
          ),
          const Divider(height: 1, indent: 60, endIndent: 16, color: AppColors.cardBorder),
          _settingsItem(
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Notifications',
            subtitle: 'Gérer vos alertes et rappels',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60, endIndent: 16, color: AppColors.cardBorder),
          _settingsItem(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF0284C7),
            title: 'Aide & Support',
            subtitle: 'FAQ, contact HomeFix',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support : contact@homefix.tn'), behavior: SnackBarBehavior.floating),
            ),
          ),
          const Divider(height: 1, indent: 60, endIndent: 16, color: AppColors.cardBorder),
          _settingsItem(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Se déconnecter',
            isDestructive: true,
            onTap: () => _confirmLogout(context, auth),
          ),
        ],
        ),
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter de HomeFix ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
