import 'package:dio/dio.dart';

import 'package:vikoba_app/config/app_config.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

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

  Future<Map<String, dynamic>> submitSharePurchaseProof(
    int groupId, {
    required int groupMemberId,
    required double amount,
    required String paymentMethod,
    String? paymentReference,
    String? proofText,
    String? proofFilePath,
    double? jamiiAmount,
  }) async {
    final storedToken = await TokenStorage.getToken();
    final token = storedToken
        ?.replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '')
        .trim();
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: 'share-purchase-proof'),
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final form = FormData.fromMap({
      'groupMemberId': groupMemberId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (jamiiAmount != null && jamiiAmount > 0) 'jamiiAmount': jamiiAmount,
      if (paymentReference != null && paymentReference.trim().isNotEmpty)
        'paymentReference': paymentReference.trim(),
      if (proofText != null && proofText.trim().isNotEmpty)
        'proofText': proofText.trim(),
      if (proofFilePath != null)
        'proofFile': await MultipartFile.fromFile(proofFilePath),
    });
    final response = await _dio.post(
      AppConfig.sharePurchaseRequests(groupId),
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        extra: {'requiresAuth': true},
      ),
    );
    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid share proof response.');
    }
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }
}
