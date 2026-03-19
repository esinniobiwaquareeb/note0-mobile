import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:uuid/uuid.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


final usageServiceProvider = Provider((ref) => UsageService());

class UsageService {
  String get _baseUrl => dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/v1');

  static const String _recordingCountKey = 'free_recording_count';
  static const String _guestIdKey = 'guest_unique_id';

  Future<String> getGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString(_guestIdKey);
    if (guestId == null) {
      guestId = const Uuid().v4();
      await prefs.setString(_guestIdKey, guestId);
    }
    return guestId;
  }


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
    // We'll also try to fetch the actual count from backend if we have a network
    // but for now, rely on local count + backend limit
    final limit = await getFreeLimit();

    return count < limit;
  }

}
