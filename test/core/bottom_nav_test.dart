import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiermetry/core/widgets/bottom_nav.dart';

void main() {
  testWidgets('bottom navigation is compact and changes destination', (
    tester,
  ) async {
    var selectedIndex = 0;

    Widget buildApp() {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: StatefulBuilder(
              builder: (context, setState) {
                return BottomNav(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: const [
                    BottomNavItem(iconBuilder: _icon, label: 'Home'),
                    BottomNavItem(iconBuilder: _icon, label: 'Arenas'),
                    BottomNavItem(iconBuilder: _icon, label: 'Explore'),
                    BottomNavItem(iconBuilder: _icon, label: 'Profile'),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    expect(tester.getSize(find.byType(BottomNav)).height, 72);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation keeps a long destination label contained', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: BottomNav(
              currentIndex: 3,
              onTap: (_) {},
              items: const [
                BottomNavItem(iconBuilder: _icon, label: 'Home'),
                BottomNavItem(iconBuilder: _icon, label: 'Arenas'),
                BottomNavItem(iconBuilder: _icon, label: 'Explore'),
                BottomNavItem(
                  iconBuilder: _icon,
                  label: 'International championships',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _icon(double size, Color color) =>
    Icon(Icons.circle, size: size, color: color);
