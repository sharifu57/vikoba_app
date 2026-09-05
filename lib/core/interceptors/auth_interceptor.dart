import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vikoba_app/config/app_config.dart';
import 'package:vikoba_app/config/app_client.dart';
import 'package:vikoba_app/config/auth_api.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra["requiresAuth"] == true;

    if (requiresAuth) {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers["authorization"] = "Bearer $token";
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (err.requestOptions.path == AppConfig.refreshToken) {
        await TokenStorage.clear();
        Get.offAllNamed("/login");
        return handler.next(err);
      }

      final refreshed = await AuthApi.refreshToken();

      if (refreshed) {
        final newToken = await TokenStorage.getToken();

        final request = err.requestOptions;

        request.headers["Authorization"] = "Bearer $newToken";

        final dio = AppClient.dio;

        final response = await dio.fetch(request);

        return handler.resolve(response);
      }

      await TokenStorage.clear();

      Get.offAllNamed("/login");
    }

    handler.next(err);
  }
}
