import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/subscription_service.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class SubscriptionHistoryScreen extends ConsumerStatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  ConsumerState<SubscriptionHistoryScreen> createState() => _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends ConsumerState<SubscriptionHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ref.read(subscriptionServiceProvider).fetchHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Subscription History'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const Gap(16),
                  Text(
                    'No subscription history yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final sub = _history[index];
                final date = DateTime.parse(sub['createdAt']);
                final amount = sub['amount'];
                final plan = sub['plan'];
                final status = (sub['status'] ?? 'Unknown').toString();
                final isDark = Theme.of(context).brightness == Brightness.dark;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: status == 'Active'
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status == 'Active' ? Icons.check_circle : Icons.schedule,
                              color: status == 'Active' ? Colors.blue : Colors.orange,
                              size: 20,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Gap(4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(date),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plan.contains('USD') ? '\$$amount' : '₦$amount',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const Gap(8),
                          const Icon(Icons.expand_more, size: 20),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
                              const Gap(8),
                              const Text(
                                'Features Included:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                              ),
                              const Gap(12),
                              ..._getPlanFeatures(plan).map((feature) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check, size: 16, color: Colors.blue),
                                        const Gap(12),
                                        Expanded(
                                          child: Text(
                                            feature,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Gap(8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status:',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                  ),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'Active' ? Colors.blue : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  List<String> _getPlanFeatures(String planName) {
    final name = planName.toLowerCase();
    if (name.contains('premium')) {
      if (name.contains('weekly')) {
        return [
          "25 hours of AI recordings/week",
          "Advanced note summaries & insights",
          "AI chat, flashcards & quizzes",
          "Priority support"
        ];
      } else {
        return [
          "100 hours of AI recordings/month",
          "Advanced note summaries & insights",
          "AI chat, flashcards & quizzes",
          "Priority support"
        ];
      }
    } else if (name.contains('pro')) {
      if (name.contains('weekly')) {
        return [
          "8 hours of AI recordings/week",
          "Advanced note summaries & insights",
          "AI chat, flashcards & quizzes",
          "Priority student support"
        ];
      } else {
        return [
          "30 hours of AI recordings/month",
          "Advanced note summaries & insights",
          "AI chat, flashcards & quizzes",
          "Priority student support"
        ];
      }
    }
    return [
      "3 audio recordings limit",
      "Basic note summaries"
    ];
  }
}
