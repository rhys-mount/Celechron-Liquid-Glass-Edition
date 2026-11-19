import 'dart:math' as math;

import 'package:celechron/design/custom_decoration.dart';
import 'package:celechron/design/event_list_card.dart';
import 'package:celechron/design/liquid_glass/home_scroll_insets.dart';
import 'package:celechron/design/liquid_glass/navigation_action.dart';
import 'package:celechron/design/sub_title.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/page/task/task_controller.dart';
import 'package:celechron/page/task/task_edit_page.dart';
import 'package:celechron/page/flow/flow_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/utils/utils.dart';

import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'package:celechron/page/calendar/schedule_view.dart';
import 'calendar_controller.dart';

class CalendarPage extends StatelessWidget {
  CalendarPage({super.key});
  final _calendarController = Get.put(CalendarController());
  final _taskController = Get.put(TaskController());
  final _flowController = Get.put(FlowController());
  final deadlineList = Get.find<RxList<Task>>(tag: 'taskList');

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final isCalendar = _calendarController.viewMode.value ==
                  CalendarViewMode.calendar;
              final focused = _calendarController.focusedDay.value;
              void toggleView() => _calendarController.toggleViewMode();
              return SubtitleRow(
                wrapSubtitle: true,
                subtitle: isCalendar
                    ? '${focused.year}\u00a0年 ${focused.month}\u00a0月'
                    : _calendarController.getCurrentSemesterDisplayName(),
                right: isCalendar
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            onPressed: () {
                              final today = DateTime.now();
                              _calendarController.focusedDay.value = today;
                              _calendarController.selectedDay.value = today;
                            },
                            child: const Text('今天',
                                style: TextStyle(fontSize: 15)),
                          ),
                          NavigationActionGroup(actions: [
                            (
                              icon: CupertinoIcons.add,
                              label: '添加日程或任务',
                              onPressed: () async {
                                final day =
                                    _calendarController.selectedDay.value;
                                final now = DateTime.now();
                                await newDeadline(
                                  context,
                                  time: DateTime(day.year, day.month, day.day,
                                      now.hour, now.minute),
                                );
                              },
                            ),
                            (
                              icon: CupertinoIcons.calendar,
                              label: '查看周课表',
                              onPressed: toggleView,
                            ),
                          ]),
                        ],
                      )
                    : NavigationAction(
                        icon: CupertinoIcons.list_bullet,
                        label: '返回月历',
                        onPressed: toggleView,
                      ),
                padHorizontal: 16,
                padVertical: 8,
              );
            }),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Obx(() {
                  if (_calendarController.viewMode.value ==
                      CalendarViewMode.schedule) {
                    return ScheduleView(controller: _calendarController);
                  }
                  final useColumns =
                      defaultTargetPlatform == TargetPlatform.android &&
                          MediaQuery.orientationOf(context) ==
                              Orientation.landscape &&
                          constraints.maxWidth >= 760 &&
                          constraints.maxHeight >= 420;
                  final format = _calendarController.calendarFormat.value;
                  final rows = format == CalendarFormat.week ? 1 : 6;
                  const weekdayHeight = 20.0;
                  const calendarBottom = 5.0;
                  const listGap = 8.0;
                  final listSpace =
                      math.min(184.0, constraints.maxHeight * .42);
                  final rowHeight = useColumns
                      ? 48.0
                      : ((constraints.maxHeight -
                                  listSpace -
                                  weekdayHeight -
                                  calendarBottom -
                                  listGap) /
                              rows)
                          .clamp(0.0, constraints.maxHeight < 680 ? 42.0 : 48.0)
                          .toDouble();
                  final calendar = Padding(
                    padding: const EdgeInsets.only(
                        bottom: calendarBottom, left: 12, right: 12),
                    child: TableCalendar(
                      locale: 'zh_CN',
                      firstDay: DateTime.utc(2022, 9, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      rowHeight: rowHeight,
                      daysOfWeekHeight: weekdayHeight,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      daysOfWeekStyle: DaysOfWeekStyle(
                        dowTextFormatter: (date, locale) => <String>[
                          '',
                          '一',
                          '二',
                          '三',
                          '四',
                          '五',
                          '六',
                          '日'
                        ][date.weekday],
                      ),
                      availableGestures: AvailableGestures.all,
                      availableCalendarFormats: const {
                        CalendarFormat.month: '显示整月',
                        CalendarFormat.week: '显示一周',
                      },
                      headerVisible: false,
                      focusedDay: _calendarController.focusedDay.value,
                      selectedDayPredicate: (day) {
                        return isSameDay(
                            _calendarController.selectedDay.value, day);
                      },
                      calendarFormat: format,
                      onPageChanged: (focusedDay) {
                        _calendarController.focusedDay.value = focusedDay;
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        _calendarController.focusedDay.value = focusedDay;
                        _calendarController.selectedDay.value = selectedDay;
                        _calendarController.focusedDay.refresh();
                      },
                      onFormatChanged: (format) {
                        _calendarController.calendarFormat.value = format;
                      },
                      eventLoader: (day) {
                        return _calendarController.getEventsForDay(day);
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: CupertinoDynamicColor.resolve(
                            CupertinoTheme.of(context).primaryColor,
                            context,
                          ).withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                        selectedTextStyle:
                            CupertinoTheme.of(context).textTheme.textStyle,
                        todayDecoration: BoxDecoration(
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.inactiveGray
                                  .withValues(alpha: 0.24),
                              context),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle:
                            CupertinoTheme.of(context).textTheme.textStyle,
                        defaultTextStyle:
                            CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                      calendarBuilders: const CalendarBuilders<Period>(
                        singleMarkerBuilder: singleMarkerBuilder,
                      ),
                    ),
                  );
                  final daySlivers = [
                    SliverToBoxAdapter(
                      child: Obx(
                        () => SubSubtitleRow(
                            padHorizontal: 24,
                            subtitle: _calendarController.dayDescription(
                                _calendarController.selectedDay.value
                                    .copyWith(isUtc: false)),
                            right: _calendarController
                                    .scholar.value.specialDates
                                    .containsKey(_calendarController
                                        .selectedDay.value
                                        .copyWith(isUtc: false))
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: CustomCupertinoDynamicColors
                                                .okGreen.darkColor,
                                            width: 1),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(
                                      _calendarController
                                              .scholar.value.specialDates[
                                          _calendarController.selectedDay.value
                                              .copyWith(isUtc: false)]!,
                                      style: TextStyle(
                                          color: CustomCupertinoDynamicColors
                                              .okGreen.darkColor,
                                          fontSize: 12),
                                    ),
                                  )
                                : null),
                      ),
                    ),
                    Obx(() {
                      final events = _calendarController.getEventsForDay(
                          _calendarController.selectedDay.value);
                      return SliverList.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 16),
                          child: createCard(context, events[index]),
                        ),
                      );
                    }),
                    SliverToBoxAdapter(
                      child:
                          SizedBox(height: HomeScrollInsets.bottomOf(context)),
                    ),
                  ];
                  final dayList = CustomScrollView(
                    primary: false,
                    slivers: daySlivers,
                  );
                  if (useColumns) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            primary: false,
                            child: calendar,
                          ),
                        ),
                        Expanded(child: dayList),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      calendar,
                      const SizedBox(height: listGap),
                      Expanded(child: dayList),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> newDeadline(context, {required DateTime time}) async {
    Task? deadline = Task(
      endTime: time,
      startTime: time,
      repeatEndsTime: time,
    );
    deadline.reset();
    deadline.startTime = time.copyWith();
    deadline.endTime = time.copyWith();
    deadline.repeatEndsTime = time.copyWith();
    deadline.type = TaskType.fixed;
    deadline.status = TaskStatus.running;
    Task? res = await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return TaskEditPage(deadline, isNew: true);
      },
    );
    if (res != null &&
        res.checkTimeValid() &&
        res.status != TaskStatus.deleted) {
      _taskController.taskList.add(res);
      _taskController.updateDeadlineListTime();
      _taskController.updateDeadlineList();
      _taskController.taskList.refresh();
    }
  }

  Future<void> showCardDialog(BuildContext context, Task deadline) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(deadline.summary),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (deadline.repeatType != TaskRepeatType.norepeat) ...[
                  const Text(
                    '重复日程。编辑将应用于整组日程。',
                  ),
                ],
                Text(
                  '开始于 ${toStringHumanReadable(deadline.startTime)}',
                ),
                Text(
                  '结束于 ${toStringHumanReadable(deadline.endTime)}',
                ),
                if (deadline.location.isNotEmpty) ...[
                  Text(
                    '地点：${deadline.location}',
                  ),
                ],
                if (deadline.description.isNotEmpty) ...[
                  Text(
                    '说明：${deadline.description}',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
            if (deadline.type == TaskType.fixed)
              CupertinoDialogAction(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final res = await TaskEditPage.open(context, deadline);
                  if (res == null) return;
                  final needsReplan = deadline.differentForFlow(res) ||
                      deadline.startTime != res.startTime ||
                      deadline.summary != res.summary ||
                      deadline.location != res.location ||
                      deadline.description != res.description;
                  deadline.copy(res);
                  _taskController.updateDeadlineList();
                  if (needsReplan) {
                    _taskController.updateDeadlineListTime();
                    _flowController.removeFlowInFlowList();
                    final now = DateTime.now();
                    _flowController.generateNewFlowList(DateTime(
                        now.year, now.month, now.day, now.hour, now.minute));
                  }
                  _taskController.taskList.refresh();
                  _taskController.saveDeadlineListToDb();
                },
                child: const Text('编辑'),
              ),
            if (deadline.type == TaskType.fixedlegacy)
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  Navigator.of(context).pop();
                  deadline.status = TaskStatus.deleted;
                  _taskController.updateDeadlineList();
                  _taskController.taskList.refresh();
                },
                child: const Text('删除'),
              ),
          ],
        );
      },
    );
  }

  Widget createCard(context, Period period) {
    return EventListCard(
      period: period,
      timeLabel: period.friendlyTimeStartDayBased,
      onTap:
          (period.type == PeriodType.classes || period.type == PeriodType.test)
              ? () => CourseDetailPage.open(context, period.fromUid)
              : (period.type == PeriodType.user
                  ? (() async {
                      Task? deadline;
                      for (var x in deadlineList) {
                        if (x.uid == period.fromUid) {
                          deadline = x;
                          break;
                        }
                      }
                      if (deadline != null) {
                        showCardDialog(context, deadline);
                      }
                    })
                  : null),
    );
  }

  static Widget singleMarkerBuilder(
      BuildContext context, DateTime day, Period event) {
    if (event.type == PeriodType.virtual) return const SizedBox.shrink();
    Color color = CupertinoColors.systemPink;
    if (event.type == PeriodType.classes) {
      color = TimeColors.colorFromHour(event.startTime.hour);
    } else if (event.type == PeriodType.user) {
      color = UidColors.colorFromUid(event.fromFromUid ?? event.fromUid);
    }

    double size = 4.5;

    if (event.type == PeriodType.test) {
      size = 6;
    }

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 0.3),
      decoration: customDecoration(
        color: color,
        shape: periodTypeShape[event.type]!,
      ),
    );
  }
}
