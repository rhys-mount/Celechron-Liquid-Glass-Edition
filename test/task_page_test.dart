// issue #178 回归用例：
// 1) 任务页空状态必须随任务列表出现/消失，不能滞留在列表上方
// 2) 从任务卡片进入编辑页点“删除任务”应真正删除（与左滑删除共用同一实现）
import 'package:celechron/database/database_helper.dart';
import 'package:celechron/design/liquid_glass/home_scroll_insets.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/page/calendar/calendar_view.dart';
import 'package:celechron/page/flow/flow_controller.dart';
import 'package:celechron/page/flow/flow_view.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'package:celechron/page/task/task_controller.dart';
import 'package:celechron/page/task/task_edit_page.dart';
import 'package:celechron/page/task/task_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

import 'support/academic_fixture.dart';

class _ScholarWithPeriods extends Scholar {
  _ScholarWithPeriods(this.periods);

  @override
  final List<Period> periods;
}

class _FakeDb extends DatabaseHelper {
  List<Task> stored = <Task>[];
  List<Period> storedFlow = <Period>[];
  DateTime storedTime = DateTime.fromMicrosecondsSinceEpoch(0);

  @override
  List<Task> getTaskList() => stored;

  @override
  Future<void> setTaskList(List<Task> deadlineList) async {
    stored = List<Task>.of(deadlineList);
  }

  @override
  DateTime getTaskListUpdateTime() => storedTime;

  @override
  Future<void> setTaskListUpdateTime(DateTime deadlineListUpdateTime) async {
    storedTime = deadlineListUpdateTime;
  }

  @override
  List<Period> getFlowList() => storedFlow;

  @override
  Future<void> setFlowList(List<Period> flowList) async {
    storedFlow = List<Period>.of(flowList);
  }

  @override
  DateTime getFlowListUpdateTime() => storedTime;

  @override
  Future<void> setFlowListUpdateTime(DateTime flowListUpdateTime) async {
    storedTime = flowListUpdateTime;
  }

  // 重新规划会用到的偏好项，取与 DatabaseHelper 默认值一致的常量。
  @override
  Duration getWorkTime() => const Duration(minutes: 45);

  @override
  Duration getRestTime() => const Duration(minutes: 15);

  @override
  Map<DateTime, DateTime> getAllowTime() => <DateTime, DateTime>{
        DateTime(0, 0, 0, 8, 0): DateTime(0, 0, 0, 11, 35),
        DateTime(0, 0, 0, 14, 15): DateTime(0, 0, 0, 23, 0),
      };
}

Task _testTask({required String summary}) {
  final now = DateTime.now();
  return Task(
    endTime: now.add(const Duration(hours: 1)),
    startTime: now,
    repeatEndsTime: now,
    summary: summary,
  );
}

Iterable<Task> _aliveTasks(RxList<Task> taskList) =>
    taskList.where((element) => element.status != TaskStatus.deleted);

void main() {
  late RxList<Task> taskList;

  setUp(() {
    Get.reset();
    taskList = <Task>[].obs;
    Get.put<DatabaseHelper>(_FakeDb(), tag: 'db');
    Get.put<Rx<Scholar>>(Scholar().obs, tag: 'scholar');
    Get.put<RxList<Period>>(<Period>[].obs, tag: 'flowList');
    Get.put<Rx<DateTime>>(DateTime.now().obs, tag: 'flowListLastUpdate');
    Get.put<RxList<Task>>(taskList, tag: 'taskList');
    Get.put<Rx<DateTime>>(DateTime.now().obs, tag: 'taskListLastUpdate');
  });

  tearDown(() {
    Get.reset();
  });

  // TaskPage 构造出的两个 GetxController 各有一个每秒定时器。flutter_test 在测试体
  // 结束时就会检查 pending timer，晚于 tearDown，所以必须在测试体内部停掉。
  void stopPageTimers() {
    if (Get.isRegistered<TaskController>()) {
      Get.find<TaskController>().onClose();
    }
    if (Get.isRegistered<FlowController>()) {
      Get.find<FlowController>().onClose();
    }
  }

  Future<void> runPageTest(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } finally {
      stopPageTimers();
    }
  }

  Future<void> pumpTaskPage(WidgetTester tester) async {
    await tester.pumpWidget(CupertinoApp(home: TaskPage()));
    await tester.pump();
  }

  // 页面里有每秒触发的定时器，pumpAndSettle 永远等不到静止，只能按帧推进。
  Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    final int steps = (duration.inMilliseconds / 50).ceil();
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tapCard(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await pumpFor(tester, const Duration(milliseconds: 700));
  }

  Future<void> tapDeleteInEditPage(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('删除任务').hitTestable(),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('删除任务'));
    await pumpFor(tester, const Duration(milliseconds: 700));
  }

  testWidgets('规划过期时仍可从顶部重新规划', (tester) async {
    await runPageTest(tester, () async {
      Get.find<Rx<DateTime>>(tag: 'flowListLastUpdate').value =
          DateTime.fromMillisecondsSinceEpoch(0);
      await tester.pumpWidget(CupertinoApp(
        navigatorKey: Get.key,
        home: FlowPage(),
      ));

      expect(Get.find<FlowController>().isFlowListOutdated(), isTrue);
      expect(find.text('规划方案已过期'), findsNothing);
      expect(find.text('今日无事可做'), findsOneWidget);

      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('重新规划'));
      } finally {
        semantics.dispose();
      }
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.text('开始规划'), findsOneWidget);
      await tester.tap(find.text('返回'));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.text('开始规划'), findsNothing);
      expect(Get.find<FlowController>().isFlowListOutdated(), isTrue);
    });
  });

  testWidgets('关闭日程编辑不修改任务或触发重排', (tester) async {
    await tester.runAsync(() => initializeDateFormatting('zh_CN'));
    final task = _testTask(summary: '保留原日程')
      ..type = TaskType.fixed
      ..genUid();
    final page = CalendarPage();
    taskList.add(task);
    await runPageTest(tester, () async {
      await tester.pumpWidget(CupertinoApp(home: page));
      await tester.pump();
      await tapCard(tester, find.text(task.summary));
      await tester.tap(find.text('编辑'));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.text('编辑日程'), findsOneWidget);
      await tester.enterText(find.byType(CupertinoTextField).first, '放弃的内容');
      final db = Get.find<DatabaseHelper>(tag: 'db') as _FakeDb;
      final storedTime = db.storedTime;
      final cachedFlow = db.storedFlow;
      await tester.pump();
      await tester.tap(find.byIcon(CupertinoIcons.xmark).hitTestable());
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(task.summary, '保留原日程');
      expect(db.storedTime, storedTime);
      expect(db.storedFlow, same(cachedFlow));
      expect(find.text('编辑日程'), findsNothing);
    });
  });

  testWidgets('新建日程没有删除操作，取消不添加项目', (tester) async {
    await tester.runAsync(() => initializeDateFormatting('zh_CN'));
    await runPageTest(tester, () async {
      await tester.pumpWidget(CupertinoApp(home: CalendarPage()));
      await tester.pump();
      final semantics = tester.ensureSemantics();
      try {
        await tester.tap(find.bySemanticsLabel('添加日程或任务'));
        await pumpFor(tester, const Duration(milliseconds: 500));
        expect(find.text('新建日程'), findsOneWidget);
        expect(find.text('删除日程'), findsNothing);
        await tester.tap(find.bySemanticsLabel('关闭编辑'));
        await pumpFor(tester, const Duration(milliseconds: 500));
        expect(taskList, isEmpty);
      } finally {
        semantics.dispose();
      }
    });
  });

  testWidgets('两页课程卡都能查看详情，接下来保留课程倒计时', (tester) async {
    await tester.runAsync(() => initializeDateFormatting('zh_CN'));
    final now = DateTime.now();
    const location = '教学楼 101';
    final course = Period(
      summary: academicCourse,
      location: location,
      description: '',
      fromUid: academicCourseId,
      startTime: now,
      endTime: now.add(const Duration(minutes: 45)),
      type: PeriodType.classes,
    );
    Get.find<Rx<Scholar>>(tag: 'scholar').value = _ScholarWithPeriods([course])
      ..semesters = academicFixture().semesters;
    await runPageTest(tester, () async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final page in [FlowPage(), CalendarPage()]) {
        await tester.pumpWidget(CupertinoApp(
          key: ValueKey(page.runtimeType),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: page,
        ));
        await tester.pump();
        expect(find.text(location).hitTestable(), findsOneWidget);
        expect(
          find.textContaining('离结束还有'),
          page is FlowPage ? findsOneWidget : findsNothing,
        );
        await tester.tap(find.text(academicCourse).hitTestable());
        await pumpFor(tester, const Duration(milliseconds: 400));
        expect(find.byType(CourseDetailPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  testWidgets('空状态在新增任务后应当消失', (tester) async {
    await runPageTest(tester, () async {
      await pumpTaskPage(tester);
      expect(find.text('没有任务'), findsOneWidget);

      taskList.add(_testTask(summary: '删除功能'));
      await tester.pump();

      expect(find.text('删除功能'), findsOneWidget, reason: '新任务卡片应当出现');
      expect(find.text('没有任务'), findsNothing, reason: '有任务时不应再显示空状态');
    });
  });

  testWidgets('任务列表绘制到底部，最后一项可滚到悬浮栏上方', (tester) async {
    await runPageTest(tester, () async {
      taskList.addAll([
        for (var i = 0; i < 20; i++) _testTask(summary: '滚动测试任务 $i'),
      ]);
      await tester.pumpWidget(CupertinoApp(
        home: HomeScrollInsets(bottom: 88, child: TaskPage()),
      ));
      await tester.pump();

      final scrollView = find.byType(CustomScrollView);
      final viewportBottom = tester.getBottomRight(scrollView).dy;
      expect(viewportBottom,
          tester.view.physicalSize.height / tester.view.devicePixelRatio);
      final position =
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      final last = find.text('滚动测试任务 19');
      expect(last.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(last).dy, lessThan(viewportBottom - 88));
    });
  });

  testWidgets('滑动当天日程时月历位置保持固定', (tester) async {
    await tester.runAsync(() => initializeDateFormatting('zh_CN'));
    final now = DateTime.now();
    taskList.addAll([
      for (var i = 0; i < 16; i++)
        Task(
          type: TaskType.fixed,
          status: TaskStatus.running,
          startTime: DateTime(now.year, now.month, now.day, i),
          endTime: DateTime(now.year, now.month, now.day, i + 1),
          repeatEndsTime: now,
          summary: '当天日程测试 $i',
        ),
    ]);
    await runPageTest(tester, () async {
      await tester.pumpWidget(CupertinoApp(
        home: HomeScrollInsets(bottom: 88, child: CalendarPage()),
      ));
      await tester.pump();

      final calendar =
          find.byWidgetPredicate((widget) => widget is TableCalendar);
      final originalTop = tester.getTopLeft(calendar);
      expect(find.text('+13'), findsNothing);
      final calendarWidget = tester.widget<TableCalendar<Period>>(calendar);
      expect(calendarWidget.calendarBuilders.singleMarkerBuilder, isNotNull);
      expect(calendarWidget.eventLoader!(now), hasLength(16));
      final dayList = find.byType(CustomScrollView);
      expect(tester.getBottomRight(dayList).dy,
          tester.view.physicalSize.height / tester.view.devicePixelRatio);
      final listScrollable = find.descendant(
        of: dayList,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(listScrollable).position;

      await tester.drag(dayList, const Offset(0, -180));
      await tester.pump(const Duration(milliseconds: 500));
      expect(position.pixels, greaterThan(0));
      expect(tester.getTopLeft(calendar), originalTop);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('清空任务后应当重新出现空状态', (tester) async {
    await runPageTest(tester, () async {
      taskList.add(_testTask(summary: '删除功能'));
      await pumpTaskPage(tester);
      expect(find.text('没有任务'), findsNothing);

      await tester.drag(find.text('删除功能'), const Offset(-600, 0));
      await pumpFor(tester, const Duration(milliseconds: 700));

      expect(find.text('删除功能'), findsNothing);
      expect(find.text('没有任务'), findsOneWidget);
    });
  });

  testWidgets('从卡片进入编辑页点“删除任务”应当删除任务', (tester) async {
    await runPageTest(tester, () async {
      taskList.add(_testTask(summary: '删除功能'));
      await pumpTaskPage(tester);

      await tapCard(tester, find.text('删除功能'));
      expect(find.text('编辑任务'), findsOneWidget);

      await tapDeleteInEditPage(tester);

      expect(find.text('编辑任务'), findsNothing, reason: '编辑页应当已经返回上一页');
      expect(
        _aliveTasks(taskList),
        isEmpty,
        reason: '点“删除任务”后任务应当被标记为删除或从列表移除',
      );
    });
  });

  testWidgets('左滑删除仍然有效（与编辑页删除共用实现）', (tester) async {
    await runPageTest(tester, () async {
      taskList.add(_testTask(summary: '删除功能'));
      await pumpTaskPage(tester);

      await tester.drag(find.text('删除功能'), const Offset(-600, 0));
      await pumpFor(tester, const Duration(milliseconds: 700));

      expect(find.text('删除功能'), findsNothing);
      expect(_aliveTasks(taskList), isEmpty);
    });
  });

  testWidgets('窄屏输入和调整截止时间后，键盘打开时仍能保存草稿', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    final task = _testTask(summary: '原任务');
    const draft = '整理本学期高等数学和数字信号处理课程的期末复习资料';
    final newEnd = task.endTime.add(const Duration(days: 1));
    Task? result;
    await tester.pumpWidget(CupertinoApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.4),
        ),
        child: child!,
      ),
      home: Builder(builder: (context) {
        return CupertinoPageScaffold(
          child: CupertinoButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Task>(
                CupertinoPageRoute(builder: (_) => TaskEditPage(task)),
              );
            },
            child: const Text('打开编辑'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();

    final field = find.byType(CupertinoTextField).first;
    await tester.enterText(field, draft);
    await tester.tap(find.text('截止时间'));
    await tester.pumpAndSettle();
    final date = find.byType(CupertinoDatePicker);
    tester.widget<CupertinoDatePicker>(date).onDateTimeChanged(newEnd);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('截止时间'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<CupertinoDatePicker>(date).initialDateTime, task.endTime);
    tester.widget<CupertinoDatePicker>(date).onDateTimeChanged(newEnd);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoTextField>(field).controller!.text, draft);

    await tester.tap(field);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').hitTestable());
    await tester.pumpAndSettle();
    expect(result?.summary, draft);
    expect(result?.endTime, newEnd);
    expect(tester.takeException(), isNull);
  });

  testWidgets('对照组：编辑页点“删除任务”确实会返回 status=deleted 的任务', (tester) async {
    await runPageTest(tester, () async {
      final task = _testTask(summary: '删除功能');
      Task? popped;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoPageScaffold(
              child: CupertinoButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => TaskEditPage(task),
                    ),
                  );
                },
                child: const Text('打开编辑页'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开编辑页'));
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.text('编辑任务'), findsOneWidget);

      await tapDeleteInEditPage(tester);

      expect(popped?.status, TaskStatus.deleted);
    });
  });
}
