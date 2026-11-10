import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/homefix_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../services/auth_service.dart';
import '../../../services/email_service.dart';

/// Three-step "forgot password" flow:
///   Step 1 – Enter email  →  Step 2 – Enter verification code  →  Step 3 – New password
///
/// When the user is already logged in, we show the classic "change password"
/// form instead (requires the current password).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ── Logged-in change-password ──────────────────────────────────────────────
  final _old = TextEditingController();
  final _next = TextEditingController();

  // ── Forgot-password steps ──────────────────────────────────────────────────
  int _step = 1; // 1 | 2 | 3
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _saving = false;
  String? _errorMsg;

  // Holds the generated code returned by the backend (simulated email).
  String? _simulatedCode;
  bool _isRealEmailSent = false;

  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────── Logged-in flow ───────────────────────────────

  Future<void> _changePassword() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorMsg = null;
    });
    final repo = context.read<HomeFixRepository>();
    final ok = await runAction(
        context,
        () => repo.changePassword(_old.text, _next.text),
        success: 'Mot de passe modifié.');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  // ─────────────────────────── Step 1 – email ───────────────────────────────

  Future<void> _requestCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Entrez une adresse e-mail valide.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMsg = null;
    });
    try {
      final code = await context
          .read<HomeFixRepository>()
          .requestPasswordReset(email);

      // Attempt to send a real email via Gmail SMTP
      bool realSent = false;
      try {
        realSent = await EmailService.instance.sendPasswordResetEmail(
          toEmail: email,
          code: code,
        );
      } catch (err) {
        debugPrint('[ForgotPasswordScreen] SMTP error: $err');
      }

      setState(() {
        _isRealEmailSent = realSent;
        _simulatedCode = realSent ? null : code;
        _step = 2;
      });

      if (mounted) {
        if (realSent) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('📧 Code envoyé par e-mail à $email.'),
            backgroundColor: AppColors.success,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '📧 Code généré pour $email\n(Mode démo – code : $code)'),
            duration: const Duration(seconds: 10),
            backgroundColor: AppColors.success,
          ));
        }
      }
    } catch (e) {
      setState(() =>
          _errorMsg = e is HomeFixException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────── Step 2 – code ────────────────────────────────

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _errorMsg = 'Le code fait 6 chiffres.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMsg = null;
    });
    try {
      await context
          .read<HomeFixRepository>()
          .verifyResetToken(_emailCtrl.text.trim(), code);
      setState(() => _step = 3);
    } catch (e) {
      setState(() =>
          _errorMsg = e is HomeFixException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────── Step 3 – new password ────────────────────────

  Future<void> _resetPassword() async {
    final pw = _newPwCtrl.text;
    final cpw = _confirmPwCtrl.text;
    if (pw.length < 8) {
      setState(
          () => _errorMsg = 'Le mot de passe doit contenir 8 caractères minimum.');
      return;
    }
    if (pw != cpw) {
      setState(
          () => _errorMsg = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMsg = null;
    });
    try {
      await context.read<HomeFixRepository>().resetPasswordWithToken(
            _emailCtrl.text.trim(),
            _codeCtrl.text.trim(),
            pw,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès !'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() =>
          _errorMsg = e is HomeFixException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    // If the user is logged in → classic change-password UI
    if (user != null) {
      return _buildChangePasswordForm();
    }

    // Otherwise → 3-step forgot-password flow
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        leading: _step > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _step -= 1;
                  _errorMsg = null;
                }),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Progress indicator ──────────────────────────────────────────
            _StepIndicator(current: _step),
            const SizedBox(height: 28),

            // ── Step 1 ──────────────────────────────────────────────────────
            if (_step == 1) ...[
              const PageIntro(
                title: 'Réinitialiser\nle mot de passe',
                description:
                    'Entrez votre adresse e-mail. Vous recevrez un code à 6 chiffres.',
              ),
              CustomTextField(
                label: 'Adresse e-mail',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: 24),
              if (_errorMsg != null) _ErrorText(_errorMsg!),
              CustomButton(
                text: 'Envoyer le code',
                isLoading: _saving,
                onPressed: _requestCode,
              ),
            ],

            // ── Step 2 ──────────────────────────────────────────────────────
            if (_step == 2) ...[
              const PageIntro(
                title: 'Entrer\nle code',
                description:
                    'Un code à 6 chiffres a été envoyé à votre adresse e-mail. Saisissez-le ci-dessous.',
              ),
              if (_isRealEmailSent)
                _InfoBanner(
                    '📬 E-mail envoyé à ${_emailCtrl.text.trim()} ! Consultez votre boîte de réception (et vos spams si besoin).')
              else if (_simulatedCode != null)
                _InfoBanner(
                    '📧 (Mode démo) Code : $_simulatedCode – valable 15 min.'),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Code de vérification',
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.lock_open_outlined,
              ),
              const SizedBox(height: 24),
              if (_errorMsg != null) _ErrorText(_errorMsg!),
              CustomButton(
                text: 'Vérifier le code',
                isLoading: _saving,
                onPressed: _verifyCode,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving ? null : _requestCode,
                child: const Text('Renvoyer le code'),
              ),
            ],

            // ── Step 3 ──────────────────────────────────────────────────────
            if (_step == 3) ...[
              const PageIntro(
                title: 'Nouveau\nmot de passe',
                description:
                    'Choisissez un mot de passe fort (8 caractères minimum).',
              ),
              CustomTextField(
                label: 'Nouveau mot de passe',
                controller: _newPwCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: 'Confirmer le mot de passe',
                controller: _confirmPwCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 24),
              if (_errorMsg != null) _ErrorText(_errorMsg!),
              CustomButton(
                text: 'Réinitialiser',
                isLoading: _saving,
                onPressed: _resetPassword,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Logged-in variant ───────────────────────────────────────────────────────
  Widget _buildChangePasswordForm() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe')),
      body: SingleChildScrollView(
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
              onPressed: _changePassword),
        ]),
      ),
    );
  }
}

// ── Small helpers ────────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(message,
            style: const TextStyle(color: AppColors.error, fontSize: 13)),
      );
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final labels = ['E-mail', 'Code', 'Mot de passe'];
    return Row(
      children: List.generate(3, (i) {
        final stepNum = i + 1;
        final active = stepNum == current;
        final done = stepNum < current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: done || active
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                      child: done
                          ? const Icon(Icons.check, size: 15, color: Colors.white)
                          : Text(
                              '$stepNum',
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i],
                        style: TextStyle(
                            fontSize: 10,
                            color: active || done
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ],
                ),
              ),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done ? AppColors.primary : AppColors.surfaceMuted,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
