import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Service responsible for sending real transactional emails via Gmail SMTP.
///
/// To enable real email delivery:
/// 1. Use any standard Google account (e.g. your_email@gmail.com).
/// 2. Enable 2-Step Verification on your Google account:
///    https://myaccount.google.com/security
/// 3. Create an "App Password" (Mot de passe d'application):
///    https://myaccount.google.com/apppasswords
///    Select app: "Autre (nom personnalisé)" -> "HomeFix"
/// 4. Paste your Gmail address and 16-character App Password below.
class EmailService {
  EmailService._();
  static final EmailService instance = EmailService._();

  // ─── GMAIL SMTP CONFIGURATION ─────────────────────────────────────────────
  static String gmailAddress = 'benaribiaaroussi@gmail.com';
  static String gmailAppPassword = 'iveo liji emom mair';
  static String senderName = 'HomeFix';

  /// Returns true if the service has been configured with real credentials.
  bool get isConfigured {
    final cleanEmail = gmailAddress.trim();
    final cleanPass = gmailAppPassword.replaceAll(' ', '').trim();
    return cleanEmail.isNotEmpty &&
        cleanEmail.contains('@') &&
        !cleanEmail.contains('your_email@') &&
        cleanPass.isNotEmpty &&
        !cleanPass.contains('xxxx') &&
        cleanPass.length >= 16;
  }

  /// Sends a real 6-digit password reset code to [toEmail] via Gmail SMTP.
  ///
  /// Returns `true` if the email was successfully sent over SMTP,
  /// or `false` if credentials are not configured yet (simulation mode).
  Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String code,
  }) async {
    if (!isConfigured) {
      debugPrint(
        '⚠️ [EmailService] Gmail SMTP not configured yet. Set gmailAddress & gmailAppPassword in email_service.dart.',
      );
      return false;
    }

    final cleanPass = gmailAppPassword.replaceAll(' ', '').trim();
    final smtpServer = gmail(gmailAddress.trim(), cleanPass);

    final message = Message()
      ..from = Address(gmailAddress.trim(), senderName)
      ..recipients.add(toEmail.trim())
      ..subject = 'Code de réinitialisation HomeFix : $code'
      ..text = '''Bonjour,

Vous avez demandé la réinitialisation de votre mot de passe sur HomeFix.

Votre code de vérification est : $code

Ce code est valable pendant 15 minutes.
Si vous n'êtes pas à l'origine de cette demande, vous pouvez ignorer cet e-mail.

L'équipe HomeFix.
'''
      ..html = _buildHtmlEmail(code: code);

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('✅ [EmailService] Email sent successfully: ${sendReport.toString()}');
      return true;
    } on MailerException catch (e) {
      debugPrint('❌ [EmailService] MailerException: ${e.toString()}');
      for (final p in e.problems) {
        debugPrint('   Problem: ${p.code}: ${p.msg}');
      }
      throw Exception(
        'Impossible d\'envoyer l\'e-mail via Gmail SMTP (${e.message}). Vérifiez vos identifiants.',
      );
    } catch (e) {
      debugPrint('❌ [EmailService] Unexpected error: $e');
      throw Exception('Erreur réseau lors de l\'envoi de l\'e-mail.');
    }
  }

  /// Clean, responsive HTML email template branded with HomeFix theme.
  String _buildHtmlEmail({required String code}) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Réinitialisation de mot de passe HomeFix</title>
</head>
<body style="margin: 0; padding: 24px; background-color: #F4F5EF; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #203B33;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width: 520px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #DDE3D8; box-shadow: 0 4px 12px rgba(0,0,0,0.04);">
    <!-- Header -->
    <tr>
      <td style="padding: 28px 32px; background-color: #16695B; text-align: center;">
        <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 800; letter-spacing: -0.5px;">HomeFix</h1>
        <p style="margin: 4px 0 0; color: #E0EDE5; font-size: 13px;">Services À Domicile & Entraide</p>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding: 36px 32px;">
        <h2 style="margin: 0 0 12px; font-size: 20px; font-weight: 700; color: #203B33;">Réinitialisation de votre mot de passe</h2>
        <p style="margin: 0 0 24px; font-size: 14px; line-height: 1.5; color: #637268;">
          Vous avez demandé à réinitialiser votre mot de passe. Voici votre code de vérification à 6 chiffres :
        </p>

        <!-- Code Box -->
        <div style="background-color: #E0EDE5; border: 2px dashed #16695B; border-radius: 12px; padding: 20px; text-align: center; margin: 0 0 24px;">
          <span style="font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #104B41; font-family: monospace;">$code</span>
        </div>

        <p style="margin: 0 0 8px; font-size: 13px; color: #7C8A80;">
          ⏳ <strong>Ce code est valable pendant 15 minutes.</strong>
        </p>
        <p style="margin: 0; font-size: 13px; color: #7C8A80;">
          Si vous n'êtes pas à l'origine de cette demande, ignorez simplement cet e-mail. Votre mot de passe actuel reste inchangé.
        </p>
      </td>
    </tr>

    <!-- Footer -->
    <tr>
      <td style="padding: 20px 32px; background-color: #EBEEE6; text-align: center; border-top: 1px solid #DDE3D8;">
        <p style="margin: 0; font-size: 12px; color: #7C8A80;">
          © ${DateTime.now().year} HomeFix — Plateforme de Services & Artisans.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
