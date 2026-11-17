import 'package:celechron/design/card_detail_line.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/model/course.dart';
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
    final grade = course.grade;
    final primary = CupertinoTheme.of(context).primaryColor;
    final content = Column(
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
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              course.credit > 0
                  ? '${course.credit.toStringAsFixed(1)} 学分'
                  : '待更新',
              style: TextStyle(
                fontSize: 13,
                color: course.credit > 0
                    ? primary
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
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
            if (grade != null)
              CardDetailLine(
                CupertinoIcons.checkmark_seal,
                '成绩 ${grade.original.isEmpty ? grade.hundredPoint : grade.original}'
                ' / ${grade.original.isEmpty ? 100 : grade.fivePoint.toStringAsFixed(1)}',
              ),
            if (course.online == true)
              const CardDetailLine(CupertinoIcons.globe, '线上课程'),
            if (course.type case final type?)
              CardDetailLine(CupertinoIcons.tag, type),
          ],
        ),
      ],
    );

    return RoundRectangleCard.content(
      animate: false,
      onTap: allowDirect
          ? () => Navigator.of(context).push(CupertinoPageRoute<void>(
                builder: (_) => CourseDetailPage(courseId: course.id),
              ))
          : null,
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
