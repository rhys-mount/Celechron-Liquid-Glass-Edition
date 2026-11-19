import 'package:celechron/design/action_dialogs.dart';
import 'package:celechron/design/persistent_headers.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'option_controller.dart';

String timeToString(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class DateTimePair {
  DateTime first, second;
  bool isDeleted;
  DateTimePair({
    required this.first,
    required this.second,
    this.isDeleted = false,
  });
}

class DateTimePairEditDialog extends StatefulWidget {
  final DateTimePair val;
  final Function(DateTimePair pair)? onChanged;
  const DateTimePairEditDialog({
    super.key,
    required this.val,
    this.onChanged,
  });
  @override
  State<DateTimePairEditDialog> createState() => _DateTimePairEditDialogState();
}

class _DateTimePairEditDialogState extends State<DateTimePairEditDialog> {
  late DateTimePair val;
  @override
  void initState() {
    super.initState();
    val = DateTimePair(first: widget.val.first, second: widget.val.second);
  }

  void saveChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(val);
    }
  }

  Future<void> _editTime({required bool start}) async {
    final value = await showDatePickerSheet(
      context,
      title: start ? '开始时间' : '结束时间',
      initialValue: start ? val.first : val.second,
      mode: CupertinoDatePickerMode.time,
    );
    if (!mounted || value == null) return;
    setState(() {
      if (start) {
        val.first = value;
      } else {
        val.second = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('更改时段'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoButton(
            onPressed: () => _editTime(start: true),
            child: Text('开始时间 ${timeToString(val.first)}'),
          ),
          CupertinoButton(
            onPressed: () => _editTime(start: false),
            child: Text('结束时间 ${timeToString(val.second)}'),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('取消'),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        CupertinoDialogAction(
          child: const Text('确定'),
          onPressed: () async {
            Navigator.of(context).pop();
            saveChange();
          },
        ),
      ],
    );
  }
}

class AllowTimeEditPage extends StatefulWidget {
  const AllowTimeEditPage({super.key});

  @override
  State<AllowTimeEditPage> createState() => _AllowTimeEditPageState();
}

class _AllowTimeEditPageState extends State<AllowTimeEditPage> {
  final _optionController = Get.find<OptionController>(tag: 'optionController');
  List<DateTimePair> now = [];
  int __got = 0;

  void getAllowTime() {
    now.clear();
    for (var x in _optionController.allowTime.keys) {
      now.add(DateTimePair(
        first: x.copyWith(),
        second: _optionController.allowTime[x]!.copyWith(),
      ));
    }
    now.sort((DateTimePair a, DateTimePair b) {
      if (a.first.compareTo(b.first) != 0) {
        return a.first.compareTo(b.first);
      }
      return a.second.compareTo(b.second);
    });
    setState(() {});
  }

  void saveAllowTime() async {
    for (int i = 0; i < now.length; i++) {
      var x = now[i];

      if (!x.first.isBefore(x.second)) {
        await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text(
                '开始时间必须早于结束时间',
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
        getAllowTime();
        return;
      }

      for (int j = 0; j < now.length; j++) {
        if (i == j) continue;
        var y = now[j];
        if ((!x.first.isBefore(y.first) && !x.first.isAfter(y.second)) ||
            (!x.second.isBefore(y.first) && !x.second.isAfter(y.second))) {
          await showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: const Text(
                  '时间段之间不能有重合或直接相邻',
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
          getAllowTime();
          return;
        }
      }
    }

    FormState().save();
    Map<DateTime, DateTime> res = {};
    for (var x in now) {
      res[x.first] = x.second;
    }

    _optionController.allowTime = res;
  }

  @override
  Widget build(BuildContext context) {
    if (__got == 0) {
      getAllowTime();
      __got = 1;
    }

    now.removeWhere((element) => element.isDeleted);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            const CelechronSliverTextHeader(subtitle: '编辑可用工作时段'),
            SliverList(
              delegate: SliverChildListDelegate([
                CupertinoListSection.insetGrouped(
                  header: Container(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      '可用工作时段列表',
                      style: TextStyle(
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.secondaryLabel, context),
                          fontSize: 14),
                    ),
                  ),
                  children: [
                    ...List.generate(
                      now.length,
                      (index) => CupertinoFormRow(
                        prefix: Text(
                            '${timeToString(now[index].first)} - ${timeToString(now[index].second)}'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                showCupertinoDialog(
                                  context: context,
                                  builder: (context) => DateTimePairEditDialog(
                                    val: now[index],
                                    onChanged: (DateTimePair updated) {
                                      setState(() {
                                        now[index] = DateTimePair(
                                          first: updated.first,
                                          second: updated.second,
                                          isDeleted: updated.isDeleted,
                                        );
                                        saveAllowTime();
                                      });
                                    },
                                  ),
                                );
                              },
                              child: const Icon(
                                CupertinoIcons.pencil,
                                semanticLabel: '更改时段',
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (now.length > 1) {
                                  setState(() {
                                    now.removeAt(index);
                                    saveAllowTime();
                                  });
                                }
                              },
                              child: const Icon(
                                CupertinoIcons.delete,
                                semanticLabel: '删除时段',
                                color: CupertinoColors.destructiveRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: () {
                    now.add(DateTimePair(
                      first: DateTime(0, 0, 0, 8, 0),
                      second: DateTime(0, 0, 0, 12, 0),
                      isDeleted: false,
                    ));
                    setState(() {});
                  },
                  child: const Text('添加一个时段'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
