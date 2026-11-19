import 'package:celechron/design/card_action.dart';
import 'dart:math';

import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/page/scholar/grade_detail/grade_detail_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:celechron/model/grade.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';

class GradeCard extends StatelessWidget {
  final Grade grade;
  final CupertinoDynamicColor backgroundColor;
  final Widget? weightControl;
  final bool weightIncluded;
  final ValueChanged<bool>? onWeightIncludedChanged;

  const GradeCard({
    super.key,
    required this.grade,
    this.backgroundColor = CupertinoColors.systemBackground,
  })  : weightControl = null,
        weightIncluded = true,
        onWeightIncludedChanged = null;

  const GradeCard.weighted({
    super.key,
    required this.grade,
    required Widget this.weightControl,
    this.backgroundColor = CupertinoColors.systemBackground,
    this.weightIncluded = true,
    this.onWeightIncludedChanged,
  });

  @override
  Widget build(BuildContext context) {
    var brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.of(context).platformBrightness;

    Widget buildCard({bool highlighted = true, ValueChanged<bool>? onSelect}) {
      return Container(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: brightness == Brightness.dark
              ? CupertinoColors.secondarySystemGroupedBackground
                  .resolveFrom(context)
              : CupertinoDynamicColor.resolve(backgroundColor, context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onWeightIncludedChanged == null
                  ? null
                  : () => onWeightIncludedChanged!(!highlighted),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  spacing: 8,
                  children: [
                    if (onSelect != null)
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: CupertinoCheckbox(
                          value: highlighted,
                          onChanged: (bool? value) {
                            if (value != null) {
                              onSelect(value);
                            }
                          },
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(grade.name,
                              style: const TextStyle(fontSize: 16)),
                          Text(
                            '${grade.realId} / ${grade.credit.toStringAsFixed(1)} 学分',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
                      child: Text(
                        '${grade.original} / ${grade.fivePoint.toStringAsFixed(1)}',
                        semanticsLabel:
                            '成绩 ${grade.original}，绩点 ${grade.fivePoint.toStringAsFixed(1)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 8,
              width:
                  max((context.width - 60) * (grade.fivePoint - 1.4) / 3.6, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: highlighted
                      ? themeAccent(context)
                      : CupertinoColors.systemGrey.resolveFrom(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (weightControl case final control?) ...[
              const SizedBox(height: 12),
              control,
            ],
          ],
        ),
      );
    }

    if (weightControl != null) {
      return buildCard(
        highlighted: weightIncluded,
        onSelect: onWeightIncludedChanged,
      );
    }

    final controller = Get.find<GradeDetailController>();
    void openCourse() => CourseDetailPage.open(context, grade.id);
    return Obx(() {
      final custom = controller.customGpaMode.value;
      final selected =
          !custom || (controller.customGpaSelected[grade.id] ?? false);
      void setSelected(bool value) {
        controller.customGpaSelected[grade.id] = value;
        controller.refreshCustomGpa();
      }

      final card = buildCard(
        highlighted: selected,
        onSelect: custom ? setSelected : null,
      );
      return CardAction(
        onTap: custom ? () => setSelected(!selected) : openCourse,
        onLongPress: custom ? openCourse : null,
        child: card,
      );
    });
  }
}
