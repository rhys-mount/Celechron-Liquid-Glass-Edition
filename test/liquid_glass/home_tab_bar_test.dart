import 'dart:ui' show SemanticsAction;

import 'package:celechron/design/liquid_glass/home_tab_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  test('a short landscape phone and a portrait tablet keep the bottom bar', () {
    expect(homeNavigationRailWidth(const Size(914, 411)), isNull);
    expect(homeNavigationRailWidth(const Size(840, 1200)), isNull);
    expect(homeNavigationRailWidth(const Size(839, 600)), isNull);
    expect(homeNavigationRailWidth(const Size(840, 480)), 72);
    expect(homeNavigationRailWidth(const Size(1200, 800)), 176);
  });

  testWidgets('compact rail destinations expose labelled tap actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var selectedIndex = 0;
      await tester.pumpWidget(CupertinoApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: GlassHomeNavigationRail(
            width: 72,
            selectedIndex: selectedIndex,
            onSelected: (index) => selectedIndex = index,
          ),
        ),
      ));

      final destination = find.bySemanticsLabel('任务');
      final node = tester.getSemantics(destination);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(destination);
      expect(selectedIndex, 2);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('glass and Cupertino tabs use the same selection and ordering',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedIndex = 0;
    Future<void> mountBar({required bool useGlass}) async {
      await tester.pumpWidget(CupertinoApp(
        home: Builder(
          builder: (context) => Align(
            alignment: Alignment.bottomCenter,
            child: buildHomeTabBar(
              context,
              useGlass: useGlass,
              selectedIndex: selectedIndex,
              onSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      ));
      await tester.pump();
    }

    await mountBar(useGlass: true);
    final glassBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
    expect(glassBar.maskingQuality, MaskingQuality.high);
    expect(glassBar.quality, GlassQuality.minimal);
    expect(
        glassBar.tabs.map((tab) => tab.label), ['接下来', '日程', '任务', '学业', '设置']);
    expect(glassBar.preferredSize.height, greaterThan(0));
    await tester.tap(find.text('任务'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(selectedIndex, 2);
    expect(tester.takeException(), isNull);

    await mountBar(useGlass: false);
    final cupertinoBar =
        tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar));
    expect(cupertinoBar.items.map((tab) => tab.label),
        ['接下来', '日程', '任务', '学业', '设置']);
    expect(cupertinoBar.currentIndex, 2);
    await tester.tap(find.text('设置'));
    expect(selectedIndex, 4);
  });
}
