import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import './payment_webview.dart';



import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/services/auth_service.dart';

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
        setState(() {
          _plans = jsonDecode(response.body);
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

  Future<void> _initializeSubscription(String planName) async {
    if (_isProcessing) return;
    
    final authService = ref.read(authServiceProvider);
    final token = await authService.getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to subscribe')),
      );
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
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentWebView(url: url),
            ),
          );
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


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      
                      return _PlanCard(
                        plan: plan,
                        isPremium: isPremium,
                        isProcessing: _isProcessing,
                        onTap: () => _initializeSubscription(plan['name']),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isPremium,
    required this.onTap,
    required this.isProcessing,
  });
  final dynamic plan;
  final bool isPremium;
  final bool isProcessing;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? Colors.blue.withOpacity(0.5) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          width: isPremium ? 2 : 1,
        ),
        boxShadow: isPremium 
          ? [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
          : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPremium)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['name'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '₦${plan['amount']}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  'per ${plan['interval']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const Gap(24),
                _BenefitItem(text: plan['description'] ?? 'Unlimited AI Transcriptions'),
                const _BenefitItem(text: 'High-Fidelity Audio Storage'),
                const _BenefitItem(text: 'Advanced Folder Organization'),
                const _BenefitItem(text: 'Priority Customer Support'),
                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onTap,
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
                        : const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),


                  ),
                ),
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
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const Gap(12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

