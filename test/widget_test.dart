import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/features/wallet/presentation/widgets/three_scene_loop_tracker.dart';

void main() {
  testWidgets('App theme & ThreeSceneLoopTracker widget render test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: TiermetryColors.background,
          body: Center(
            child: ThreeSceneLoopTracker(
              currentScene: 1,
              loopIndex: 1,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('RETENTION LOOP #1'), findsOneWidget);
    expect(find.text('Scene 1 Done! ₹40 Key ready for Scene 2'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });
}
