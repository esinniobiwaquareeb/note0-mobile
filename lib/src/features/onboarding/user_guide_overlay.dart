import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class UserGuideOverlay extends StatelessWidget {
  const UserGuideOverlay({super.key, required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: InkWell(
        onTap: onDismiss,
        child: Stack(
          children: [
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  _GuideStep(
                    icon: Icons.mic,
                    title: 'Tap to Record',
                    description: 'Start capturing your thoughts instantly.',
                    isDark: isDark,
                  ),
                  const Gap(24),
                  _GuideStep(
                    icon: Icons.swipe,
                    title: 'Swipe for Actions',
                    description: 'Swipe left to delete, right to move to folder.',
                    isDark: isDark,
                  ),
                  const Gap(24),
                  _GuideStep(
                    icon: Icons.auto_awesome,
                    title: 'AI Magic',
                    description: 'Use AI tools to summarize and analyze note.',
                    isDark: isDark,
                  ),
                  const Gap(40),
                  const Text(
                    'Tap anywhere to start',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(4),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
