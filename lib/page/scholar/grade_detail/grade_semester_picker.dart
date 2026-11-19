import 'dart:math' as math;

import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/design/semester_chips.dart';
import 'package:celechron/design/two_line_card.dart';
import 'package:celechron/model/semester.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class GradeSemesterPicker extends StatelessWidget {
  const GradeSemesterPicker({
    super.key,
    required this.semesters,
    required this.selectedIndex,
    required this.onSelected,
    this.selectionSummary,
    this.onLongPress,
    this.compactSingle = false,
  });

  final List<Semester> semesters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String Function(Semester)? selectionSummary;
  final ValueChanged<int>? onLongPress;
  final bool compactSingle;

  @override
  Widget build(BuildContext context) {
    if (semesters.isEmpty) return const SizedBox.shrink();
    final scaler = MediaQuery.textScalerOf(context);
    final height = 81 +
        (scaler.scale(18) - 18).clamp(0.0, double.infinity) +
        (scaler.scale(14) - 14).clamp(0.0, double.infinity);
    final width = compactSingle ? math.max(120.0, scaler.scale(120)) : 120.0;
    final picker = RoundRectangleCard(
      animate: false,
      child: SizedBox(
        height: height.toDouble(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: semesters.length,
          separatorBuilder: (_, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final semester = semesters[index];
            final selected = index == selectedIndex;
            Widget buildCard() => Semantics(
                  label: semester.name,
                  button: true,
                  selected: selected,
                  child: TwoLineCard(
                    animate: true,
                    withColoredFont: selected,
                    hideAccentBar: true,
                    mutedTint: true,
                    width: width,
                    title: shortSemesterLabel(semester.name),
                    content: selectionSummary?.call(semester) ??
                        '${semester.gpa[0].toStringAsFixed(2)}/${semester.credits.toStringAsFixed(1)}',
                    onTap: () => onSelected(index),
                    onLongPress:
                        onLongPress == null ? null : () => onLongPress!(index),
                    backgroundColor: selected
                        ? CustomCupertinoDynamicColors.cyan
                        : CupertinoColors.systemGrey5,
                  ),
                );
            return selectionSummary == null ? buildCard() : Obx(buildCard);
          },
        ),
      ),
    );
    if (!compactSingle || semesters.length != 1) return picker;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(width: width + 24, child: picker),
    );
  }
}
