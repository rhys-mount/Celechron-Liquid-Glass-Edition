import 'package:celechron/model/option.dart';
import 'package:celechron/design/course_search_field.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/model/semester.dart';
import 'package:celechron/page/scholar/scholar_controller.dart';
import 'package:celechron/page/scholar/scholar_view.dart';
import 'package:celechron/page/search/search_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _RefreshScholarController extends ScholarController {
  int refreshCount = 0;

  @override
  Future<List<String?>> fetchData() async {
    refreshCount++;
    return [];
  }
}

void main() {
  const descending = [
    '2026-2027秋冬',
    '2025-2026春夏',
    '2025-2026秋冬',
    '2024-2025春夏',
    '2024-2025秋冬',
  ];
  const alphabetic = [
    '2026-2027秋冬',
    '2025-2026秋冬',
    '2025-2026春夏',
    '2024-2025秋冬',
    '2024-2025春夏',
  ];

  test('缓存中的旧学期顺序会恢复为时间倒序', () {
    final scholar = Scholar.fromJson({
      'semesters': [for (final name in alphabetic) Semester(name).toJson()],
    });
    expect(scholar.semesters.map((semester) => semester.name), descending);
    expect(scholar.thisSemester.name, descending.first);
  });

  test('课表刷新失败时合并新旧学期仍按时间倒序', () {
    final scholar = Scholar()
      ..semesters = [for (final name in alphabetic.skip(1)) Semester(name)];
    final cached = scholar.semesters.first;

    scholar.setScholar(
        ['课表查询出错'], [Semester(alphabetic.first)], {}, [], {}, [], null);

    expect(scholar.semesters.map((semester) => semester.name), descending);
    expect(scholar.semesters[2], same(cached));
  });

  testWidgets('学业页在登录后即使没有缓存也可从大标题下方下拉刷新', (tester) async {
    final originalErrorBuilder = ErrorWidget.builder;
    addTearDown(() {
      ErrorWidget.builder = originalErrorBuilder;
      Get.reset();
    });
    Get.put(
      Option(
        workTime: const Duration(minutes: 25).obs,
        restTime: const Duration(minutes: 5).obs,
        allowTime: <DateTime, DateTime>{}.obs,
        gpaStrategy: GpaStrategy.best.obs,
        pushOnGradeChange: false.obs,
        pushOnDdlReminder: false.obs,
        brightnessMode: BrightnessMode.system.obs,
        courseIdMappingList: <CourseIdMap>[].obs,
        hideHomeGpa: false.obs,
        asyncRefresh: false.obs,
      ),
      tag: 'option',
    );
    final scholar = Get.put(Scholar().obs, tag: 'scholar');
    final controller = _RefreshScholarController();
    Get.put<ScholarController>(controller);
    final page = ScholarPage();
    ErrorWidget.builder = originalErrorBuilder;
    await tester.pumpWidget(CupertinoApp(
      home: page,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: false),
        child: child!,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoSliverRefreshControl), findsNothing);

    scholar.value.isLogan = true;
    scholar.refresh();
    await tester.pumpAndSettle();
    expect(find.text('下拉刷新以获取数据'), findsOneWidget);
    await tester.dragFrom(const Offset(300, 230), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(controller.refreshCount, 1);

    final semantics = tester.ensureSemantics();
    try {
      final source = tester.getRect(find.byType(CupertinoSearchTextField));
      await tester.tap(find.descendant(
          of: find.byType(CourseSearchField),
          matching: find.byType(CupertinoButton)));
      await tester.pump();
      final input = find.descendant(
          skipOffstage: false,
          of: find.byType(SearchPage, skipOffstage: false),
          matching: find.byType(CupertinoSearchTextField, skipOffstage: false));
      expect(tester.getRect(input), source);
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.pump(const Duration(milliseconds: 170));
      final middle = tester.getRect(input);
      expect(middle.top, lessThan(source.top));
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsOneWidget);
      final expanded = tester.getRect(input);
      expect(expanded.top, lessThan(middle.top));
      expect(expanded.width, lessThan(source.width));
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(input, '无匹配课程');
      await tester.pumpAndSettle();
      expect(find.text('没有匹配的课程'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('取消'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 130));
      expect(tester.getRect(input).top, greaterThan(expanded.top));
      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsNothing);
      expect(tester.getRect(find.byType(CupertinoSearchTextField)), source);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
    Get.delete<ScholarController>(force: true);
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));

  testWidgets('减少动态效果时跳过位移动画并仍然聚焦搜索', (tester) async {
    addTearDown(Get.reset);
    Get.put(Scholar().obs, tag: 'scholar');
    await tester.pumpWidget(CupertinoApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const CupertinoPageScaffold(
        child: Center(child: CourseSearchLauncher()),
      ),
    ));
    final prior = tester.getTopLeft(find.byType(CupertinoSearchTextField)).dy;
    await tester.tap(find.byType(CupertinoButton));
    await tester.pump();
    final input = find.descendant(
        of: find.byType(SearchPage),
        matching: find.byType(CupertinoSearchTextField));
    expect(tester.getTopLeft(input).dy, lessThan(prior));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsNothing);
    expect(tester.getTopLeft(find.byType(CupertinoSearchTextField)).dy, prior);
  });
}
