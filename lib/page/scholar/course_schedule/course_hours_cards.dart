import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/design/two_line_card.dart';
import 'package:celechron/model/semester.dart';
import 'package:flutter/cupertino.dart';

class CourseHoursCards extends StatelessWidget {
  const CourseHoursCards({
    super.key,
    required this.semester,
    required this.onSelect,
    this.selectedFirstHalf,
  });

  final Semester semester;
  final ValueChanged<bool> onSelect;
  final bool? selectedFirstHalf;

  @override
  Widget build(BuildContext context) {
    final spring = semester.firstHalfName == '春';

    Widget card(
        bool first, String name, double hours, CupertinoDynamicColor color) {
      return Expanded(
        child: TwoLineCard(
          animate: true,
          width: double.infinity,
          onTap: () => onSelect(first),
          title: '$name学期课时',
          content: '$hours节/两周',
          backgroundColor:
              selectedFirstHalf == null || selectedFirstHalf == first
                  ? color
                  : CupertinoColors.systemFill,
          withColoredFont: true,
        ),
      );
    }

    return Row(
      spacing: 8,
      children: [
        card(
            true,
            semester.firstHalfName,
            semester.firstHalfSessionCount,
            spring
                ? CustomCupertinoDynamicColors.spring
                : CustomCupertinoDynamicColors.autumn),
        card(
            false,
            semester.secondHalfName,
            semester.secondHalfSessionCount,
            spring
                ? CustomCupertinoDynamicColors.summer
                : CustomCupertinoDynamicColors.winter),
      ],
    );
  }
}
