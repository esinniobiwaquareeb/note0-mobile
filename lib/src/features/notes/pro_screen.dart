import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'notes_list_screen.dart';
import '../../core/theme/app_theme.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Gap(60),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Header Background Visualization
                      _HeaderVisualization(),
                      PositionNotifier(),
                    ],
                  ),
                  const Gap(40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Note0',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF404040),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                            Gap(4),
                            Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    'Unlock All Features with Note0',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const Gap(32),
                  _FeatureList(),
                  const Gap(32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _SubscriptionOptions(),
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(),
        ],
      ),
    );
  }
}

class PositionNotifier extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black : Colors.black12, blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, color: Colors.grey[400], size: 20),
          const Gap(8),
          Text('..........', style: TextStyle(letterSpacing: 2, fontSize: 18, color: isDark ? Colors.white54 : Colors.black)),
          Text('||||', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
          Text('..........', style: TextStyle(letterSpacing: 2, fontSize: 18, color: isDark ? Colors.white54 : Colors.black)),
          const Gap(8),
          Icon(Icons.mic_none, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
}

class _HeaderVisualization extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Opacity(
        opacity: 0.1,
        child: Stack(
          alignment: Alignment.center,
          children: const [
            _LabelCloudItem(text: 'Learn', top: 20, left: 100),
            _LabelCloudItem(text: 'Audio', top: 30, right: 80),
            _LabelCloudItem(text: 'Quick', bottom: 40, right: 120),
            _LabelCloudItem(text: 'Write', bottom: 50, left: 60),
            _LabelCloudItem(text: 'Focus', bottom: 20, right: 40),
            _LabelCloudItem(text: 'Quote', bottom: 60, left: 120),
          ],
        ),
      ),
    );
  }
}

class _LabelCloudItem extends StatelessWidget {
  const _LabelCloudItem({required this.text, this.top, this.bottom, this.left, this.right});
  final String text;
  final double? top, bottom, left, right;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white54 : Colors.black),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _FeatureItem(label: 'Unlimited transcriptions'),
          Gap(16),
          _FeatureItem(label: 'Generate summaries instantly'),
          Gap(16),
          _FeatureItem(label: 'AI Powered flashcards & quizzes'),
          Gap(16),
          _FeatureItem(label: 'Multi-language support'),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isDark ? Colors.white12 : const Color(0xFF262626),
          child: Icon(Icons.check, color: isDark ? Colors.white70 : Colors.white, size: 14),
        ),
        const Gap(16),
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black),
        ),
      ],
    );
  }
}

class _SubscriptionOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OptionTile(
          title: 'Yearly Access',
          price: '₦45,000 per year',
          description: 'Just ₦865 per week',
          isAnnual: true,
          isSelected: true,
        ),
        const Gap(16),
        const _OptionTile(
          title: 'Weekly Access',
          price: '₦2,500 per week',
          description: '',
          isSelected: false,
        ),
        const Gap(24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            Gap(8),
            Text(
              'Auto Renewable, Cancel Anytime',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.price,
    required this.description,
    this.isAnnual = false,
    required this.isSelected,
  });

  final String title;
  final String price;
  final String description;
  final bool isAnnual;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : Colors.black),
                  ),
                  const Gap(4),
                  Text(
                    price,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              if (description.isNotEmpty)
                Text(
                  description,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
            ],
          ),
          if (isAnnual)
            Positioned(
              top: -30,
              right: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Save 86%',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const NotesListScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Terms', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('•', style: TextStyle(color: Colors.grey))),
              const Text('Privacy Policy', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('•', style: TextStyle(color: Colors.grey))),
              const Text('Restore', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
