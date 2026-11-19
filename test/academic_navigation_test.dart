import 'dart:ui' show Tristate;

import 'package:celechron/database/database_helper.dart';
import 'package:celechron/design/two_line_card.dart';
import 'package:celechron/model/grade.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/model/semester.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'package:celechron/page/scholar/course_list/course_list_view.dart';
import 'package:celechron/page/scholar/course_schedule/course_card.dart';
import 'package:celechron/page/scholar/course_schedule/course_schedule_view.dart';
import 'package:celechron/page/scholar/exam_list/exam_list_controller.dart';
import 'package:celechron/page/scholar/exam_list/exam_list_view.dart';
import 'package:celechron/page/scholar/grade_detail/grade_detail_controller.dart';
import 'package:celechron/page/scholar/grade_detail/grade_detail_view.dart';
import 'package:celechron/page/scholar/grade_detail/weighted_gpa_controller.dart';
import 'package:celechron/page/scholar/grade_detail/weighted_gpa_view.dart';
import 'package:celechron/page/scholar/practice_score/practice_score_page.dart';
import 'package:celechron/page/search/search_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets('成绩空态在缓存刷新后恢复，所选学期消失后回到有效项', (tester) async {
    final source = Get.find<Rx<Scholar>>(tag: 'scholar');
    final populated = source.value;
    source.value = Scholar()..semesters = [Semester(academicSemester)];
    await openPage(tester, (_) => GradeDetailPage());
    expect(find.textContaining('暂无成绩'), findsOneWidget);
    source.value = populated;
    await tester.pumpAndSettle();
    expect(find.text(academicCourse), findsOneWidget);
    final controller = Get.find<GradeDetailController>();
    final newer = Semester('2027-2028秋冬')
      ..grades.add(populated.semesters.first.grades.first);
    source.value = Scholar()..semesters = [newer, populated.semesters.first];
    await tester.pumpAndSettle();
    expect(controller.selectedIndex, 1);
    source.value = Scholar()..semesters = [newer];
    await tester.pumpAndSettle();
    expect(controller.selectedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('课程 ID 缓存未命中时提供可返回的空态，重新同步后可显示', (tester) async {
    final source = Get.find<Rx<Scholar>>(tag: 'scholar');
    final populated = source.value;
    source.value = Scholar();
    await openPage(tester, (_) => CourseDetailPage(courseId: academicCourseId));
    expect(find.textContaining('暂未同步到这门课'), findsOneWidget);
    expect(find.byType(CupertinoNavigationBarBackButton), findsOneWidget);
    source.value = populated;
    await tester.pumpAndSettle();
    expect(find.text(academicCourse), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
      final segments =
          find.byType(CupertinoSlidingSegmentedControl<double>).first;
      await tester.ensureVisible(segments);
      await tester.pumpAndSettle();
      Finder preset(String label) => find.descendant(
            of: segments,
            matching: find.bySemanticsLabel(label),
          );
      expect(
          tester
              .getSemantics(preset('1.1 倍'))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          Tristate.isTrue);
      expect(tester.getSize(segments).height, greaterThanOrEqualTo(44));
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        tester.getSemantics(preset('1.0 倍')).id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(weights.getWeight(academicCourseId), 1.0);
      await tester.tap(preset('1.1 倍'));
      await tester.pumpAndSettle();
      expect(weights.getWeight(academicCourseId), 1.1);
      final from = tester.getCenter(preset('1.1 倍'));
      final to = tester.getCenter(preset('1.2 倍'));
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      expect(weights.getWeight(academicCourseId), 1.2);
      await tester.drag(
          find.byType(CustomScrollView).last, const Offset(0, 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部学期'));
      await tester.pumpAndSettle();
      expect(weights.showAllSemesters.value, isTrue);
      await tester.tap(find.text('重置倍率'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CupertinoDialogAction, '取消'));
      await tester.pumpAndSettle();
      expect(weights.getWeight(academicCourseId), 1.2);
      await tester.tap(find.text('重置倍率'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CupertinoDialogAction, '重置倍率'));
      await tester.pumpAndSettle();
      expect(weights.getWeight(academicCourseId), 1.0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('全部学期仅统计勾选的课程，取消选择时保留倍率', (tester) async {
    final scholar = Get.find<Rx<Scholar>>(tag: 'scholar').value;
    final previousGrade = Grade({
      'xkkh': '(2025-2026-2)-DEMO01-01',
      'kcmc': '往期课程',
      'cj': '80',
      'xf': 2,
      'jd': 3,
    });
    scholar.semesters.last.grades.add(previousGrade);
    scholar.grades[previousGrade.realId] = [previousGrade];

    await openPage(tester, (_) => WeightedGpaPage(),
        width: 320, textScale: 1.5);
    expect(find.byType(CupertinoCheckbox), findsNothing);
    await tester.tap(find.text('全部学期'));
    await tester.pumpAndSettle();
    expect(find.text('已选 25 / 25 门'), findsOneWidget);
    String metric(String title) => tester
        .widget<TwoLineCard>(find.byWidgetPredicate(
            (widget) => widget is TwoLineCard && widget.title == title))
        .content;
    expect(metric('加权学分'), '74.0');
    await tester.tap(find.text('清空勾选'));
    await tester.pumpAndSettle();
    expect(metric('加权学分'), '0.0');
    expect(metric('加权五分制'), '0.00');

    final priorCourse = find.text('往期课程');
    await tester.ensureVisible(priorCourse);
    await tester.pumpAndSettle();
    await tester.tap(priorCourse);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 / 25 门'), findsOneWidget);
    expect(metric('加权学分'), '2.0');
    expect(metric('加权五分制'), '3.00');
    expect(Get.find<WeightedGpaController>().getWeight(academicCourseId), 1.1);

    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    expect(metric('加权学分'), '74.0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('成绩页按缓存校正后的顺序列出同一学年的两个学期', (tester) async {
    final scholar = Get.find<Rx<Scholar>>(tag: 'scholar');
    final grade = scholar.value.semesters.first.grades.first;
    Map<String, dynamic> cachedTerm(String name) =>
        Semester(name).toJson()..['grades'] = [grade.toJson()];
    scholar.value = Scholar.fromJson({
      'semesters': [cachedTerm('2025-2026秋冬'), cachedTerm('2025-2026春夏')],
    });
    final semantics = tester.ensureSemantics();
    try {
      await openPage(tester, (_) => GradeDetailPage(),
          width: 320, textScale: 1.5);
      final springChip = find.text('25-26春夏');
      final autumnChip = find.text('25-26秋冬');
      expect(springChip.hitTestable(), findsOneWidget);
      final controller = Get.find<GradeDetailController>();
      expect(controller.semesterIndex.value, 0);
      expect(controller.semestersWithGrades.map((term) => term.name),
          ['2025-2026春夏', '2025-2026秋冬']);
      final picker = find.byWidgetPredicate((widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal);
      await tester.drag(picker, const Offset(-240, 0));
      await tester.pumpAndSettle();
      await tester.tap(autumnChip);
      await tester.pumpAndSettle();
      expect(controller.semesterIndex.value, 1);
      await tester.tap(find.bySemanticsLabel('自定义绩点'));
      await tester.pumpAndSettle();
      await tester.longPress(autumnChip);
      await tester.pumpAndSettle();
      expect(controller.customGpaSelected[academicCourseId], isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('按住后拖动成绩列表不修改自定义选课，松手点击才修改', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await openPage(tester, (_) => GradeDetailPage());
      await tester.tap(find.bySemanticsLabel('自定义绩点'));
      await tester.pumpAndSettle();
      final controller = Get.find<GradeDetailController>();
      final course = find.text(academicCourse).hitTestable();
      final gesture = await tester.startGesture(tester.getCenter(course));
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.moveBy(const Offset(0, -90));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.customGpaSelected[academicCourseId], isTrue);
      await tester.ensureVisible(find.text(academicCourse));
      await tester.pumpAndSettle();
      await tester.tap(course);
      await tester.pumpAndSettle();
      expect(controller.customGpaSelected[academicCourseId], isFalse);
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

  testWidgets('考试列表从固定学期栏下方滚过，学期仍可切换', (tester) async {
    try {
      await openPage(
        tester,
        (_) => const ExamListPage(initialSemesterName: academicSemester),
      );
      expect(find.text(academicCourse), findsOneWidget);
      expect(find.text('请务必前往教务网核对'), findsOneWidget);
      final previousSemester = find.text('25-26春夏');
      final scroll =
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      scroll.jumpTo(80);
      await tester.pump();
      final pinned = tester.getRect(previousSemester);
      final examTitle = find.text(academicCourse);
      scroll.jumpTo(
          scroll.pixels + tester.getTopLeft(examTitle).dy - pinned.top - 4);
      await tester.pump();
      expect(tester.getTopLeft(examTitle).dy,
          inExclusiveRange(pinned.top, pinned.bottom));
      expect(tester.getRect(previousSemester), pinned);
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
    final semantics = tester.ensureSemantics();
    try {
      await openPage(tester, (_) => const SearchPage());
      await tester.enterText(
          find.byType(CupertinoSearchTextField), academicCourse);
      await tester.pumpAndSettle();
      expect(find.text(academicCourse), findsWidgets);
      await tester.tap(find.bySemanticsLabel('取消'));
      await tester.pumpAndSettle();
      expect(find.text('打开学业页面'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('课程详情显示课时和考试二级内容', (tester) async {
    await openPage(tester, (_) => CourseDetailPage(courseId: academicCourseId));
    expect(find.text(academicCourse), findsOneWidget);
    expect(find.text('课时'), findsOneWidget);
    expect(find.textContaining('演示教室'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('课表显示学期筛选和课程网格', (tester) async {
    await openPage(tester, (_) => CourseSchedulePage(academicSemester, true),
        textScale: 1.5);
    expect(find.text('26-27秋冬'), findsOneWidget);
    expect(find.text('星期一'), findsNothing);
    expect(find.byType(SessionCard), findsWidgets);
    expect(find.text('秋学期课时'), findsOneWidget);
    expect(find.text('冬学期课时'), findsOneWidget);
    final autumnCard = find.byWidgetPredicate(
        (widget) => widget is TwoLineCard && widget.title == '秋学期课时');
    final autumnSurface = find.descendant(
      of: autumnCard,
      matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration),
    );
    expect(tester.getSize(autumnSurface).width, closeTo(148, 1));
    await tester.tap(find.text(academicCourse).hitTestable().first);
    await tester.pumpAndSettle();
    final details = tester.element(find.byType(CourseDetailPage));
    expect(ModalRoute.of(details), isA<CupertinoPageRoute<void>>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('从成绩卡打开课程详情时由右侧推入', (tester) async {
    await openPage(tester, (_) => GradeDetailPage());
    await tester.ensureVisible(find.text(academicCourse));
    await tester.tap(find.text(academicCourse).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final details = find.byType(CourseDetailPage);
    expect(tester.getTopLeft(details).dx, greaterThan(0));
    expect(tester.getTopLeft(details).dy, closeTo(0, 0.01));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(details).dx, closeTo(0, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('课表课程块跟随应用亮暗主题，小字保持对比度', (tester) async {
    final session = Get.find<Rx<Scholar>>(tag: 'scholar')
        .value
        .semesters
        .first
        .sessions
        .first;
    const accent = CupertinoDynamicColor.withBrightness(
      color: Color(0xFF003F88),
      darkColor: Color(0xFF0A84FF),
    );
    for (final brightness in Brightness.values) {
      final systemBrightness =
          brightness == Brightness.dark ? Brightness.light : Brightness.dark;
      await tester.pumpWidget(CupertinoApp(
        theme: CupertinoThemeData(
          brightness: brightness,
          primaryColor: accent,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(platformBrightness: systemBrightness),
          child: child!,
        ),
        home: Center(
          child: SizedBox(
            width: 120,
            height: 84,
            child: SessionCard(sessionList: [session]),
          ),
        ),
      ));
      final title = find.text(session.name);
      final fill = tester.widget<Container>(find.ancestor(
        of: title,
        matching: find.byWidgetPredicate((widget) =>
            widget is Container && widget.decoration is BoxDecoration),
      ));
      final background = (fill.decoration! as BoxDecoration).color!;
      if (brightness == Brightness.dark) {
        expect(background.b, greaterThan(accent.color.b));
        expect(background.b, lessThan(accent.darkColor.b));
      } else {
        expect(background.toARGB32(), accent.color.toARGB32());
      }
      for (final text in [title, find.text(session.location!)]) {
        final foreground = tester.widget<Text>(text).style!.color!;
        if (brightness == Brightness.dark) {
          expect(foreground, CupertinoColors.white);
        }
        final bgLuminance = background.computeLuminance() + 0.05;
        final fgLuminance = foreground.computeLuminance() + 0.05;
        final ratio = fgLuminance > bgLuminance
            ? fgLuminance / bgLuminance
            : bgLuminance / fgLuminance;
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    }
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
