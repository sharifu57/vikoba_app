import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:vikoba_app/features/member/data/member_dashboard_api.dart';
import 'package:vikoba_app/app/constants/app_colors.dart';
import 'package:vikoba_app/features/member/presentation/member_controller.dart';
import 'package:vikoba_app/features/member/presentation/member_action_pages.dart';

class MeetingControllerStub extends MemberController {
  MeetingControllerStub(this.allowed) : super(api: MemberDashboardApi(Dio()));
  final bool allowed;
  final posted = <String>[];
  @override
  Future<void> loadDashboard({bool showError = true}) async {}
  @override
  Future<Map<String, dynamic>> loadMeetingDetails(int id) async {
    meetingAttendance[id] = {'status': allowed ? 'PRESENT' : 'ABSENT'};
    return {'id': id, 'title': 'Our meeting', 'meetingDate': '2026-10-01'};
  }

  @override
  Future<Map<String, dynamic>> loadMeetingComments(int id) async => {
    'canComment': allowed,
    'reason': 'You must be marked PRESENT to comment on this meeting.',
    'comments': [
      {
        'memberName': 'Asha',
        'content': 'Keep a record of our decisions',
        'createdAt': '2026-10-01T10:00:00',
      },
    ],
  };
  @override
  Future<List<Map<String, dynamic>>> loadLoanSchedule(int loanId) async => [
    {
      'installmentNumber': 1,
      'dueDate': '2026-09-01',
      'principalAmount': 9000,
      'interestAmount': 1000,
      'penaltyAmount': 2000,
      'totalAmount': 12000,
      'paidAmount': 0,
      'balance': 12000,
      'status': 'OVERDUE',
    },
    {
      'installmentNumber': 2,
      'dueDate': '2026-11-01',
      'principalAmount': 9000,
      'interestAmount': 1000,
      'penaltyAmount': 0,
      'totalAmount': 10000,
      'paidAmount': 0,
      'balance': 10000,
      'status': 'PENDING',
    },
  ];
  @override
  Future<void> addMeetingComment(int id, String content) async {
    posted.add(content);
  }
}

void main() {
  tearDown(() => Get.reset());
  for (final allowed in [true, false]) {
    testWidgets('server eligibility $allowed controls meeting comment form', (
      tester,
    ) async {
      final controller = MeetingControllerStub(allowed);
      Get.put<MemberController>(controller);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, child) => const GetMaterialApp(
            home: MemberMeetingDetailPage(meeting: {'id': 9}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Comments & suggestions'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(TextField), allowed ? findsOneWidget : findsNothing);
      if (allowed) {
        await tester.enterText(find.byType(TextField), 'Let us save more');
        await tester.ensureVisible(find.text('Post comment'));
        await tester.tap(find.text('Post comment'));
        await tester.pumpAndSettle();
        expect(controller.posted, ['Let us save more']);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      } else {
        expect(
          find.text('You must be marked PRESENT to comment on this meeting.'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'repayment shows actual unpaid fine in red and no fine on future row',
    (tester) async {
      Get.put<MemberController>(MeetingControllerStub(true));
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, child) => const GetMaterialApp(
            home: MemberLoanDetailsPage(
              loan: {
                'id': 1,
                'loanNumber': 'LN-1',
                'latePaymentFine': 2000,
                'totalAmount': 20000,
                'remainingBalance': 20000,
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final table = find.byType(DataTable);
      expect(find.text('TZS 22,000.00'), findsNWidgets(2));
      await tester.scrollUntilVisible(
        table,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final redFine = tester.widgetList<Text>(
        find.descendant(of: table, matching: find.text('TZS 2,000.00')),
      );
      expect(redFine.single.style?.color, AppColors.error);
      expect(
        find.descendant(of: table, matching: find.text('TZS 0.00')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
