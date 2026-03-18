import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


final usageServiceProvider = Provider((ref) => UsageService());

class UsageService {
  String get _baseUrl => dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/v1');

  static const String _recordingCountKey = 'free_recording_count';

  Future<int> getFreeRecordingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_recordingCountKey) ?? 0;
  }

  Future<void> incrementRecordingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getFreeRecordingCount();
    await prefs.setInt(_recordingCountKey, current + 1);
  }

  Future<int> getFreeLimit() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/config/public'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> config = jsonDecode(response.body);
        return config['free_audio_limit'] ?? 1;
      }
    } catch (e) {
      debugPrint('Error fetching free limit: $e');
    }
    return 1; // Fallback
  }


  Future<bool> canRecord(bool isPro) async {
    if (isPro) return true;

    final count = await getFreeRecordingCount();
    final limit = await getFreeLimit();

    return count < limit;
  }
}
