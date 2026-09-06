import 'package:dio/dio.dart';

import 'package:vikoba_app/config/app_config.dart';

class MemberDashboardApi {
  MemberDashboardApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getOverview(int groupId) async {
    final response = await _dio.get(
      AppConfig.dashboardGroup(groupId),
      options: Options(extra: {'requiresAuth': true}),
    );
    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid dashboard response.');
    }
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }
}
