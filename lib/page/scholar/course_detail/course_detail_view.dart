import 'package:celechron/design/card_detail_line.dart';
import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/design/persistent_headers.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/model/course.dart';
import 'package:celechron/model/exam.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/page/scholar/course_list/course_brief_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class CourseDetailPage extends StatelessWidget {
  final _scholar = Get.find<Rx<Scholar>>(tag: 'scholar');
  late final Course course;

  CourseDetailPage({required courseId, super.key}) {
    course = _scholar.value.semesters
        .firstWhere((e) => e.courses.containsKey(courseId))
        .courses[courseId]!;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = [...course.sessions]..sort(
        (a, b) => (a.time.firstOrNull ?? 0).compareTo(b.time.firstOrNull ?? 0));

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        slivers: [
          const CelechronSliverTextHeader(subtitle: '课程详情'),
          SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            sliver: SliverList.list(children: [
              _CourseSection(
                  title: '基本信息', child: CourseBriefCard(course: course)),
              if (sessions.isNotEmpty)
                _CourseSection(
                  title: '课时',
                  child: _CourseRows(
                    rows: [
                      for (final session in sessions)
                        _CourseRow(
                          title: session.chineseTime,
                          color: TimeColors.colorFromClass(
                              session.time.firstOrNull ?? 0),
                          details: [
                            CardDetailLine(CupertinoIcons.location,
                                '地点 ${session.location ?? '未知'}'),
                          ],
                        ),
                    ],
                  ),
                ),
              if (course.exams.isNotEmpty)
                _CourseSection(
                  title: '考试',
                  child: _CourseRows(
                    rows: [
                      for (final exam in course.exams)
                        _CourseRow(
                          title: exam.chineseTime,
                          color:
                              CupertinoColors.systemPink.resolveFrom(context),
                          marker: exam.type == ExamType.midterm
                              ? CupertinoIcons.circle_fill
                              : CupertinoIcons.square_fill,
                          details: [
                            CardDetailLine(CupertinoIcons.location,
                                '地点 ${exam.location ?? '未知'}'),
                            CardDetailLine(CupertinoIcons.person,
                                '座位 ${exam.seat ?? '未知'}'),
                            if (exam.type == ExamType.midterm)
                              const CardDetailLine(
                                  CupertinoIcons.doc_text, '类型 期中'),
                          ],
                        ),
                    ],
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CourseSection extends StatelessWidget {
  const _CourseSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CourseRows extends StatelessWidget {
  const _CourseRows({required this.rows});

  final List<_CourseRow> rows;

  @override
  Widget build(BuildContext context) {
    return RoundRectangleCard.content(
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index != 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 1,
                  child: ColoredBox(
                      color: CupertinoColors.separator.resolveFrom(context)),
                ),
              ),
            row,
          ],
        ],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.title,
    required this.color,
    required this.details,
    this.marker = CupertinoIcons.circle_fill,
  });

  final String title;
  final Color color;
  final IconData marker;
  final List<CardDetailLine> details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Icon(marker, size: 10, color: color),
            ),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        ...details,
      ],
    );
  }
}
