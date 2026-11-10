import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pro_avatar.dart';
import '../../../models/professional_model.dart';
import '../screens/pro_detail_screen.dart';

class ProCard extends StatelessWidget {
  final ProfessionalModel professional;
  final bool compact;
  const ProCard({super.key, required this.professional, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final pro = professional;
    final prices = pro.services.map((s) => s.price).toList()..sort();
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProDetailScreen(professional: pro))),
                child: Padding(
                    padding: EdgeInsets.all(compact ? 16 : 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProAvatar(
                                    name: pro.name,
                                    imageUrl: pro.avatarUrl,
                                    radius: compact ? 24 : 28),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(pro.specialty,
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11)),
                                      const SizedBox(height: 5),
                                      Text(pro.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 5),
                                      Text(pro.city,
                                          style: const TextStyle(fontSize: 12)),
                                    ])),
                                const Icon(Icons.arrow_outward,
                                    size: 19, color: AppColors.primary),
                              ]),
                          if (!compact && pro.bio.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(pro.bio,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontSize: 12, height: 1.5)),
                          ],
                          const Divider(height: 30),
                          Row(children: [
                            Icon(Icons.circle,
                                size: 6,
                                color: pro.isAvailable
                                    ? AppColors.primary
                                    : AppColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(
                                    pro.isAvailable
                                        ? 'Planning ouvert'
                                        : 'Planning en pause',
                                    style: const TextStyle(fontSize: 11))),
                            Text(
                                prices.isEmpty
                                    ? 'Aucune prestation'
                                    : 'Dès ${prices.first.toStringAsFixed(0)} DT',
                                style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14)),
                          ]),
                        ])))));
  }
}
