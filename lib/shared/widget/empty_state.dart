import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

/// Empty screen with one clear next action (baseline-ui: an empty state
/// always offers exactly one thing to do).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Reveal(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, size: 28, color: c.textPrimary),
                ),
              ),
              const SizedBox(height: 20),
              Reveal(
                index: 1,
                child: Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 8),
              Reveal(
                index: 2,
                child: Text(body, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.5)),
              ),
              const SizedBox(height: 24),
              Reveal(index: 3, child: WButton(label: actionLabel, icon: Icons.add_rounded, onPressed: onAction)),
            ],
          ),
        ),
      ),
    );
  }
}
