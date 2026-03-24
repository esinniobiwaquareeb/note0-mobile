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
  late final String _googleIosClientId = dotenv.get('GOOGLE_IOS_CLIENT_ID', fallback: '');
  late final String _googleWebClientId = dotenv.get('GOOGLE_WEB_CLIENT_ID', fallback: '');
  late final String _googleAndroidClientId = dotenv.get('GOOGLE_ANDROID_CLIENT_ID', fallback: '');

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS ? _googleIosClientId : (Platform.isAndroid ? _googleAndroidClientId : null),
    serverClientId: _googleWebClientId,
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
      print('AuthService: Starting Google Sign-In...');
      print('AuthService: Client ID (iOS): $_googleIosClientId');
      print('AuthService: Server Client ID: $_googleWebClientId');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('AuthService: Google Sign-In cancelled by user or failed.');
        return null;
      }

      print('AuthService: Google Sign-In successful: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('AuthService: Obtained authentication tokens.');
      
      final deviceId = await getDeviceId();
      print('AuthService: Device ID: $deviceId');

      print('AuthService: Exchanging token with backend at: $_baseUrl/auth/google/verify');
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
      ).timeout(const Duration(seconds: 30));

      print('AuthService: Backend response: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data);
        print('AuthService: Authentication complete (User: ${data['user']['name']}, Avatar: ${data['user']['avatarUrl']})');
        return data;
      } else {

        print('AuthService: Backend authentication failed: ${response.body}');
        throw Exception('Failed to authenticate with backend: ${response.body}');
      }
    } catch (e) {
      print('AuthService: Google Sign-In Error: $e');
      rethrow; // Rethrow to let the UI catch and show the error
    }
  }


  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['access_token']);
    await prefs.setString('user_data', jsonEncode(data['user']));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('AuthService: getToken() returning ${token != null ? "a token" : "null"}');
    return token;
  }


  Future<void> logout() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
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

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
        return userData;
      }
      return null;
    } catch (e) {
      print('AuthService: fetchProfile failed: $e');
      return null;
    }
  }

  Future<bool> isPro() async {
    final user = await getUser();
    return user != null && user['plan'] == 'Pro';
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<String> getDeviceIdPublic() => getDeviceId();
}


