import 'package:celechron/design/action_dialogs.dart';
import 'package:celechron/design/content_empty_state.dart';
import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/design/event_list_card.dart';
import 'package:celechron/design/liquid_glass/navigation_action.dart';
import 'package:celechron/design/liquid_glass/home_scroll_insets.dart';
import 'package:celechron/utils/time_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:celechron/database/database_helper.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/utils/utils.dart';

import 'package:celechron/design/sub_title.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'flow_controller.dart';

class FlowPage extends StatelessWidget {
  FlowPage({super.key});

  final _flowController = Get.put(FlowController());
  final db = Get.find<DatabaseHelper>(tag: 'db');

  Widget _buildProgress(Period period, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Container(
            height: 8,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: CupertinoColors.separator.resolveFrom(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Obx(() {
            final elapsed =
                _flowController.timeNow.value.difference(period.startTime);
            final duration = period.endTime.difference(period.startTime);
            final progress = duration <= Duration.zero
                ? 0.0
                : (elapsed.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);
            return Container(
              height: 8,
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(color, context),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _periodColor(Period period) => switch (period.type) {
        PeriodType.classes => TimeColors.colorFromHour(period.startTime.hour),
        PeriodType.user ||
        PeriodType.flow =>
          UidColors.colorFromUid(period.fromUid),
        PeriodType.test => CupertinoColors.systemPink,
        _ => CupertinoColors.systemTeal,
      };

  Widget _buildEventCard(
    BuildContext context,
    Period period,
    String? title, {
    bool showProgress = false,
  }) {
    return Column(
      children: [
        if (title != null) SubtitleRow(subtitle: title),
        EventListCard(
          period: period,
          markerColor: _periodColor(period),
          timeLabel: period.friendlyTimeTodayBased,
          onTap: period.type == PeriodType.classes
              ? () => CourseDetailPage.open(context, period.fromUid)
              : null,
          footer: showProgress
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Obx(() {
                      final now = _flowController.timeNow.value;
                      final started = period.startTime.isBefore(now);
                      final remaining =
                          (started ? period.endTime : period.startTime)
                              .difference(now);
                      return Text(
                        '${started ? '离结束还有' : '开始还有'} ${TimeHelper.toHMS(remaining)}',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                          fontSize: 14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    }),
                    _buildProgress(period, _periodColor(period)),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  Future<void> newFlowList(BuildContext context) async {
    var startTime = DateTime.now()
        .add(const Duration(seconds: 90))
        .copyWith(second: 0, millisecond: 0, microsecond: 0);
    String? error;
    final restMinutes = await showCupertinoDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('开始规划'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                onPressed: () async {
                  final updated = await showDatePickerSheet(
                    context,
                    title: '开始时间',
                    initialValue: startTime,
                  );
                  if (!context.mounted || updated == null) return;
                  setState(() {
                    startTime = updated;
                    error = null;
                  });
                },
                child: Text('开始时间\n${TimeHelper.chineseDateTime(startTime)}',
                    textAlign: TextAlign.center),
              ),
              Text('工作 ${durationToString(db.getWorkTime())} · '
                  '休息 ${durationToString(db.getRestTime())}'),
              if (error case final message?)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(liveRegion: true, child: Text(message)),
                ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                if (!startTime.isAfter(DateTime.now())) {
                  setState(() => error = '开始时间必须晚于现在，请调整时间。');
                  return;
                }
                final result = _flowController.generateNewFlowList(startTime);
                if (result < 0) {
                  setState(() => error = '时间不足。请缩短任务的预期用时，或检查是否有任务早于规划开始时间截止。');
                  return;
                }
                Navigator.pop(context, result);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted ||
        restMinutes == null ||
        restMinutes == db.getRestTime().inMinutes) {
      return;
    }
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('休息时间已压缩'),
        content: Text(
            '每段休息缩短为 ${durationToString(Duration(minutes: restMinutes))}。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          // Allow the list to shrink wrap around the top and bottom bars.
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('接下来'),
              stretch: true,
              border: null,
              trailing: NavigationAction(
                icon: CupertinoIcons.arrow_clockwise,
                label: '重新规划',
                onPressed: () async {
                  await newFlowList(context);
                },
              ),
            ),
            Obx(
              () {
                if (_flowController.flowList.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: ContentEmptyState(
                      icon: CupertinoIcons.clock,
                      title: '今日无事可做',
                    ),
                  );
                }

                int? lastWaitingFlowIndex;
                for (int i = 0; i < _flowController.flowList.length; i++) {
                  if (!_flowController.flowList[i].hasStarted) {
                    lastWaitingFlowIndex = i;
                    break;
                  }
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      var container = Container(
                        padding: EdgeInsets.only(
                            top: index == 0 ? 0 : 5,
                            bottom: 5,
                            left: 16,
                            right: 16),
                        child: _buildEventCard(
                          context,
                          _flowController.flowList[index],
                          index == 0
                              ? (_flowController.flowList[index].hasStarted
                                  ? '正在进行'
                                  : '即将开始')
                              : (index == lastWaitingFlowIndex
                                  ? '之后的安排'
                                  : null),
                          showProgress: index == 0 ||
                              _flowController.flowList[index].hasStarted,
                        ),
                      );

                      return container;
                    },
                    childCount: _flowController.flowList.length,
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 20 + HomeScrollInsets.bottomOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
