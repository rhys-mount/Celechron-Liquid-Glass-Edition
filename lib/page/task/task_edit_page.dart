import 'package:flutter/cupertino.dart';
import 'package:celechron/design/action_dialogs.dart';
import 'package:celechron/design/liquid_glass/navigation_action.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/utils/utils.dart';
import 'package:celechron/utils/time_helper.dart';

class TaskEditPage extends StatefulWidget {
  final Task deadline;
  final bool isNew;
  const TaskEditPage(this.deadline, {super.key, this.isNew = false});

  static Future<Task?> open(BuildContext context, Task task) {
    final route = MediaQuery.disableAnimationsOf(context)
        ? PageRouteBuilder<Task>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                TaskEditPage(task),
          )
        : CupertinoPageRoute<Task>(builder: (_) => TaskEditPage(task));
    return Navigator.of(context, rootNavigator: true).push(route);
  }

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  late Task now;
  late final TextEditingController _summary;
  late final TextEditingController _location;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    now = widget.deadline.copyWith();
    if (now.startTime.isAfter(now.endTime)) {
      now.startTime = now.endTime.subtract(const Duration(minutes: 1));
    }
    if (now.repeatEndsTime.isAfter(DateTime(2099)) ||
        dateOnly(now.repeatEndsTime).isBefore(dateOnly(now.startTime))) {
      now.repeatEndsTime = dateOnly(now.startTime);
    }
    _summary = TextEditingController(text: now.summary);
    _location = TextEditingController(text: now.location);
    _description = TextEditingController(text: now.description);
  }

  @override
  void dispose() {
    _summary.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void saveAndExit() {
    if (now.type == TaskType.fixed && !now.startTime.isBefore(now.endTime)) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text(
              '结束时间必须晚于开始时间',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
      return;
    }

    if (now.type == TaskType.fixed &&
        now.repeatType != TaskRepeatType.norepeat &&
        dateOnly(now.startTime).isAfter(dateOnly(now.repeatEndsTime))) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text(
              '开始时间不能晚于重复截止日期',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
      return;
    }

    if (now.type == TaskType.fixed &&
        now.repeatType != TaskRepeatType.norepeat) {
      int length = now.endTime.difference(now.startTime).inMinutes;
      if ((now.repeatType == TaskRepeatType.days &&
              length > now.repeatPeriod * 24 * 60) ||
          (now.repeatType == TaskRepeatType.month && length > 28 * 24 * 60) ||
          (now.repeatType == TaskRepeatType.year && length > 365 * 24 * 60)) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text(
                '这个重复日程的持续时间太长',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
        return;
      }
    }

    FormState().save();
    now.forceRefreshStatus();
    Navigator.of(context).pop(now);
  }

  void removeAndExit() {
    FormState().save();
    now.forceRefreshStatus();
    now.status = TaskStatus.deleted;
    Navigator.of(context).pop(now);
  }

  void exitWithoutSave() {
    Navigator.of(context).pop();
  }

  Future<void> _editDate(
    String title,
    DateTime initial,
    ValueChanged<DateTime> apply, {
    CupertinoDatePickerMode mode = CupertinoDatePickerMode.dateAndTime,
  }) async {
    final value = await showDatePickerSheet(
      context,
      title: title,
      initialValue: initial,
      mode: mode,
    );
    if (!mounted || value == null) return;
    setState(() => apply(value));
  }

  Future<void> _editDuration(bool expected) async {
    final initial = expected ? now.timeNeeded : now.timeSpent;
    var hours = initial.inHours;
    var minutes = initial.inMinutes % 60;
    final value = await showPickerSheet<Duration>(
      context,
      title: expected ? '预期用时' : '已经用时',
      initialValue: initial,
      builder: (context, update) => Row(
        children: [
          Expanded(
              child: _NumberWheel(
            initial: hours,
            count: 1000,
            onChanged: (value) {
              hours = value;
              update(Duration(hours: hours, minutes: minutes));
            },
          )),
          const Text('小时'),
          Expanded(
              child: _NumberWheel(
            initial: minutes,
            count: 60,
            looping: true,
            onChanged: (value) {
              minutes = value;
              update(Duration(hours: hours, minutes: minutes));
            },
          )),
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 16),
            child: Text('分钟'),
          ),
        ],
      ),
    );
    if (!mounted || value == null) return;
    setState(() {
      if (expected) {
        now.timeNeeded =
            value == Duration.zero ? const Duration(minutes: 1) : value;
      } else {
        now.timeSpent = value;
      }
    });
  }

  Future<void> _editRepeatType() async {
    final repeat = await showPickerSheet<int>(
      context,
      title: '重复',
      initialValue: now.repeatType.index,
      builder: (context, update) => _NumberWheel(
        initial: now.repeatType.index,
        count: TaskRepeatType.values.length,
        label: (index) => deadlineRepeatTypeName[TaskRepeatType.values[index]]!,
        onChanged: update,
      ),
    );
    if (!mounted || repeat == null) return;
    setState(() {
      now.repeatType = TaskRepeatType.values[repeat];
      if (now.repeatType != TaskRepeatType.norepeat &&
          dateOnly(now.repeatEndsTime).isBefore(dateOnly(now.startTime))) {
        now.repeatEndsTime = dateOnly(now.startTime);
      }
    });
  }

  Future<void> _editRepeatPeriod() async {
    final period = await showPickerSheet<int>(
      context,
      title: '重复周期',
      initialValue: now.repeatPeriod,
      builder: (context, update) => _NumberWheel(
        initial: now.repeatPeriod - 1,
        count: 999,
        label: (index) => '${index + 1} 天',
        onChanged: (index) => update(index + 1),
      ),
    );
    if (!mounted || period == null) return;
    setState(() => now.repeatPeriod = period);
  }

  @override
  Widget build(BuildContext context) {
    final itemName = now.type == TaskType.deadline ? '任务' : '日程';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGroupedBackground, context),
        leading: NavigationAction(
          icon: CupertinoIcons.xmark,
          label: '关闭编辑',
          onPressed: exitWithoutSave,
        ),
        middle: Text(widget.isNew ? '新建$itemName' : '编辑$itemName'),
        trailing: Semantics(
          label: '保存任务',
          button: true,
          onTap: saveAndExit,
          excludeSemantics: true,
          child: CupertinoButton.filled(
            minimumSize: const Size(52, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            borderRadius: BorderRadius.circular(22),
            onPressed: saveAndExit,
            child: const Text('保存', style: TextStyle(fontSize: 15)),
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 20.0,
                    bottom: 8.0,
                  ),
                  child: CupertinoSlidingSegmentedControl<TaskType>(
                    groupValue: now.type,
                    children: <TaskType, Widget>{
                      TaskType.deadline: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Text('任务'),
                      ),
                      TaskType.fixed: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('${deadlineTypeName[TaskType.fixed]}'),
                      ),
                    },
                    onValueChanged: (TaskType? value) {
                      if (value != null) {
                        setState(() {
                          now.type = value;
                          if (now.type == TaskType.fixed) {
                            now.status = TaskStatus.running;
                          }
                        });
                      }
                    },
                  ),
                ),
                CupertinoListSection.insetGrouped(
                  header: const Text('基本信息'),
                  children: [
                    CupertinoTextFormFieldRow(
                      placeholder: '任务名',
                      textAlign: TextAlign.left,
                      controller: _summary,
                      maxLines: 3,
                      minLines: 1,
                      onChanged: (String value) {
                        now.summary = value;
                      },
                    ),
                    if (now.type == TaskType.fixed)
                      CupertinoListTile(
                        title: const Text('开始时间'),
                        subtitle:
                            Text(TimeHelper.chineseDateTime(now.startTime)),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () => _editDate('开始时间', now.startTime, (value) {
                          now.startTime = value;
                          if (now.endTime.isBefore(value)) now.endTime = value;
                        }),
                      ),
                    CupertinoListTile(
                      title:
                          Text(now.type == TaskType.deadline ? '截止时间' : '结束时间'),
                      subtitle: Text(TimeHelper.chineseDateTime(now.endTime)),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => _editDate(
                          itemName == '任务' ? '截止时间' : '结束时间', now.endTime,
                          (value) {
                        now.endTime = value;
                        if (now.type == TaskType.fixed &&
                            now.startTime.isAfter(value)) now.startTime = value;
                      }),
                    ),
                  ],
                ),
                if (now.type == TaskType.deadline)
                  CupertinoListSection.insetGrouped(
                    header: const Text('时间安排'),
                    children: [
                      CupertinoListTile(
                        title: const Text('预期用时'),
                        trailing: Text(durationToString(now.timeNeeded)),
                        onTap: () => _editDuration(true),
                      ),
                      CupertinoListTile(
                        title: const Text('已经用时'),
                        trailing: Text(durationToString(now.timeSpent)),
                        onTap: () => _editDuration(false),
                      ),
                      CupertinoListTile(
                        title: const Text('允许插入休息时间'),
                        trailing: CupertinoSwitch(
                          value: now.isBreakable,
                          onChanged: (value) {
                            setState(() {
                              now.isBreakable = !now.isBreakable;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                if (now.type == TaskType.fixed) ...[
                  CupertinoListSection.insetGrouped(
                    header: const Text('日程设置'),
                    children: [
                      CupertinoListTile(
                        title: const Text('重复'),
                        trailing: Text(deadlineRepeatTypeName[now.repeatType]!),
                        onTap: _editRepeatType,
                      ),
                      if (now.repeatType == TaskRepeatType.days)
                        CupertinoListTile(
                          title: const Text('重复周期'),
                          trailing: Text('${now.repeatPeriod} 天'),
                          onTap: _editRepeatPeriod,
                        ),
                      if (now.repeatType != TaskRepeatType.norepeat)
                        CupertinoListTile(
                          title: const Text('重复截止日期'),
                          trailing:
                              Text(TimeHelper.chineseDate(now.repeatEndsTime)),
                          onTap: () => _editDate('重复截止日期', now.repeatEndsTime,
                              (value) => now.repeatEndsTime = value,
                              mode: CupertinoDatePickerMode.date),
                        ),
                      CupertinoListTile(
                        title: const Text('不在这个日程中安排任务'),
                        trailing: CupertinoSwitch(
                          value: now.blockArrangements,
                          onChanged: (value) {
                            setState(() {
                              now.blockArrangements = !now.blockArrangements;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  // Container(
                  //   padding: const EdgeInsets.only(left: 40, right: 40),
                  //   child: Text(
                  //     '可以在其中安排任务的日程不会出现在“接下来”栏中。',
                  //     style: TextStyle(
                  //         color: CupertinoDynamicColor.resolve(
                  //             CupertinoColors.secondaryLabel, context),
                  //         fontSize: 14),
                  //   ),
                  // ),
                ],
                CupertinoListSection.insetGrouped(
                  header: const Text('附加信息'),
                  children: [
                    CupertinoTextFormFieldRow(
                      prefix: const Text('地点'),
                      placeholder: '选填',
                      textAlign: TextAlign.left,
                      controller: _location,
                      onChanged: (String value) {
                        now.location = value;
                      },
                    ),
                    CupertinoTextFormFieldRow(
                      prefix: const Text('说明'),
                      placeholder: '选填',
                      textAlign: TextAlign.left,
                      controller: _description,
                      maxLines: 6,
                      minLines: 2,
                      onChanged: (String value) {
                        now.description = value;
                      },
                    ),
                  ],
                ),
                if (!widget.isNew)
                  CupertinoButton(
                    onPressed: removeAndExit,
                    child: Text(
                      '删除$itemName',
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberWheel extends StatefulWidget {
  const _NumberWheel({
    required this.initial,
    required this.count,
    required this.onChanged,
    this.label,
    this.looping = false,
  });

  final int initial;
  final int count;
  final ValueChanged<int> onChanged;
  final String Function(int)? label;
  final bool looping;

  @override
  State<_NumberWheel> createState() => _NumberWheelState();
}

class _NumberWheelState extends State<_NumberWheel> {
  late final _scroll = FixedExtentScrollController(
    initialItem: widget.initial.clamp(0, widget.count - 1),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extent = MediaQuery.textScalerOf(context).scale(32);
    Widget item(int index) =>
        Center(child: Text(widget.label?.call(index) ?? index.toString()));
    if (widget.looping) {
      return CupertinoPicker(
        itemExtent: extent,
        scrollController: _scroll,
        onSelectedItemChanged: widget.onChanged,
        looping: true,
        children: List.generate(widget.count, item),
      );
    }
    return CupertinoPicker.builder(
      itemExtent: extent,
      scrollController: _scroll,
      onSelectedItemChanged: widget.onChanged,
      childCount: widget.count,
      itemBuilder: (context, index) => item(index),
    );
  }
}
