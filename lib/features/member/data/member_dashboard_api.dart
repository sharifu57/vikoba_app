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

  Future<List<Map<String, dynamic>>> getFines(int groupId) async {
    final response = await _dio.get(
      AppConfig.fines(groupId),
      options: Options(extra: {'requiresAuth': true}),
    );
    final body = response.data;
    if (body is! Map) throw const FormatException('Invalid fines response.');
    final data = body['data'];
    if (data is! List) return <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMeetings(int groupId) async =>
      _listResponse(
        await _dio.get(
          AppConfig.meetings(groupId),
          options: Options(extra: {'requiresAuth': true}),
        ),
        'meetings',
      );

  Future<Map<String, dynamic>> getMeeting(int meetingId) async => _mapResponse(
    await _dio.get(
      AppConfig.meeting(meetingId),
      options: Options(extra: {'requiresAuth': true}),
    ),
    'meeting',
  );

  Future<List<Map<String, dynamic>>> getMeetingAttendance(
    int meetingId,
  ) async => _listResponse(
    await _dio.get(
      AppConfig.meetingAttendance(meetingId),
      options: Options(extra: {'requiresAuth': true}),
    ),
    'meeting attendance',
  );

  Future<Map<String, dynamic>> getLoanApplicationContext(int groupId) async =>
      _mapResponse(
        await _dio.get(
          AppConfig.loanApplicationContext(groupId),
          options: Options(extra: {'requiresAuth': true}),
        ),
        'loan application context',
      );

  Future<List<Map<String, dynamic>>> getLoans(int groupId) async =>
      _listResponse(
        await _dio.get(
          AppConfig.loans(groupId),
          options: Options(extra: {'requiresAuth': true}),
        ),
        'loans',
      );

  Future<List<Map<String, dynamic>>> getGuaranteeRequests(int groupId) async =>
      _listResponse(
        await _dio.get(
          AppConfig.loanGuarantees(groupId),
          options: Options(extra: {'requiresAuth': true}),
        ),
        'guarantee requests',
      );

  Future<Map<String, dynamic>> applyForLoan(
    int groupId, {
    required double amount,
    required int durationMonths,
    required String purpose,
    required List<int> guarantorIds,
  }) async => _mapResponse(
    await _dio.post(
      AppConfig.loanApplications(groupId),
      data: {
        'principalAmount': amount,
        'durationMonths': durationMonths,
        'purpose': purpose,
        'guarantorIds': guarantorIds,
        'consentAccepted': true,
      },
      options: Options(extra: {'requiresAuth': true}),
    ),
    'loan application',
  );

  Future<Map<String, dynamic>> decideGuarantee(
    int groupId,
    int guaranteeId,
    bool accept,
  ) async => _mapResponse(
    await _dio.post(
      AppConfig.loanGuaranteeDecision(
        groupId,
        guaranteeId,
        accept ? 'accept' : 'reject',
      ),
      options: Options(extra: {'requiresAuth': true}),
    ),
    'guarantee decision',
  );

  Future<Map<String, dynamic>> replaceGuarantor(
    int groupId,
    int loanId,
    int guaranteeId,
    int replacementId,
  ) async => _mapResponse(
    await _dio.post(
      AppConfig.replaceLoanGuarantor(groupId, loanId, guaranteeId),
      data: {'replacementId': replacementId},
      options: Options(extra: {'requiresAuth': true}),
    ),
    'guarantor replacement',
  );

  Future<Map<String, dynamic>> reviewLoan(
    int groupId,
    int loanId,
    String action, {
    String? reason,
  }) async => _mapResponse(
    await _dio.post(
      AppConfig.loanDecision(groupId, loanId, action),
      data: reason == null ? <String, dynamic>{} : {'rejectionReason': reason},
      options: Options(extra: {'requiresAuth': true}),
    ),
    'loan workflow decision',
  );

  Future<List<Map<String, dynamic>>> getLoanSchedule(
    int groupId,
    int loanId,
  ) async => _listResponse(
    await _dio.get(
      AppConfig.loanSchedule(groupId, loanId),
      options: Options(extra: {'requiresAuth': true}),
    ),
    'loan repayment schedule',
  );

  Map<String, dynamic> _mapResponse(Response<dynamic> response, String label) {
    final body = response.data;
    if (body is! Map) throw FormatException('Invalid $label response.');
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listResponse(
    Response<dynamic> response,
    String label,
  ) {
    final body = response.data;
    if (body is! Map) throw FormatException('Invalid $label response.');
    final data = body['data'];
    if (data is! List) return <Map<String, dynamic>>[];
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
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
