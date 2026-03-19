import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  late final String _baseUrl = dotenv.get('API_BASE_URL');
  late final String _googleClientId = dotenv.get('GOOGLE_CLIENT_ID', fallback: '');

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // On iOS without Firebase, clientId is mandatory
    clientId: Platform.isIOS && _googleClientId.isNotEmpty ? _googleClientId : null,
    // Provide serverClientId so backend can verify id token
    serverClientId: _googleClientId.isNotEmpty ? _googleClientId : null,
    scopes: ['email', 'profile', 'openid'],
  );



  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_device';
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final deviceId = await getDeviceId();

      // Exchange Google ID Token for backend JWT
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': googleAuth.idToken,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data);
        return data;
      } else {
        throw Exception('Failed to authenticate with backend: ${response.body}');
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token']);
    await prefs.setString('user_data', jsonEncode(data['user']));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<bool> isPro() async {
    final user = await getUser();
    return user != null && user['plan'] == 'Pro';
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}

