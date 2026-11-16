import 'package:celechron/design/liquid_glass/home_tab_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
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
    expect(glassBar.maskingQuality, MaskingQuality.off);
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
