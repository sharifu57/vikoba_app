import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vikoba_app/app/widgets/vikoba_loader.dart';

void main() {
  testWidgets('loader respects reduced motion and button constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox.square(dimension: 18, child: VikobaLoader()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CustomPaint).last), const Size(18, 18));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh uses branded loader and removes it after completion', (
    tester,
  ) async {
    final refresh = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VikobaRefreshIndicator(
            onRefresh: () {
              calls++;
              return refresh.future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [Text('Member shares')],
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    expect(find.byType(VikobaLoader), findsOneWidget);
    refresh.complete();
    await tester.pumpAndSettle();
    expect(find.byType(VikobaLoader), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
