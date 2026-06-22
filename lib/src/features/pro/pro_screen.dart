import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import './payment_webview.dart';



import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/utils/toast_utils.dart';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  List<dynamic> _plans = [];
  bool _isLoading = true;
  bool _isProcessing = false;


  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final baseUrl = dotenv.get('API_BASE_URL');
      final response = await http.get(Uri.parse('$baseUrl/subscriptions/plans'));
      if (response.statusCode == 200) {
        final List<dynamic> allPlans = jsonDecode(response.body);
        final filteredPlans = allPlans.where((plan) => plan['name'].toString().toLowerCase() != 'free').toList();
        setState(() {
          _plans = filteredPlans;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching plans: $e');
    }
  }

  Future<void> _cancelSubscription() async {
    if (_isProcessing) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel Subscription?',
      message: 'Are you sure you want to cancel your active Pro subscription? You will lose access to all Pro features and your account will revert to the Free plan.',
      confirmLabel: 'Cancel Subscription',
      cancelLabel: 'Keep Plan',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isProcessing = true);
    try {
      final success = await ref.read(subscriptionServiceProvider).cancelSubscription();
      if (success) {
        if (mounted) {
          ToastUtils.showSuccess(context, 'Subscription cancelled successfully.');
          await ref.read(userProvider.notifier).refreshUser();
        }
      } else {
        if (mounted) {
          ToastUtils.showError(context, 'Failed to cancel subscription.');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePlanSelection(dynamic plan, String currentPlanName) async {
    final planId = _planIdentifier(plan);
    final planName = plan['name'].toString();

    if (currentPlanName != 'Free') {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Change Subscription Plan?',
        message: 'Are you sure you want to change your current plan to the $planName plan?',
        confirmLabel: 'Confirm Change',
        cancelLabel: 'Cancel',
      );
      if (!confirmed) return;
    }

    _initializeSubscription(planId);
  }

  Future<void> _initializeSubscription(String planName) async {
    if (_isProcessing) return;
    
    final authService = ref.read(authServiceProvider);
    var token = await authService.getToken();

    // If token is null, wait a brief moment and retry once (to handle SharedPreferences write latency)
    if (token == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      token = await authService.getToken();
    }

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to subscribe')),
        );
      }
      return;
    }


    setState(() => _isProcessing = true);
    try {
      final baseUrl = dotenv.get('API_BASE_URL');
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'planName': planName}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['paymentUrl'];
        final reference = data['reference']?.toString();
        
        if (url == null) {
          // Free or immediate activation
          if (mounted) {
            await ref.read(userProvider.notifier).refreshUser();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Success!'),
                content: const Text('Your subscription has been activated successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Pop dialog
                      Navigator.of(context).pop(true); // Pop screen
                    },
                    child: const Text('Awesome'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            final success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentWebView(url: url, reference: reference),
              ),
            );
            if (success == true && mounted) {
              Navigator.pop(context, true);
            }
          }
        }
      } else {
        throw Exception('Failed to initialize subscription');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _planIdentifier(dynamic plan) {
    final id = plan['id']?.toString();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return plan['name'].toString();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(userProvider);
    final user = userAsync.value;
    final currentPlanName = user != null ? (user['plan'] ?? 'Free').toString() : 'Free';
    final cancelAtPeriodEnd = user != null ? (user['cancelAtPeriodEnd'] == true) : false;
    final renewalDateStr = user != null ? user['renewalDate']?.toString() : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Note0 Pro',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Unlock the full potential of your notes with AI-powered insights and unlimited storage.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const Gap(32),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final isPremium = plan['name'].toString().toLowerCase().contains('premium');
                      final planName = plan['name'].toString();
                      final isCurrent = planName == currentPlanName;

                      return _PlanCard(
                        plan: plan,
                        isPremium: isPremium,
                        isProcessing: _isProcessing,
                        isCurrentPlan: isCurrent,
                        cancelAtPeriodEnd: isCurrent ? cancelAtPeriodEnd : false,
                        renewalDateStr: isCurrent ? renewalDateStr : null,
                        onCancelPlan: isCurrent && currentPlanName != 'Free' && !cancelAtPeriodEnd ? _cancelSubscription : null,
                        onTap: () => _handlePlanSelection(plan, currentPlanName),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Secure payments via KudiPot. Cancel anytime.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}

String _formatInterval(String interval) {
  switch (interval.toLowerCase()) {
    case 'weekly':
      return 'week';
    case 'monthly':
      return 'month';
    case 'yearly':
      return 'year';
    case 'daily':
      return 'day';
    default:
      return interval;
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isPremium,
    required this.onTap,
    required this.isProcessing,
    required this.isCurrentPlan,
    this.onCancelPlan,
    this.cancelAtPeriodEnd = false,
    this.renewalDateStr,
  });
  final dynamic plan;
  final bool isPremium;
  final bool isProcessing;
  final VoidCallback onTap;
  final bool isCurrentPlan;
  final VoidCallback? onCancelPlan;
  final bool cancelAtPeriodEnd;
  final String? renewalDateStr;


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrentPlan
              ? Colors.green.withOpacity(0.8)
              : (isPremium
                  ? Colors.blue.withOpacity(0.5)
                  : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
          width: isCurrentPlan || isPremium ? 2 : 1,
        ),
        boxShadow: isCurrentPlan
          ? [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
          : (isPremium
              ? [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
              : []),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrentPlan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: const Text(
                'YOUR CURRENT PLAN',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            )
          else if (isPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        plan['name'] ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      '${plan['currency'] == 'USD' ? '\$' : '₦'}${plan['amount']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  'per ${_formatInterval((plan['interval'] ?? 'monthly').toString())}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const Gap(24),
                if (plan['features'] != null && plan['features'] is List && (plan['features'] as List).isNotEmpty)
                  ...(plan['features'] as List).map((feature) => _BenefitItem(text: feature.toString()))
                else ...[
                  _BenefitItem(text: plan['description'] ?? 'Unlimited AI Transcriptions'),
                  const _BenefitItem(text: 'High-Fidelity Audio Storage'),
                  const _BenefitItem(text: 'Advanced Folder Organization'),
                  const _BenefitItem(text: 'Priority Customer Support'),
                ],
                const Gap(32),
                if (isCurrentPlan) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cancelAtPeriodEnd ? Colors.orange.withOpacity(0.5) : Colors.green.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        cancelAtPeriodEnd 
                          ? 'Cancels on ${renewalDateStr != null ? DateTime.tryParse(renewalDateStr!)?.toLocal().toString().split(' ')[0] ?? '' : ''}'
                          : 'Active Plan',
                        style: TextStyle(color: cancelAtPeriodEnd ? Colors.orange : Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  if (onCancelPlan != null) ...[
                    const Gap(12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: isProcessing ? null : onCancelPlan,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Cancel Subscription',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPremium ? Colors.blue : (isDark ? Colors.white10 : Colors.black),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isProcessing 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Start 3-Day Free Trial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
