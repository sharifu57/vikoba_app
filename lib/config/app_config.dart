import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  static const Duration connectTimeout = Duration(seconds: 20);

  static const Duration receiveTimeout = Duration(seconds: 20);

  static String get auth => "$baseUrl/api/auth";

  static String get lookUp => "$auth/lookup";
  static String get register => "$auth/register";
  static String get verifyOtp => "$auth/verify-otp";
  static String get resendOtp => "$auth/resend-otp";
  static String get refreshToken => "$auth/refresh";
  static String get logout => "$auth/logout";
  static String get shares => "$baseUrl/api/shares";

  static String dashboardGroup(int groupId) =>
      "$baseUrl/api/dashboard/group/$groupId";

  static String groupMembers(int groupId) =>
      "$baseUrl/api/members/group/$groupId";

  static String shareSummary(int groupId) => "$shares/group/$groupId/summary";

  static String shareLedger(int groupId) => "$shares/group/$groupId/ledger";

  static String purchaseShares(int groupId) =>
      "$shares/group/$groupId/purchase";

  static String sharePurchaseRequests(int groupId) =>
      "$baseUrl/api/share-purchase-requests/group/$groupId";

  static String fines(int groupId) => "$baseUrl/api/fines?groupId=$groupId";

  static String meetings(int groupId) =>
      "$baseUrl/api/groups/$groupId/meetings";
  static String meeting(int meetingId) => "$baseUrl/api/meetings/$meetingId";
  static String meetingAttendance(int meetingId) =>
      "${meeting(meetingId)}/attendance";

  static String loans(int groupId) => "$baseUrl/api/loans/group/$groupId";
  static String loanApplicationContext(int groupId) =>
      "${loans(groupId)}/application-context";
  static String loanApplications(int groupId) =>
      "${loans(groupId)}/applications";
  static String loanGuarantees(int groupId) =>
      "${loans(groupId)}/guarantees/mine";
  static String loanGuaranteeDecision(
    int groupId,
    int guaranteeId,
    String decision,
  ) => "${loans(groupId)}/guarantees/$guaranteeId/$decision";
  static String replaceLoanGuarantor(
    int groupId,
    int loanId,
    int guaranteeId,
  ) => "${loans(groupId)}/$loanId/guarantors/$guaranteeId/replace";
  static String loanDecision(int groupId, int loanId, String action) =>
      "${loans(groupId)}/$loanId/$action";
  static String loanSchedule(int groupId, int loanId) =>
      "${loans(groupId)}/$loanId/schedule";
}
