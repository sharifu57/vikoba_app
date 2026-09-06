import 'package:dio/dio.dart';

import 'package:vikoba_app/config/app_config.dart';

class AuthApiClient {
  AuthApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final response = await _dio.post(AppConfig.lookUp, data: {'phone': phone});
    return _map(response.data);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _dio.post(
      AppConfig.verifyOtp,
      data: {'phone': phone, 'code': code, 'purpose': 'login'},
    );
    return _map(response.data);
  }

  Future<Map<String, dynamic>> resendOtp(String phone) async {
    final response = await _dio.post(
      AppConfig.resendOtp,
      data: {'phone': phone, 'purpose': 'login'},
    );
    return _map(response.data);
  }

  Map<String, dynamic> _map(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected authentication response.');
  }
}
