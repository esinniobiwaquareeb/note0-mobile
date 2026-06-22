import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/subscription_service.dart';

class PaymentWebView extends ConsumerStatefulWidget {
  final String url;
  final String successUrl;
  final bool isPayment;
  final String? reference;

  const PaymentWebView({
    super.key,
    required this.url,
    this.successUrl = 'https://note0.app/payment-success',
    this.isPayment = true,
    this.reference,
  });


  @override
  ConsumerState<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends ConsumerState<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _successHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            // Check if the URL is the success URL
            if (widget.isPayment && (url.contains('success') || url.contains(widget.successUrl))) {
              _handleSuccess();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (widget.isPayment && (request.url.contains('success') || request.url.contains(widget.successUrl))) {
              _handleSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },

        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _handleSuccess() async {
    if (_successHandled) return;
    setState(() {
      _successHandled = true;
    });

    if (widget.reference != null && widget.reference!.isNotEmpty) {
      await ref.read(subscriptionServiceProvider).verifyPayment(widget.reference!);
    } else {
      // Fallback if we somehow lost the provider reference
      await Future.delayed(const Duration(seconds: 2));
    }
    
    // Refresh user state to reflect Pro status
    if (mounted) {
      await ref.read(userProvider.notifier).refreshUser();
    }
    
    // Show success dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: const Text('Your Pro subscription has been activated.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Pop dialog
                Navigator.of(context).pop(true); // Pop webview with success flag
              },
              child: const Text('Awesome'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isPayment 
        ? AppBar(
            title: const Text('Complete Payment'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _controller.reload(),
              ),
            ],
          )
        : null,

      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
