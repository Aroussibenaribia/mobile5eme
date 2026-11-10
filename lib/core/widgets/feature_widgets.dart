import 'package:flutter/material.dart';
import '../data/homefix_repository.dart';
import '../theme/app_colors.dart';

class FeatureCard extends StatelessWidget {
  final Widget child;
  const FeatureCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ));
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge(this.label, {super.key, this.color = AppColors.primary});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700)));
}

class FeatureEmpty extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Widget? action;
  const FeatureEmpty(
      {super.key,
      required this.title,
      this.description = '',
      this.icon = Icons.inbox_outlined,
      this.action});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center)
            ],
            if (action != null) ...[const SizedBox(height: 20), action!]
          ])));
}

class DetailLine extends StatelessWidget {
  final String label, value;
  const DetailLine(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 2),
        SelectableText(value.isEmpty ? '—' : value,
            style: const TextStyle(color: AppColors.textPrimary))
      ]));
}

Future<bool> confirmAction(
        BuildContext context, String title, String body) async =>
    await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: Text(title), content: Text(body), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmer'))
            ])) ??
    false;

Future<bool> runAction(BuildContext context, Future<void> Function() operation,
    {String? success}) async {
  try {
    await operation();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success), backgroundColor: AppColors.success));
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is HomeFixException
              ? e.message
              : 'Une erreur est survenue. Réessayez.'),
          backgroundColor: AppColors.error));
    }
    return false;
  }
}
