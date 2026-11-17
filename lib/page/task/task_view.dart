import 'package:celechron/design/content_empty_state.dart';
import 'package:celechron/design/card_detail_line.dart';
import 'package:celechron/design/custom_decoration.dart';
import 'package:celechron/design/liquid_glass/navigation_action.dart';
import 'package:celechron/design/liquid_glass/home_scroll_insets.dart';
import 'package:celechron/page/flow/flow_controller.dart';
import 'package:celechron/page/task/task_controller.dart';
import 'package:celechron/utils/time_helper.dart';
import 'package:celechron/utils/utils.dart';
import 'package:celechron/design/sub_title.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/design/custom_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/model/period.dart';
import 'task_edit_page.dart';
import 'dart:async';
import 'package:get/get.dart';

class TaskPage extends StatelessWidget {
  TaskPage({super.key});

  final _taskController = Get.put(TaskController());
  final _flowController = Get.put(FlowController());

  String deadlineProgress(Task deadline) {
    final progress = deadline.getProgress();
    final percent = progress.isFinite ? (progress * 100).toInt() : 0;
    return '$percent% 已完成 · 预期 ${durationToString(deadline.timeNeeded)} · 剩余 ${durationToString(deadline.timeNeeded <= deadline.timeSpent ? Duration.zero : (deadline.timeNeeded - deadline.timeSpent))}';
  }

  Future<void> showCardDialog(BuildContext context, Task deadline) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            '${deadline.summary}：${deadline.type == TaskType.deadline ? deadlineStatusName[deadline.status]! : deadline.type == TaskType.fixed ? deadlineTypeName[TaskType.fixed] : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (deadline.type == TaskType.fixed) ...[
                    Text(
                      '开始于 ${toStringHumanReadable(deadline.startTime)}',
                    ),
                    Text(
                      '结束于 ${toStringHumanReadable(deadline.endTime)}',
                    ),
                  ],
                  if (deadline.type == TaskType.deadline) ...[
                    Text(
                      '截止于 ${toStringHumanReadable(deadline.endTime)}${deadline.endTime.isBefore(DateTime.now()) ? ' - 已过期' : ''}',
                    ),
                    Text(
                      deadlineProgress(deadline),
                    ),
                  ],
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
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
            if (deadline.type == TaskType.deadline &&
                deadline.timeSpent < deadline.timeNeeded)
              CupertinoDialogAction(
                onPressed: () {
                  if (deadline.status != TaskStatus.completed) {
                    deadline.status = TaskStatus.completed;
                  } else {
                    deadline.forceRefreshStatus();
                  }
                  _taskController.updateDeadlineListTime();
                  _taskController.taskList.refresh();
                  Navigator.of(context).pop();
                },
                child: Text(
                    '标记为${deadline.status == TaskStatus.completed ? '未' : ''}完成'),
              ),
            if (deadline.type == TaskType.deadline &&
                (deadline.status == TaskStatus.running ||
                    deadline.status == TaskStatus.suspended))
              CupertinoDialogAction(
                onPressed: () {
                  if (deadline.status == TaskStatus.running) {
                    deadline.status = TaskStatus.suspended;
                  } else {
                    deadline.status = TaskStatus.running;
                  }
                  _taskController.updateDeadlineListTime();
                  _taskController.taskList.refresh();
                  Navigator.of(context).pop();
                },
                child:
                    Text(deadline.status == TaskStatus.running ? '暂停' : '继续'),
              ),
            if (deadline.type == TaskType.deadline ||
                deadline.type == TaskType.fixed)
              CupertinoDialogAction(
                onPressed: () async {
                  Navigator.of(context).pop();
                  Task res = await showCupertinoModalPopup(
                        context: context,
                        builder: (BuildContext context) {
                          return TaskEditPage(deadline);
                        },
                      ) ??
                      deadline;
                  bool needUpdate = deadline.differentForFlow(res);
                  deadline.copy(res);
                  _taskController.updateDeadlineList();
                  if (needUpdate) {
                    _taskController.updateDeadlineListTime();
                  }
                  _taskController.taskList.refresh();
                  // 仅改 summary 等字段时 updateDeadlineList 检测不到变化，需显式落盘
                  _taskController.saveDeadlineListToDb();
                },
                child: const Text('编辑'),
              ),
            if (deadline.type == TaskType.fixedlegacy)
              CupertinoDialogAction(
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

  Future<void> newDeadline(context) async {
    DateTime time = DateTime.now();
    Task? deadline = Task(
      endTime: time,
      startTime: time,
      repeatEndsTime: time,
    );
    deadline.reset();
    Task? res = await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return TaskEditPage(deadline);
      },
    );
    if (res != null && res.status != TaskStatus.deleted) {
      _taskController.taskList.add(res);
      _taskController.updateDeadlineList();
      _taskController.updateDeadlineListTime();
      // 重新规划
      _flowController.removeFlowInFlowList();
      DateTime now = DateTime.now();
      DateTime startsAt =
          DateTime(now.year, now.month, now.day, now.hour, now.minute);
      _flowController.generateNewFlowList(startsAt);
      _taskController.taskList.refresh();
    }
  }

  /// 删除任务：标记状态、落盘并重排规划。
  /// 左滑删除与编辑页里的“删除任务”共用这一份实现，避免两条路径行为分叉。
  void removeTask(Task deadline) {
    deadline.status = TaskStatus.deleted;
    _taskController.updateDeadlineList();
    _taskController.updateDeadlineListTime();
    // 重新规划
    _flowController.removeFlowInFlowList();
    DateTime now = DateTime.now();
    DateTime startsAt =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _flowController.generateNewFlowList(startsAt);
    _taskController.taskList.refresh();
  }

  Widget createCard(context, Task deadline, Color color, String? title) {
    return Column(
      children: [
        title == null
            ? const SizedBox(height: 0)
            : SubtitleRow(subtitle: title),
        Dismissible(
          key: Key(deadline.uid),
          direction: deadline.type == TaskType.deadline
              ? DismissDirection.horizontal
              : DismissDirection.endToStart,
          movementDuration: const Duration(milliseconds: 300),
          resizeDuration: const Duration(milliseconds: 300),
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.25,
            DismissDirection.endToStart: 0.25,
          },
          crossAxisEndOffset: 0.0,
          background: deadline.type == TaskType.deadline
              ? Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: deadline.status == TaskStatus.completed
                        ? CupertinoColors.systemOrange
                        : CupertinoColors.systemGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      deadline.status == TaskStatus.completed
                          ? CupertinoIcons.arrow_counterclockwise
                          : CupertinoIcons.check_mark_circled_solid,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                )
              : null,
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // 向右滑（从左到右）：完成 - 不真正 dismiss，只更新状态
              if (deadline.type == TaskType.deadline) {
                if (deadline.status == TaskStatus.completed) {
                  // 如果已完成，恢复为未完成状态，并重置计时
                  deadline.timeSpent = const Duration(minutes: 0);
                  deadline.forceRefreshStatus();
                } else {
                  // 标记为完成，完成度设为100%
                  deadline.timeSpent = deadline.timeNeeded;
                  deadline.status = TaskStatus.completed;
                }
                _taskController.updateDeadlineList();
                _taskController.updateDeadlineListTime();
                // 重新规划
                _flowController.removeFlowInFlowList();
                DateTime now = DateTime.now();
                DateTime startsAt = DateTime(
                    now.year, now.month, now.day, now.hour, now.minute);
                _flowController.generateNewFlowList(startsAt);
                _taskController.taskList.refresh();
              }
              return false; // 阻止真正的 dismiss
            } else if (direction == DismissDirection.endToStart) {
              // 向左滑（从右到左）：删除 - 允许 dismiss
              return true;
            }
            return false;
          },
          onDismissed: (direction) {
            // 只有删除操作会真正 dismiss
            if (direction == DismissDirection.endToStart) {
              // 向左滑（从右到左）：删除
              removeTask(deadline);
            }
          },
          child: RoundRectangleCard.content(
            onTap: () async {
              // 直接导航到编辑页面
              Task? res = await Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(
                  builder: (context) => TaskEditPage(deadline),
                ),
              );
              if (res == null) return;
              if (res.status == TaskStatus.deleted) {
                // 编辑页的“删除任务”会把状态置为 deleted 后返回
                removeTask(deadline);
                return;
              }
              deadline.copy(res);
              _taskController.updateDeadlineList();
              _taskController.updateDeadlineListTime();
              // 重新规划
              _flowController.removeFlowInFlowList();
              DateTime now = DateTime.now();
              DateTime startsAt =
                  DateTime(now.year, now.month, now.day, now.hour, now.minute);
              _flowController.generateNewFlowList(startsAt);
              _taskController.taskList.refresh();
            },
            child: _buildTaskCardContent(context, deadline, color),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCardContent(
    BuildContext context,
    Task task,
    Color accent,
  ) {
    final deadline = task.type == TaskType.deadline;
    final now = DateTime.now();
    final statusColor = switch (task.status) {
      TaskStatus.completed => CupertinoColors.systemGreen,
      TaskStatus.failed => CupertinoColors.systemRed,
      TaskStatus.suspended => CupertinoColors.systemOrange,
      _ => CupertinoColors.secondaryLabel,
    }
        .resolveFrom(context);
    final startLabel =
        TimeHelper.compactDateTime(task.startTime, relativeTo: now);
    final endLabel = TimeHelper.compactDateTime(task.endTime, relativeTo: now);
    final sameDay =
        dateOnly(task.startTime.toLocal()) == dateOnly(task.endTime.toLocal());
    final endTime = sameDay ? endLabel.split(' ').last : endLabel;
    final time = deadline
        ? '截止 $endLabel${task.endTime.isBefore(now) ? ' · 已过期' : ''}'
        : '$startLabel – $endTime';
    Widget statusChip(String status) => DecoratedBox(
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Text(status,
                style: TextStyle(fontSize: 12, color: statusColor)),
          ),
        );
    Widget progressBar() {
      final progress = switch (task.status) {
        TaskStatus.completed when deadline => 1.0,
        TaskStatus.failed when deadline => 0.0,
        _ => task.getProgress(),
      };
      return LinearProgressIndicator(
        value: progress.isFinite ? progress : 0,
        minHeight: 4,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        backgroundColor:
            CupertinoColors.tertiarySystemFill.resolveFrom(context),
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SizedBox.square(
                dimension: 11,
                child: DecoratedBox(
                  decoration: customDecoration(
                    color: accent,
                    shape: periodTypeShape[PeriodType.user]!,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                task.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            if (deadline)
              statusChip(deadlineStatusName[task.status]!)
            else
              Obx(() {
                final time = _flowController.timeNow.value;
                return statusChip(time.isBefore(task.startTime)
                    ? '未开始'
                    : time.isBefore(task.endTime)
                        ? '进行中'
                        : '已结束');
              }),
          ],
        ),
        CardDetailLine(CupertinoIcons.clock, time, emphasis: true),
        if (task.location.isNotEmpty)
          CardDetailLine(CupertinoIcons.location, task.location),
        if (deadline)
          CardDetailLine(CupertinoIcons.timer, deadlineProgress(task)),
        if (!deadline || task.status == TaskStatus.running)
          Obx(() {
            final _ = _flowController.timeNow.value;
            return progressBar();
          })
        else if (task.status == TaskStatus.suspended ||
            task.status == TaskStatus.completed ||
            task.status == TaskStatus.failed)
          progressBar(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('任务'),
              border: null,
              stretch: true,
              trailing: NavigationActionGroup(
                actions: [
                  (
                    icon: CupertinoIcons.add,
                    label: '添加任务',
                    onPressed: () async {
                      await newDeadline(context);
                      _taskController.updateDeadlineList();
                      _taskController.taskList.refresh();
                    },
                  ),
                  (
                    icon: CupertinoIcons.ellipsis,
                    label: '更多任务操作',
                    onPressed: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (BuildContext context) => CupertinoActionSheet(
                          actions: <Widget>[
                            CupertinoActionSheetAction(
                              child: const Text('删除已完成任务'),
                              onPressed: () async {
                                _taskController
                                    .removeCompletedDeadline(context);
                                _taskController.updateDeadlineList();
                                _taskController.taskList.refresh();
                                Navigator.of(context).pop();
                              },
                            ),
                            CupertinoActionSheetAction(
                              child: const Text('删除已过期任务'),
                              onPressed: () async {
                                _taskController.removeFailedDeadline(context);
                                _taskController.updateDeadlineList();
                                _taskController.taskList.refresh();
                                Navigator.of(context).pop();
                              },
                            ),
                            CupertinoActionSheetAction(
                              child: const Text('暂停所有任务'),
                              onPressed: () {
                                if (_taskController
                                        .suspendAllDeadline(context) >
                                    0) {
                                  _flowController.removeFlowInFlowList();
                                  _taskController.updateDeadlineListTime();
                                  _taskController.taskList.refresh();
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                            CupertinoActionSheetAction(
                              child: const Text('继续所有任务'),
                              onPressed: () {
                                if (_taskController
                                        .continueAllDeadline(context) >
                                    0) {
                                  _flowController.removeFlowInFlowList();
                                  _taskController.updateDeadlineListTime();
                                  _taskController.taskList.refresh();
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            isDefaultAction: true,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('取消'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // 空状态要随任务列表变化，必须放在 Obx 里：本页是常驻页面
            // （_pages 保存稳定 widget 实例 + KeepAlive），build 不会再跑，
            // 非响应式判断会让“没有任务”在列表变非空后残留在列表上方。
            Obx(() {
              final bool isEmpty = _taskController.todoDeadlineList.isEmpty &&
                  _taskController.doneDeadlineList.isEmpty &&
                  _taskController.fixedDeadlineList.isEmpty;
              if (!isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox());
              }
              return const SliverToBoxAdapter(
                child: ContentEmptyState(
                  icon: CupertinoIcons.check_mark_circled,
                  title: '没有任务',
                ),
              );
            }),
            Obx(
              () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Container(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : 5,
                        bottom: 5,
                        left: 16,
                        right: 16,
                      ),
                      child: createCard(
                          context,
                          _taskController.todoDeadlineList[index],
                          UidColors.colorFromUid(
                              _taskController.todoDeadlineList[index].uid),
                          index == 0 ? '待办' : null),
                    );
                  },
                  childCount: _taskController.todoDeadlineList.length,
                ),
              ),
            ),
            Obx(
              () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Container(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : 5,
                        bottom: 5,
                        left: 16,
                        right: 16,
                      ),
                      child: createCard(
                          context,
                          _taskController.doneDeadlineList[index],
                          UidColors.colorFromUid(
                              _taskController.doneDeadlineList[index].uid),
                          index == 0 ? '已完成' : null),
                    );
                  },
                  childCount: _taskController.doneDeadlineList.length,
                ),
              ),
            ),
            Obx(
              () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Container(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : 5,
                        bottom: 5,
                        left: 16,
                        right: 16,
                      ),
                      child: createCard(
                          context,
                          _taskController.fixedDeadlineList[index],
                          UidColors.colorFromUid(
                              _taskController.fixedDeadlineList[index].uid),
                          index == 0 ? '日程列表' : null),
                    );
                  },
                  childCount: _taskController.fixedDeadlineList.length,
                ),
              ),
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

class TaskPageColors {
  static const List<CupertinoDynamicColor> taskMarkColors = [
    spring,
    summer,
    winter,
    violet,
    sakura,
    cyan,
    magenta,
    peach,
    okGreen,
  ];

  static const CupertinoDynamicColor spring =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(230, 255, 226, 1.0),
    darkColor: Color.fromRGBO(147, 251, 56, 1.0),
  );

  static const CupertinoDynamicColor summer =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 218, 238, 1.0),
    darkColor: Color.fromRGBO(255, 25, 69, 1.0),
  );

  static const CupertinoDynamicColor autumn =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 234, 230, 1.0),
    darkColor: Color.fromRGBO(255, 101, 56, 1.0),
  );

  static const CupertinoDynamicColor winter =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(226, 239, 255, 1.0),
    darkColor: Color.fromRGBO(0, 183, 251, 1.0),
  );

  static const CupertinoDynamicColor violet =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(230, 229, 255, 1.0),
    darkColor: Color.fromRGBO(151, 131, 216, 1.0),
  );

  static const CupertinoDynamicColor sakura =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 226, 255, 1.0),
    darkColor: Color.fromRGBO(218, 130, 217, 1.0),
  );

  static const CupertinoDynamicColor sand =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 246, 211, 1.0),
    darkColor: Color.fromRGBO(252, 222, 59, 1.0),
  );

  static const CupertinoDynamicColor cyan =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(218, 234, 255, 1.0),
    darkColor: Color.fromRGBO(0, 140, 255, 1.0),
  );

  static const CupertinoDynamicColor magenta =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(230, 229, 255, 1.0),
    darkColor: Color.fromRGBO(238, 55, 161, 1.0),
  );

  static const CupertinoDynamicColor peach =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(255, 235, 226, 1.0),
    darkColor: Color.fromRGBO(233, 114, 70, 1.0),
  );

  static const CupertinoDynamicColor okGreen =
      CupertinoDynamicColor.withBrightness(
    color: Color.fromRGBO(230, 255, 226, 1.0),
    darkColor: Color.fromRGBO(63, 222, 23, 1.0),
  );
}
