import 'package:dio/dio.dart';
import 'package:vikoba_app/config/app_config.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

class AuthApi {
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      );

      final response = await dio.post(
        AppConfig.refreshToken,
        data: {"refreshToken": refreshToken},
      );

      if (response.data["status"] == true) {
        await TokenStorage.updateTokens(
          token: response.data["token"],
          refreshToken: response.data["refreshToken"],
          expires: response.data["expired"],
        );

        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
