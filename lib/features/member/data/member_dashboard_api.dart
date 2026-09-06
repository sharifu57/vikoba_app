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

  Future<List<Map<String, dynamic>>> getMembersByGroup(int groupId) async {
    final response = await _dio.get(
      AppConfig.groupMembers(groupId),
      options: Options(extra: {'requiresAuth': true}),
    );
    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid members response.');
    }

    final data = body['data'];
    if (data is! List) return <Map<String, dynamic>>[];

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getShareSummary(int groupId) async {
    final response = await _dio.get(
      AppConfig.shareSummary(groupId),
      options: Options(extra: {'requiresAuth': true}),
    );
    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid share summary response.');
    }
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getShareLedger(int groupId) async {
    final response = await _dio.get(
      AppConfig.shareLedger(groupId),
      options: Options(extra: {'requiresAuth': true}),
    );
    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid share ledger response.');
    }

    final data = body['data'];
    if (data is! List) return <Map<String, dynamic>>[];

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> purchaseShares(
    int groupId, {
    required int groupMemberId,
    required int quantity,
    required double amount,
    required String paymentMethod,
    String? reference,
  }) async {
    final response = await _dio.post(
      AppConfig.purchaseShares(groupId),
      data: {
        'groupMemberId': groupMemberId,
        'quantity': quantity,
        'amount': amount,
        'paymentMethod': paymentMethod,
        if (reference != null && reference.trim().isNotEmpty)
          'reference': reference.trim(),
      },
      options: Options(extra: {'requiresAuth': true}),
    );

    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid share purchase response.');
    }

    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }
}
