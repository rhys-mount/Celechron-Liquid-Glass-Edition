import 'package:celechron/design/card_detail_line.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/model/course.dart';
import 'package:celechron/model/grade.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'package:flutter/cupertino.dart';

class CourseBriefCard extends StatelessWidget {
  const CourseBriefCard({
    required this.course,
    this.allowDirect = false,
    super.key,
  });

  final Course course;
  final bool allowDirect;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(CupertinoIcons.circle_fill,
                  size: 8, color: CupertinoColors.systemTeal),
            ),
            Expanded(
              child: Text(
                course.name,
                maxLines: allowDirect ? 2 : null,
                overflow: allowDirect ? TextOverflow.ellipsis : null,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
        CardDetailLine(CupertinoIcons.number, '课号 ${course.realId}'),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            CardDetailLine(
                CupertinoIcons.person, '教师 ${course.teacher ?? '未知'}'),
            if (course.online == true)
              const CardDetailLine(CupertinoIcons.globe, '线上课程'),
            if (course.type case final type?)
              CardDetailLine(CupertinoIcons.tag, type),
          ],
        ),
      ],
    );

    final content = LayoutBuilder(
      builder: (context, constraints) => Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: details),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
            child: _CourseCreditAndGrade(
              credit: course.credit,
              grade: course.grade,
            ),
          ),
        ],
      ),
    );

    return RoundRectangleCard.content(
      animate: false,
      onTap:
          allowDirect ? () => CourseDetailPage.open(context, course.id) : null,
      child: allowDirect
          ? Row(
              spacing: 8,
              children: [
                Expanded(child: content),
                const CupertinoListTileChevron()
              ],
            )
          : content,
    );
  }
}

class _CourseCreditAndGrade extends StatelessWidget {
  const _CourseCreditAndGrade({required this.credit, required this.grade});

  final double credit;
  final Grade? grade;

  @override
  Widget build(BuildContext context) {
    final grade = this.grade;
    final theme = CupertinoTheme.of(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final scoreStyle = theme.textTheme.textStyle.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final secondaryStyle = scoreStyle.copyWith(fontSize: 13, color: secondary);
    final useHundredPoint = grade?.original.isEmpty ?? false;
    final score = grade == null
        ? null
        : useHundredPoint
            ? '${grade.hundredPoint}'
            : grade.original;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          credit > 0 ? '${credit.toStringAsFixed(1)} 学分' : '待更新',
          textAlign: TextAlign.end,
          style: secondaryStyle,
        ),
        if (score != null && grade != null) ...[
          const SizedBox(height: 4),
          Text(
            score,
            semanticsLabel: '成绩 $score',
            textAlign: TextAlign.end,
            style: scoreStyle.copyWith(
              fontSize: 25,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: CupertinoDynamicColor.resolve(theme.primaryColor, context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            useHundredPoint
                ? '满分 100'
                : '绩点 ${grade.fivePoint.toStringAsFixed(1)}',
            textAlign: TextAlign.end,
            style: secondaryStyle.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }
}
