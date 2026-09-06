import 'package:vikoba_app/config/app_config.dart';

class ApiEndpoints {
  static String get baseUrl => AppConfig.baseUrl;
  static String get lookup => "$baseUrl/lookup";
}
