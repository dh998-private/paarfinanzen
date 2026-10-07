import 'package:flutter/material.dart';

import '../finance_store.dart';
import '../formatters.dart';
import '../models.dart';
import 'app_theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ],
        ),
      );
}

class MonthAndViewControls extends StatelessWidget {
  const MonthAndViewControls({super.key, required this.store});
  final FinanceStore store;

  @override
  Widget build(BuildContext context) {
    final labels = <FinanceView, String>{
      FinanceView.common: 'Gemeinsam',
      FinanceView.person1: store.personName(1),
      FinanceView.person2: store.personName(2),
    };

    return Column(
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () => store.changeMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: Text(
                  MonthKey.label(store.selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => store.changeMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<FinanceView>(
            segments: labels.entries
                .map(
                  (e) => ButtonSegment(
                    value: e.key,
                    label: Text(e.value, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            selected: {store.view},
            onSelectionChanged: (values) => store.setView(values.first),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: AppColors.muted, size: 30),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
}
