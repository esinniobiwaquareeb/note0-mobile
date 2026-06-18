import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static final String apiBaseUrl = dotenv.get('API_BASE_URL');
  static final String paymentSuccessUrl = dotenv.get('PAYMENT_SUCCESS_URL', fallback: 'https://note0.app/payment-success');
  static final String marketingUrl = dotenv.get('MARKETING_URL', fallback: 'https://note0.app');
  static final String supportEmail = dotenv.get('SUPPORT_EMAIL', fallback: 'support@note0.app');
  static final String termsUrl = dotenv.get('TERMS_URL', fallback: 'https://note0.app/terms');
  static final String privacyUrl = dotenv.get('PRIVACY_URL', fallback: 'https://note0.app/privacy');
}
