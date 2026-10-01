import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';
import 'package:vikoba_app/features/member/presentation/group_selection_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'groups': jsonEncode([
        {
          'groupMemberId': 31,
          'role': 'MEMBER',
          'group': {
            'groupId': 11,
            'groupName': 'Umoja Circle',
            'currency': 'TZS',
          },
        },
        {
          'groupMemberId': 42,
          'role': 'GROUP_TREASURER',
          'permissions': ['CONTRIBUTION_MANAGE'],
          'group': {
            'groupId': 22,
            'groupName': 'Jitegemee Circle',
            'organizationName': 'Jitegemee Union',
            'groupCode': 'JIT-22',
            'currency': 'TZS',
          },
        },
      ]),
    });
  });

  tearDown(() => Get.reset());

  testWidgets('selecting a group stores its membership and role', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, child) => GetMaterialApp(
          initialRoute: '/select-group',
          getPages: [
            GetPage(
              name: '/select-group',
              page: () => const GroupSelectionPage(),
            ),
            GetPage(
              name: '/member',
              page: () =>
                  const Scaffold(body: Text('Selected group dashboard')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Umoja Circle'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Jitegemee Circle'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Jitegemee Circle'), findsOneWidget);
    expect(find.text('GROUP TREASURER'), findsOneWidget);
    await tester.tap(find.text('Jitegemee Circle'));
    await tester.pumpAndSettle();

    expect(find.text('Selected group dashboard'), findsOneWidget);
    expect(await TokenStorage.getCurrentGroupId(), 22);
    expect(await TokenStorage.getCurrentGroupMemberId(), 42);
    expect(await TokenStorage.getCurrentGroupRole(), 'GROUP_TREASURER');
    expect(await TokenStorage.getCurrentGroupPermissions(), [
      'CONTRIBUTION_MANAGE',
    ]);
  });
}
