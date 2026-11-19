import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/utils/tuple.dart';
import 'package:celechron/model/grade.dart';
import 'package:celechron/model/semester.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/design/two_line_card.dart';
import 'grade_semester_picker.dart';
import 'package:celechron/design/persistent_headers.dart';
import 'package:celechron/design/liquid_glass/navigation_action.dart';
import 'grade_card.dart';
import 'grade_detail_controller.dart';
import 'package:celechron/utils/gpa_helper.dart';
import 'weighted_gpa_view.dart';

class GradeDetailPage extends StatelessWidget {
  final _gradeDetailController = Get.put(GradeDetailController());

  GradeDetailPage({super.key}) {
    _gradeDetailController.init();
  }

  int getPairedSemesterIndex(int idx) {
    for (var i = 0;
        i < _gradeDetailController.semestersWithGrades.length;
        i++) {
      if (i != idx &&
          _gradeDetailController.semestersWithGrades[i].name.substring(2, 5) ==
              _gradeDetailController.semestersWithGrades[idx].name
                  .substring(2, 5)) {
        return i;
      }
    }
    return idx;
  }

  Tuple<List<double>, double> getYearStats(int semesterIndex) {
    var s1 = _gradeDetailController.semestersWithGrades[semesterIndex];
    int another = getPairedSemesterIndex(semesterIndex);
    if (another == semesterIndex) {
      return Tuple([s1.gpa[0], s1.gpa[1], s1.gpa[2]], s1.credits);
    }
    var s2 = _gradeDetailController.semestersWithGrades[another];
    double credits = s1.credits + s2.credits;
    if (credits == 0) {
      return Tuple([0, 0, 0], 0);
    }
    return Tuple(
        List.generate(
            3,
            (int i) =>
                (s1.credits * s1.gpa[i] + s2.credits * s2.gpa[i]) / credits),
        credits);
  }

  Widget _buildGradeBrief(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Hero(
                tag: 'gradeBrief',
                child: RoundRectangleCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '学年学分',
                                content: getYearStats(
                                        _gradeDetailController.selectedIndex)
                                    .item2
                                    .toStringAsFixed(1),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.peach)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '学年均绩',
                                content: getYearStats(
                                        _gradeDetailController.selectedIndex)
                                    .item1[0]
                                    .toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.cyan)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '学年四分制',
                                content: getYearStats(
                                        _gradeDetailController.selectedIndex)
                                    .item1[1]
                                    .toStringAsFixed(2),
                                extraContent: getYearStats(
                                        _gradeDetailController.selectedIndex)
                                    .item1[2]
                                    .toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.spring)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '学年主修学分',
                                content: _gradeDetailController
                                    .getYearMajorGpa(
                                        _gradeDetailController.selectedIndex)
                                    .item2
                                    .toStringAsFixed(1),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.sand)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '学年主修均绩',
                                content: _gradeDetailController
                                    .getYearMajorGpa(
                                        _gradeDetailController.selectedIndex)
                                    .item1[0]
                                    .toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.sakura)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '学年主修四分制',
                                content: _gradeDetailController
                                    .getYearMajorGpa(
                                        _gradeDetailController.selectedIndex)
                                    .item1[1]
                                    .toStringAsFixed(2),
                                extraContent: _gradeDetailController
                                    .getYearMajorGpa(
                                        _gradeDetailController.selectedIndex)
                                    .item1[2]
                                    .toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.spring)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCustomGpaBrief(BuildContext context) {
    List<Grade> inSelected = [], notSelected = [];
    for (var semester in _gradeDetailController.semestersWithGrades) {
      for (var grade in semester.grades) {
        if (_gradeDetailController.customGpaSelected[grade.id] ?? false) {
          inSelected.add(grade);
        } else {
          notSelected.add(grade);
        }
      }
    }
    var inGpa = GpaHelper.calculateGpa(inSelected);
    var notGpa = GpaHelper.calculateGpa(notSelected);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Hero(
                tag: 'gradeBrief',
                child: RoundRectangleCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '已选学分',
                                content: inGpa.item2.toStringAsFixed(1),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.sand)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '已选五分制',
                                content: inGpa.item1[0].toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.sakura)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '已选四分制',
                                content: inGpa.item1[1].toStringAsFixed(2),
                                extraContent: inGpa.item1[2].toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.magenta)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '已选百分制',
                                content: inGpa.item1[3].toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.peach)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '未选五分制',
                                content: notGpa.item1[0].toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.cyan)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => TwoLineCard(
                                mutedTint: true,
                                title: '未选四分制',
                                content: notGpa.item1[1].toStringAsFixed(2),
                                extraContent:
                                    notGpa.item1[2].toStringAsFixed(2),
                                backgroundColor:
                                    CustomCupertinoDynamicColors.spring)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  int getSelectedGradeCount(Semester semester) {
    int selectedCount = 0;
    for (var i in semester.grades) {
      if (_gradeDetailController.customGpaSelected[i.id] ?? false) {
        selectedCount++;
      }
    }
    return selectedCount;
  }

  Widget _buildHistory() => Obx(() {
        final controller = _gradeDetailController;
        final custom = controller.customGpaMode.value;

        void select(int index) {
          controller.semesterIndex.value = index;
          controller.semesterIndex.refresh();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GradeSemesterPicker(
            semesters: controller.semestersWithGrades,
            selectedIndex: controller.selectedIndex,
            onSelected: select,
            selectionSummary: custom
                ? (semester) =>
                    '${getSelectedGradeCount(semester)} / ${semester.grades.length}'
                : null,
            onLongPress: custom
                ? (index) {
                    select(index);
                    controller.toggleSemesterSelection(index);
                  }
                : null,
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGroupedBackground, context),
      child: CustomScrollView(
        slivers: [
          CelechronSliverTextHeader(
            subtitle: '成绩',
            right: Obx(() {
              final controller = _gradeDetailController;
              final custom = controller.customGpaMode.value;
              void toggleMode() => controller.customGpaMode.value = !custom;

              if (!custom) {
                if (controller.semestersWithGrades.isEmpty) {
                  return const SizedBox.shrink();
                }
                return NavigationActionGroup(
                  actions: [
                    (
                      icon: CupertinoIcons.chart_bar,
                      label: '加权成绩',
                      onPressed: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                          builder: (_) => WeightedGpaPage(),
                        ));
                      },
                    ),
                    (
                      icon: CupertinoIcons.square_line_vertical_square,
                      label: '自定义绩点',
                      onPressed: toggleMode,
                    ),
                  ],
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () {
                      controller.customGpaSelected.clear();
                      controller.refreshCustomGpa();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('长按清空'),
                    ),
                  ),
                  NavigationAction(
                    icon: CupertinoIcons.square_fill_line_vertical_square_fill,
                    label: '退出自定义绩点',
                    onPressed: toggleMode,
                  ),
                ],
              );
            }),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        children: [
                          Obx(() {
                            final controller = _gradeDetailController;
                            if (controller.semestersWithGrades.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Text('暂无成绩。请返回学业页下拉刷新。'),
                              );
                            }
                            return controller.customGpaMode.value
                                ? _buildCustomGpaBrief(context)
                                : _buildGradeBrief(context);
                          }),
                          _buildHistory(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                  ],
                )
              ],
            ),
          ),
          Obx(() {
            final controller = _gradeDetailController;
            final grades = controller.semestersWithGrades.isEmpty
                ? const <Grade>[]
                : controller
                    .semestersWithGrades[controller.selectedIndex].grades;
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  18, 0, 18, MediaQuery.paddingOf(context).bottom + 8),
              sliver: SliverList.builder(
                itemCount: grades.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GradeCard(grade: grades[index]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
