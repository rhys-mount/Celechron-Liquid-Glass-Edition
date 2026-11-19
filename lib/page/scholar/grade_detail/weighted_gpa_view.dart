import 'package:celechron/design/action_dialogs.dart';
import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/design/persistent_headers.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/design/two_line_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'grade_card.dart';
import 'grade_semester_picker.dart';
import 'weighted_gpa_controller.dart';

class WeightedGpaPage extends StatelessWidget {
  final _controller = Get.put(WeightedGpaController());

  WeightedGpaPage({super.key});

  Widget _buildWeightedGpaBrief() => Obx(() {
        final result = _controller.calculateCurrentSemesterWeightedGpa();
        return RoundRectangleCard(
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: TwoLineCard(
                  title: '加权学分',
                  content: result.item2.toStringAsFixed(1),
                  mutedTint: true,
                  backgroundColor: CustomCupertinoDynamicColors.peach,
                ),
              ),
              Expanded(
                child: TwoLineCard(
                  title: '加权五分制',
                  content: result.item1[0].toStringAsFixed(2),
                  mutedTint: true,
                  backgroundColor: CustomCupertinoDynamicColors.cyan,
                ),
              ),
            ],
          ),
        );
      });

  Widget _buildSelectionBar(int total) => Obx(() {
        final selected = _controller
            .getAllGrades()
            .where((grade) =>
                grade.gpaIncluded && _controller.includesGrade(grade.id))
            .length;
        const buttonPadding = EdgeInsets.symmetric(horizontal: 8);
        return RoundRectangleCard.content(
          animate: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text('已选 $selected / $total 门')),
              CupertinoButton(
                padding: buttonPadding,
                onPressed:
                    selected < total ? _controller.selectAllGrades : null,
                child: const Text('全选'),
              ),
              CupertinoButton(
                padding: buttonPadding,
                onPressed:
                    selected > 0 ? _controller.clearGradeSelection : null,
                child: const Text('清空勾选'),
              ),
            ],
          ),
        );
      });

  @override
  Widget build(BuildContext context) => Obx(() {
        final all = _controller.showAllSemesters.value;
        final grades = _controller
            .getCurrentSemesterGrades()
            .where((grade) => grade.gpaIncluded)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return CupertinoPageScaffold(
          backgroundColor:
              CupertinoColors.systemGroupedBackground.resolveFrom(context),
          child: CustomScrollView(
            slivers: [
              const CelechronSliverTextHeader(subtitle: '加权成绩'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 20,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          CupertinoButton(
                            onPressed: _controller.weightedMap.isEmpty
                                ? null
                                : () async {
                                    final confirmed =
                                        await confirmDestructiveAction(
                                      context,
                                      title: '重置加权倍率？',
                                      message: '所有课程将恢复为 1.0×，本次勾选不会改变。',
                                      action: '重置倍率',
                                    );
                                    if (!confirmed || !context.mounted) return;
                                    _controller.weightedMap.clear();
                                    _controller.refreshWeightedGpa();
                                  },
                            child: const Text('重置倍率'),
                          ),
                          CupertinoButton(
                            onPressed: () =>
                                _controller.showAllSemesters.value = !all,
                            child: Text(all ? '按学期' : '全部学期'),
                          ),
                        ],
                      ),
                      _buildWeightedGpaBrief(),
                      if (all) _buildSelectionBar(grades.length),
                      if (!all)
                        GradeSemesterPicker(
                          compactSingle: true,
                          semesters: _controller.semestersWithGrades,
                          selectedIndex: _controller.semesterIndex.value,
                          onSelected: (index) =>
                              _controller.semesterIndex.value = index,
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    18, 0, 18, MediaQuery.paddingOf(context).bottom + 8),
                sliver: SliverList.builder(
                  itemCount: grades.length,
                  itemBuilder: (context, index) {
                    final grade = grades[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Obx(() => GradeCard.weighted(
                            key: ValueKey(grade.id),
                            grade: grade,
                            weightIncluded:
                                !all || _controller.includesGrade(grade.id),
                            onWeightIncludedChanged: all
                                ? (included) => _controller.setGradeIncluded(
                                    grade.id, included)
                                : null,
                            weightControl: _WeightControl(
                              courseName: grade.name,
                              weight: _controller.getWeight(grade.id),
                              included:
                                  !all || _controller.includesGrade(grade.id),
                              onChanged: (weight) =>
                                  _controller.setWeight(grade.id, weight),
                            ),
                          )),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      });
}

class _WeightControl extends StatelessWidget {
  const _WeightControl({
    required this.courseName,
    required this.weight,
    required this.included,
    required this.onChanged,
  });

  // Four mutually exclusive presets, with no implied continuous scale.
  static const _options = [0.8, 1.0, 1.1, 1.2];
  final String courseName;
  final double weight;
  final bool included;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final isPreset = _options.contains(weight);
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$courseName加权比例',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          ExcludeSemantics(
            excluding: isPreset,
            child: Text(
              [
                isPreset ? '加权比例' : '加权比例 · 当前 $weight×',
                if (!included) '未计入本次统计',
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: secondary),
            ),
          ),
          CupertinoSlidingSegmentedControl<double>(
            groupValue: isPreset ? weight : null,
            padding: const EdgeInsets.all(3),
            onValueChanged: (value) {
              if (value != null && value != weight) onChanged(value);
            },
            children: {
              for (final value in _options)
                value: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${value.toStringAsFixed(1)}×',
                          semanticsLabel: '${value.toStringAsFixed(1)} 倍',
                          style: TextStyle(
                            fontSize: 14,
                            color: label,
                            fontWeight: value == weight
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}
