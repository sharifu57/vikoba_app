import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  static const Duration connectTimeout = Duration(seconds: 20);

  static const Duration receiveTimeout = Duration(seconds: 20);

  static String get auth => "$baseUrl/api/auth";

  static String get lookUp => "$auth/lookup";
  static String get register => "$auth/register";
  static String get verifyOtp => "$auth/verify-otp";
  static String get resendOtp => "$auth/resend-otp";
  static String get refreshToken => "$auth/refresh";
  static String get logout => "$auth/logout";
  static String get roles => "$auth/roles";
  static String get staffInvite => "$auth/staff-invite";

  static String get staff => "$auth/organization-staff";
}
