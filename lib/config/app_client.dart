import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:vikoba_app/config/app_config.dart';
import 'package:vikoba_app/core/interceptors/auth_interceptor.dart';

class AppClient {
  static late Dio dio;

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,

        connectTimeout: AppConfig.connectTimeout,

        receiveTimeout: AppConfig.receiveTimeout,

        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor());

    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    final cacheOptions = CacheOptions(
      store: MemCacheStore(),

      policy: CachePolicy.request,

      maxStale: const Duration(days: 7),
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  }
}
