import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../models/work_schedule.dart';

class PageIntro extends StatelessWidget {
  final String eyebrow, title, description;
  final Widget? trailing;
  const PageIntro(
      {super.key,
      required this.title,
      this.eyebrow = '',
      this.description = '',
      this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (eyebrow.isNotEmpty) ...[
          Text(eyebrow,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const SizedBox(height: 10),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.headlineLarge)),
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ]),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ]));
}

class SectionHeading extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeading(this.title, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null) action!,
      ]));
}

class WeekDays extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String>? onToggle;
  const WeekDays({super.key, required this.selected, this.onToggle});
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 7, runSpacing: 8, children: [
        for (var i = 0; i < WorkSchedule.days.length; i++)
          if (onToggle != null)
            FilterChip(
                label: Text(WorkSchedule.days[i]),
                selected: selected.contains(WorkSchedule.days[i]),
                tooltip: WorkSchedule.labels[i],
                showCheckmark: true,
                onSelected: (_) => onToggle!(WorkSchedule.days[i]))
          else
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                    color: selected.contains(WorkSchedule.days[i])
                        ? AppColors.primaryLight
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(9)),
                child: Text(WorkSchedule.days[i],
                    style: TextStyle(
                        color: selected.contains(WorkSchedule.days[i])
                            ? AppColors.primaryDark
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: selected.contains(WorkSchedule.days[i])
                            ? FontWeight.w700
                            : FontWeight.w400))),
      ]);
}

class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentWidth({super.key, required this.child, this.maxWidth = 720});
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

class CraftMark extends StatelessWidget {
  final double size;
  const CraftMark({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(size * .28)),
      child:
          Icon(Icons.handyman_outlined, size: size * .5, color: Colors.white));
}
