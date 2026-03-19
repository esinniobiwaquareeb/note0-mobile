import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:gap/gap.dart';


class SubscriptionHistoryScreen extends StatelessWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> history = []; // TODO: Fetch from backend once subscription system is fully integrated

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Subscription History'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: history.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.3)),
                const Gap(16),
                Text(
                  'No translation history yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ... existing list items if any
            ],
          ),
    );
  }
}

