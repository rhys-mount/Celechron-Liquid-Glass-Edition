import 'package:celechron/database/database_helper.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'package:celechron/page/scholar/course_list/course_list_view.dart';
import 'package:celechron/page/scholar/course_schedule/course_schedule_view.dart';
import 'package:celechron/page/scholar/exam_list/exam_list_controller.dart';
import 'package:celechron/page/scholar/exam_list/exam_list_view.dart';
import 'package:celechron/page/scholar/grade_detail/grade_detail_controller.dart';
import 'package:celechron/page/scholar/grade_detail/grade_detail_view.dart';
import 'package:celechron/page/scholar/grade_detail/weighted_gpa_controller.dart';
import 'package:celechron/page/scholar/practice_score/practice_score_page.dart';
import 'package:celechron/page/search/search_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/academic_fixture.dart';

class _AcademicOptions extends DatabaseHelper {
  @override
  Map<String, bool> getCustomGpa() => {academicCourseId: true};

  @override
  Future<void> setCustomGpa(Map<String, bool> selectList) async {}

  @override
  Map<String, double> getWeightedGpa() => {academicCourseId: 1.1};

  @override
  Future<void> setWeightedGpa(Map<String, double> weightedMap) async {}
}

void main() {
  setUp(() {
    Get.put<DatabaseHelper>(_AcademicOptions(), tag: 'db');
    Get.put<Rx<Scholar>>(academicFixture().obs, tag: 'scholar');
  });

  tearDown(Get.reset);

  Future<void> openPage(
    WidgetTester tester,
    WidgetBuilder builder, {
    Brightness brightness = Brightness.light,
    double width = 360,
    double textScale = 1.2,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(CupertinoApp(
      theme: CupertinoThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) => CupertinoPageScaffold(
          child: Center(
            child: CupertinoButton(
              onPressed: () => Navigator.of(context).push<void>(
                CupertinoPageRoute(builder: builder),
              ),
              child: const Text('打开学业页面'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('打开学业页面'));
    await tester.pumpAndSettle();
  }

  testWidgets('课程列表标题随滚动收起，选择器和返回可用', (tester) async {
    await openPage(
      tester,
      (_) => CourseListPage(initialSemesterName: academicSemester),
    );
    final back = find.byType(CupertinoNavigationBarBackButton);
    final selector = find.text('26-27秋冬');
    final expandedPosition = tester.getTopLeft(selector).dy;
    expect(expandedPosition - tester.getTopLeft(back).dy, greaterThan(60));

    await tester.drag(find.text(academicCourse), const Offset(0, -430));
    await tester.pumpAndSettle();
    final collapsedPosition = tester.getTopLeft(selector).dy;
    expect(expandedPosition - collapsedPosition, greaterThan(30));
    expect(collapsedPosition, greaterThan(tester.getBottomLeft(back).dy));
    expect(selector.hitTestable(), findsOneWidget);
    expect(find.text(academicCourse).hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('打开学业页面'), findsOneWidget);
  });

  testWidgets('窄屏深色下成绩工具仍能切换模式和清理选择', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await openPage(tester, (_) => GradeDetailPage(),
          brightness: Brightness.dark);
      await tester.tap(find.bySemanticsLabel('自定义绩点'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('长按清空'));
      await tester.pumpAndSettle();
      expect(Get.find<GradeDetailController>().customGpaSelected, isEmpty);
      await tester.tap(find.bySemanticsLabel('退出自定义绩点'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('加权成绩'));
      await tester.pumpAndSettle();

      final weights = Get.find<WeightedGpaController>();
      expect(weights.getWeight(academicCourseId), 1.1);
      await tester.tap(find.text('全部学期'));
      await tester.pumpAndSettle();
      expect(weights.showAllSemesters.value, isTrue);
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(weights.getWeight(academicCourseId), 1.0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('小屏大字号课程卡可打开长标题、课时和考场', (tester) async {
    final course = Get.find<Rx<Scholar>>(tag: 'scholar')
        .value
        .semesters
        .first
        .courses[academicCourseId]!;
    const title = '数字信号处理与面向真实场景的跨学期综合设计实验';
    course
      ..name = title
      ..teacher = '课程教学与实验指导团队';
    await openPage(
      tester,
      (_) => CourseListPage(initialSemesterName: academicSemester),
      brightness: Brightness.dark,
      width: 320,
      textScale: 1.5,
    );
    final heading = find.text(title).hitTestable();
    expect(heading, findsOneWidget);
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(find.text('基本信息'), findsOneWidget);
    expect(find.text('教师 课程教学与实验指导团队'), findsOneWidget);
    expect(find.text('课时'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('地点 演示考场 01').hitTestable(), 150);
    expect(find.text('地点 演示考场 01').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('考试列表有数据时切换学期并保留核对提示', (tester) async {
    try {
      await openPage(
        tester,
        (_) => const ExamListPage(initialSemesterName: academicSemester),
      );
      expect(find.text(academicCourse), findsOneWidget);
      expect(find.text('请务必前往教务网核对'), findsOneWidget);
      final previousSemester = find.text('25-26春夏');
      final gesture =
          await tester.startGesture(tester.getCenter(previousSemester));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('往期演示课程'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      if (Get.isRegistered<ExamListController>()) {
        Get.find<ExamListController>().onClose();
      }
    }
  });

  testWidgets('搜索有结果时可以直接取消返回', (tester) async {
    await openPage(tester, (_) => SearchPage());
    await tester.enterText(
        find.byType(CupertinoSearchTextField), academicCourse);
    await tester.pumpAndSettle();
    expect(find.text(academicCourse), findsWidgets);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('打开学业页面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('课程详情显示课时和考试二级内容', (tester) async {
    await openPage(tester, (_) => CourseDetailPage(courseId: academicCourseId));
    expect(find.text(academicCourse), findsOneWidget);
    expect(find.text('课时'), findsOneWidget);
    expect(find.textContaining('演示教室'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('课表显示学期筛选和课程网格', (tester) async {
    await openPage(tester, (_) => CourseSchedulePage(academicSemester, true));
    expect(find.text('秋学期课时'), findsOneWidget);
    expect(find.text('冬学期课时'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('实践二级列表可以打开项目明细', (tester) async {
    await openPage(
      tester,
      (_) => PracticeScorePage(scholar: academicFixture(), categoryId: 1),
    );
    await tester.tap(find.text('演示实践项目'));
    await tester.pumpAndSettle();
    expect(find.text('项目名称'), findsOneWidget);
    expect(find.text('演示实践项目'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
