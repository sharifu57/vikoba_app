import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:vikoba_app/config/app_config.dart';
import 'package:vikoba_app/core/interceptors/auth_interceptor.dart';

class AppClient {
  static late Dio dio;

  static String cacheKey({
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  }) {
    final authorization = headers?.entries
        .where((entry) => entry.key.toLowerCase() == 'authorization')
        .map((entry) => entry.value)
        .firstOrNull;
    // The default builder hashes this URI; the token is never stored in the key.
    return CacheOptions.defaultCacheKeyBuilder(
      url: url.replace(fragment: authorization ?? ''),
    );
  }

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

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }

    final cacheOptions = CacheOptions(
      store: MemCacheStore(),
      keyBuilder: cacheKey,

      policy: CachePolicy.request,

      maxStale: const Duration(days: 7),
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  }
}
