import 'package:flutter/cupertino.dart';
import 'package:celechron/design/liquid_glass/navigation_action.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/utils/utils.dart';
import 'package:celechron/utils/time_helper.dart';

class TaskEditPage extends StatefulWidget {
  final Task deadline;
  const TaskEditPage(this.deadline, {super.key});

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
    now = widget.deadline.copyWith();
    Navigator.of(context).pop(now);
  }

  @override
  Widget build(BuildContext context) {
    List<String> deadlineRepeatTypeNameList = [];
    for (var i in TaskRepeatType.values) {
      deadlineRepeatTypeNameList.add(deadlineRepeatTypeName[i]!);
    }

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
        middle: const Text('编辑任务'),
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
                        child: Text('${deadlineTypeName[TaskType.deadline]}'),
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
                        onTap: () async {
                          await showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) {
                                return CupertinoPageScaffold(
                                  child: SizedBox(
                                    height: MediaQuery.of(context)
                                            .copyWith()
                                            .size
                                            .height /
                                        3,
                                    child: CupertinoDatePicker(
                                      initialDateTime: now.startTime,
                                      use24hFormat: true,
                                      minuteInterval: 1,
                                      mode: CupertinoDatePickerMode.dateAndTime,
                                      onDateTimeChanged: (DateTime newTime) {
                                        setState(() {
                                          now.startTime = newTime;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              });
                          if (now.endTime.isBefore(now.startTime)) {
                            setState(() {
                              now.endTime = now.startTime;
                            });
                          }
                        },
                      ),
                    CupertinoListTile(
                      title:
                          Text(now.type == TaskType.deadline ? '截止时间' : '结束时间'),
                      subtitle: Text(TimeHelper.chineseDateTime(now.endTime)),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () async {
                        await showCupertinoModalPopup(
                            context: context,
                            builder: (BuildContext context) {
                              return CupertinoPageScaffold(
                                child: SizedBox(
                                  height: MediaQuery.of(context)
                                          .copyWith()
                                          .size
                                          .height /
                                      3,
                                  child: CupertinoDatePicker(
                                    initialDateTime: now.endTime,
                                    use24hFormat: true,
                                    minuteInterval: 1,
                                    mode: CupertinoDatePickerMode.dateAndTime,
                                    onDateTimeChanged: (DateTime newTime) {
                                      setState(() {
                                        now.endTime = newTime;
                                      });
                                    },
                                  ),
                                ),
                              );
                            });
                        if (now.type == TaskType.fixed &&
                            now.startTime.isAfter(now.endTime)) {
                          setState(() {
                            now.startTime = now.endTime;
                          });
                        }
                      },
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
                        onTap: () async {
                          await showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) {
                                return CupertinoPageScaffold(
                                  child: SizedBox(
                                    height: MediaQuery.of(context)
                                            .copyWith()
                                            .size
                                            .height /
                                        3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 150,
                                          child: CupertinoPicker(
                                            itemExtent: 32,
                                            scrollController:
                                                FixedExtentScrollController(
                                              initialItem:
                                                  now.timeNeeded.inHours,
                                            ),
                                            onSelectedItemChanged: (value) {
                                              now.timeNeeded = Duration(
                                                  hours: value,
                                                  minutes:
                                                      now.timeNeeded.inMinutes %
                                                          60);
                                              if (now.timeNeeded <=
                                                  Duration.zero) {
                                                now.timeNeeded =
                                                    const Duration(minutes: 1);
                                              }

                                              setState(() {});
                                            },
                                            children: List.generate(
                                              1000,
                                              (index) =>
                                                  Center(child: Text("$index")),
                                            ),
                                          ),
                                        ),
                                        const Text('小时'),
                                        SizedBox(
                                          width: 150,
                                          child: CupertinoPicker(
                                            itemExtent: 32,
                                            looping: true,
                                            scrollController:
                                                FixedExtentScrollController(
                                              initialItem:
                                                  now.timeNeeded.inMinutes % 60,
                                            ),
                                            onSelectedItemChanged: (value) {
                                              now.timeNeeded = Duration(
                                                hours:
                                                    now.timeNeeded.inMinutes ~/
                                                        60,
                                                minutes: value,
                                              );
                                              if (now.timeNeeded <=
                                                  Duration.zero) {
                                                now.timeNeeded =
                                                    const Duration(minutes: 1);
                                              }

                                              setState(() {});
                                            },
                                            children: List.generate(
                                              60,
                                              (index) =>
                                                  Center(child: Text("$index")),
                                            ),
                                          ),
                                        ),
                                        const Text('分钟'),
                                      ],
                                    ),
                                    // CupertinoTimerPicker(
                                    //   mode: CupertinoTimerPickerMode.hm,
                                    //   initialTimerDuration: now.timeNeeded,
                                    //   onTimerDurationChanged: (value) {
                                    //     if (value > Duration.zero) {
                                    //       setState(() {
                                    //         now.timeNeeded = value;
                                    //       });
                                    //     } else {
                                    //       setState(() {
                                    //         now.timeNeeded =
                                    //             const Duration(minutes: 1);
                                    //       });
                                    //     }
                                    //   },
                                    // ),
                                  ),
                                );
                              });
                        },
                      ),
                      CupertinoListTile(
                        title: const Text('已经用时'),
                        trailing: Text(durationToString(now.timeSpent)),
                        onTap: () async {
                          await showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) {
                                return CupertinoPageScaffold(
                                  child: SizedBox(
                                    height: MediaQuery.of(context)
                                            .copyWith()
                                            .size
                                            .height /
                                        3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 150,
                                          child: CupertinoPicker(
                                            itemExtent: 32,
                                            scrollController:
                                                FixedExtentScrollController(
                                              initialItem:
                                                  now.timeSpent.inHours,
                                            ),
                                            onSelectedItemChanged: (value) {
                                              now.timeSpent = Duration(
                                                  hours: value,
                                                  minutes:
                                                      now.timeSpent.inMinutes %
                                                          60);

                                              setState(() {});
                                            },
                                            children: List.generate(
                                              1000,
                                              (index) =>
                                                  Center(child: Text("$index")),
                                            ),
                                          ),
                                        ),
                                        const Text('小时'),
                                        SizedBox(
                                          width: 150,
                                          child: CupertinoPicker(
                                            itemExtent: 32,
                                            looping: true,
                                            scrollController:
                                                FixedExtentScrollController(
                                              initialItem:
                                                  now.timeSpent.inMinutes % 60,
                                            ),
                                            onSelectedItemChanged: (value) {
                                              now.timeSpent = Duration(
                                                hours:
                                                    now.timeSpent.inMinutes ~/
                                                        60,
                                                minutes: value,
                                              );

                                              setState(() {});
                                            },
                                            children: List.generate(
                                              60,
                                              (index) =>
                                                  Center(child: Text("$index")),
                                            ),
                                          ),
                                        ),
                                        const Text('分钟'),
                                      ],
                                    ),
                                    // child: CupertinoTimerPicker(
                                    //   mode: CupertinoTimerPickerMode.hm,
                                    //   initialTimerDuration: now.timeSpent,
                                    //   onTimerDurationChanged: (value) {
                                    //     setState(() {
                                    //       now.timeSpent = value;
                                    //     });
                                    //   },
                                    // ),
                                  ),
                                );
                              });
                        },
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
                        onTap: () async {
                          await showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) {
                                return CupertinoPageScaffold(
                                  child: SizedBox(
                                    height: MediaQuery.of(context)
                                            .copyWith()
                                            .size
                                            .height /
                                        3,
                                    child: CupertinoPicker(
                                      itemExtent: 32,
                                      scrollController:
                                          FixedExtentScrollController(
                                        initialItem: now.repeatType.index,
                                      ),
                                      onSelectedItemChanged: (int value) {
                                        setState(() {
                                          now.repeatType =
                                              TaskRepeatType.values[value];

                                          if (now.repeatType !=
                                                  TaskRepeatType.norepeat &&
                                              dateOnly(now.repeatEndsTime)
                                                  .isBefore(dateOnly(
                                                      now.startTime))) {
                                            now.repeatEndsTime =
                                                dateOnly(now.startTime);
                                          }
                                        });
                                      },
                                      children: List<Widget>.generate(
                                        deadlineRepeatTypeNameList.length,
                                        (int index) {
                                          return Center(
                                            child: Text(
                                              deadlineRepeatTypeNameList[index],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              });
                        },
                      ),
                      if (now.repeatType == TaskRepeatType.days)
                        CupertinoListTile(
                          title: const Text('重复周期'),
                          trailing: Text('${now.repeatPeriod} 天'),
                          onTap: () async {
                            await showCupertinoModalPopup(
                                context: context,
                                builder: (BuildContext context) {
                                  return CupertinoPageScaffold(
                                    child: SizedBox(
                                      height: MediaQuery.of(context)
                                              .copyWith()
                                              .size
                                              .height /
                                          3,
                                      child: CupertinoPicker(
                                        itemExtent: 32,
                                        scrollController:
                                            FixedExtentScrollController(
                                          initialItem: now.repeatPeriod - 1,
                                        ),
                                        onSelectedItemChanged: (int value) {
                                          setState(() {
                                            now.repeatPeriod = value + 1;
                                          });
                                        },
                                        children: List<Widget>.generate(
                                          999,
                                          (int index) {
                                            return Center(
                                              child:
                                                  Text((index + 1).toString()),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                });
                          },
                        ),
                      if (now.repeatType != TaskRepeatType.norepeat)
                        CupertinoListTile(
                          title: const Text('重复截止日期'),
                          trailing:
                              Text(TimeHelper.chineseDate(now.repeatEndsTime)),
                          onTap: () async {
                            await showCupertinoModalPopup(
                                context: context,
                                builder: (BuildContext context) {
                                  return CupertinoPageScaffold(
                                    child: SizedBox(
                                      height: MediaQuery.of(context)
                                              .copyWith()
                                              .size
                                              .height /
                                          3,
                                      child: CupertinoDatePicker(
                                        mode: CupertinoDatePickerMode.date,
                                        initialDateTime: now.repeatEndsTime,
                                        onDateTimeChanged: (value) {
                                          setState(() {
                                            now.repeatEndsTime = value;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                });
                          },
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
                CupertinoButton(
                  onPressed: removeAndExit,
                  child: const Text(
                    '删除任务',
                    style: TextStyle(
                      color: CupertinoColors.systemPink,
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
