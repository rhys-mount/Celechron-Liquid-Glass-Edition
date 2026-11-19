import 'dart:math';

import 'package:celechron/utils/tuple.dart';
import 'package:celechron/model/session.dart';
import 'package:celechron/design/persistent_headers.dart';
import 'course_schedule_controller.dart';
import 'package:get/get.dart';
import 'package:celechron/design/semester_chips.dart';
import 'package:celechron/design/floating_filter_panel.dart';
import 'package:celechron/design/content_empty_state.dart';
import 'course_hours_cards.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'course_card.dart';
import 'package:flutter/cupertino.dart';

class CourseSchedulePage extends StatelessWidget {
  late final CourseScheduleController _courseScheduleController;

  CourseSchedulePage(String name, bool first, {super.key}) {
    bool initialHideCourseInfomation = false;
    try {
      initialHideCourseInfomation =
          Get.find<CourseScheduleController>().hideCourseInfomation.value;
    } catch (e) {
      // not initialized
    }
    Get.delete<CourseScheduleController>();
    _courseScheduleController = Get.put(CourseScheduleController(
      initialName: name,
      initialFirstOrSecondSemester: first,
      initialHideCourseInfomation: initialHideCourseInfomation,
    ));
  }

  Widget _courseHours() {
    final controller = _courseScheduleController;
    return RoundRectangleCard(
      animate: false,
      child: Obx(() => Hero(
            tag: 'courseSchedule',
            child: CourseHoursCards(
              semester: controller.semester,
              selectedFirstHalf: controller.firstOrSecondSemester.value,
              onSelect: (first) =>
                  controller.firstOrSecondSemester.value = first,
            ),
          )),
    );
  }

  Widget _courseSchedule(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final timeLabelHeight =
        (textScaler.scale(10) + textScaler.scale(14)) * 1.4 + 2;
    const List<String> courseStartTime = [
      "08:00",
      "08:50",
      "10:00",
      "10:50",
      "11:40",
      "13:25",
      "14:15",
      "15:05",
      "16:15",
      "17:05",
      "18:50",
      "19:40",
      "20:30"
    ];
    return RoundRectangleCard(
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(flex: 1),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '一',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 14,
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '二',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 14,
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '三',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 14,
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '四',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 14,
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '五',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 14,
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '六',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 14,
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '日',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 14,
                            ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: max(560.0, timeLabelHeight * 13),
            child: Obx(
              () {
                var sessionsByDayOfWeek =
                    _courseScheduleController.sessionsByDayOfWeek;
                return Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          for (var i = 1; i <= 13; i++)
                            Expanded(
                              child: Center(
                                child: Column(
                                  // mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: Text(
                                        courseStartTime[i - 1],
                                        style: CupertinoTheme.of(context)
                                            .textTheme
                                            .textStyle
                                            .copyWith(
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      i.toString(),
                                      style: CupertinoTheme.of(context)
                                          .textTheme
                                          .textStyle
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (var i = 1; i <= 6; i++)
                      Expanded(
                        flex: 2,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              Column(
                                children: [
                                  for (var j = 1; j <= 12; j++)
                                    Expanded(
                                      child: Container(
                                          // decoration: BoxDecoration(
                                          //   border: Border(
                                          //     bottom: BorderSide(
                                          //         color: CupertinoDynamicColor
                                          //             .resolve(
                                          //                 CupertinoColors
                                          //                     .systemGrey4,
                                          //                 context)),
                                          //     right: BorderSide(
                                          //       color:
                                          //           CupertinoDynamicColor.resolve(
                                          //               CupertinoColors
                                          //                   .systemGrey4,
                                          //               context),
                                          //     ),
                                          //   ),
                                          // ),
                                          ),
                                    ),
                                  Expanded(
                                    child: Container(
                                        // decoration: BoxDecoration(
                                        //   border: Border(
                                        //     right: BorderSide(
                                        //       color:
                                        //           CupertinoDynamicColor.resolve(
                                        //               CupertinoColors.systemGrey4,
                                        //               context),
                                        //     ),
                                        //   ),
                                        // ),
                                        ),
                                  ),
                                ],
                              ),
                              ..._buildCourseScheduleByDayOfWeek(
                                  sessionsByDayOfWeek, i, constraints)
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          children: [
                            Column(
                              children: [
                                for (var j = 1; j <= 12; j++)
                                  Expanded(
                                    child: Container(
                                        // decoration: BoxDecoration(
                                        //   border: Border(
                                        //     bottom: BorderSide(
                                        //       color:
                                        //           CupertinoDynamicColor.resolve(
                                        //               CupertinoColors.systemGrey4,
                                        //               context),
                                        //     ),
                                        //   ),
                                        // ),
                                        ),
                                  ),
                                Expanded(child: Container())
                              ],
                            ),
                            ..._buildCourseScheduleByDayOfWeek(
                                sessionsByDayOfWeek, 7, constraints)
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCourseScheduleByDayOfWeek(
      List<List<Session>> sessionsByDayOfWeek,
      int day,
      BoxConstraints constraints) {
    List<Tuple<int, int>> period = [];
    for (var i = 1; i <= 13; i++) {
      period.add(Tuple(i, i));
    }
    for (var s in sessionsByDayOfWeek[day]) {
      int sl = s.time.first, sr = s.time.last;
      int xl = sl, xr = sr;
      for (var i in period) {
        if (!(i.item2 < sl || sr < i.item1)) {
          xl = min(xl, i.item1);
          xr = max(xr, i.item2);
        }
      }
      period.removeWhere((x) => xl <= x.item1 && x.item2 <= xr);
      period.add(Tuple(xl, xr));
    }
    List<List<Session>> sessionList = [];
    for (var _ in period) {
      sessionList.add([]);
    }
    for (var s in sessionsByDayOfWeek[day]) {
      int sl = s.time.first, sr = s.time.last;
      for (int i = 0; i < period.length; i++) {
        if (!(period[i].item2 < sl || sr < period[i].item1)) {
          bool added = false;
          for (var t in sessionList[i]) {
            if (t.id == s.id) {
              added = true;
              Set<int> timeSet = Set.from(t.time);
              timeSet.addAll(s.time);
              t.time = List.from(timeSet);
              t.time.sort();
              break;
            }
          }
          if (!added) {
            sessionList[i].add(Session.fromJson(s.toJson()));
          }
        }
      }
    }

    List<Widget> cardList = [];
    for (int i = 0; i < period.length; i++) {
      if (sessionList[i].isNotEmpty) {
        cardList.add(
          Positioned.fromRelativeRect(
            rect: RelativeRect.fromLTRB(
              0,
              (period[i].item1 - 1) * constraints.maxHeight / 13,
              0,
              (13 - period[i].item2) * constraints.maxHeight / 13,
            ),
            child: Obx(
              () => SessionCard(
                sessionList: sessionList[i],
                compact: true,
                hideInfomation:
                    _courseScheduleController.hideCourseInfomation.value,
              ),
            ),
          ),
        );
      }
    }

    return cardList;

    // return sessionsByDayOfWeek[day]
    //     .map((e) => Positioned.fromRelativeRect(
    //           rect: RelativeRect.fromLTRB(
    //             0,
    //             (e.time.first - 1) * constraints.maxHeight / 13,
    //             0,
    //             (13 - e.time.last) * constraints.maxHeight / 13,
    //           ),
    //           child: SessionCard(sessionList: [e]),
    //         ))
    //     .toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGroupedBackground, context),
      child: CustomScrollView(
        slivers: [
          const CelechronSliverTextHeader(subtitle: '课表'),
          SliverFloatingFilterPanel(
            child: Obx(() => SemesterChips(
                  names: [
                    for (final semester in _courseScheduleController.semesters)
                      semester.name
                  ],
                  selectedIndex: _courseScheduleController.selectedIndex,
                  onSelected: (index) =>
                      _courseScheduleController.semesterIndex.value = index,
                )),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                if (_courseScheduleController.semesters.isEmpty) {
                  return const ContentEmptyState(
                    icon: CupertinoIcons.calendar,
                    title: '暂无课表。请返回学业页下拉刷新。',
                  );
                }
                return Column(
                  children: [
                    _courseHours(),
                    const SizedBox(height: 8),
                    _courseSchedule(context),
                    const SizedBox(height: 20),
                    Obx(
                      () => CupertinoListSection.insetGrouped(
                        margin: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 0.0, 10.0),
                        additionalDividerMargin: 2,
                        children: <CupertinoListTile>[
                          CupertinoListTile(
                              title: const Text('隐藏课程信息'),
                              trailing: CupertinoSwitch(
                                value: _courseScheduleController
                                    .hideCourseInfomation.value,
                                onChanged: (value) async {
                                  _courseScheduleController
                                      .hideCourseInfomation.value = value;
                                },
                              )),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
