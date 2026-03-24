import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import './auth_service.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService(ref.read(authServiceProvider)));

class SubscriptionService {
  final AuthService _authService;
  SubscriptionService(this._authService);

  String get _baseUrl => dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/v1');

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('SubscriptionService: fetchHistory failed: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchCurrentStatus() async {
    final token = await _authService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('SubscriptionService: fetchCurrentStatus failed: $e');
    }
    return null;
  }
}
