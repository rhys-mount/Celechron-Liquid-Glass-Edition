import 'package:celechron/design/content_empty_state.dart';
import 'package:celechron/model/session.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'package:flutter/cupertino.dart';

class ScheduleSessionList extends StatelessWidget {
  const ScheduleSessionList({
    super.key,
    required this.days,
    this.hideDetails = false,
  });

  final List<List<Session>> days;
  final bool hideDetails;

  static bool prefersList(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) >= 19;

  @override
  Widget build(BuildContext context) {
    if (days.every((sessions) => sessions.isEmpty)) {
      return const ContentEmptyState(
        icon: CupertinoIcons.calendar,
        title: '这段时间暂无课程',
      );
    }
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var day = 1; day <= weekdays.length; day++)
          if (day < days.length && days[day].isNotEmpty)
            CupertinoListSection.insetGrouped(
              margin: const EdgeInsets.only(bottom: 12),
              header: Text('星期${weekdays[day - 1]}'),
              children: [
                for (final session in [
                  ...days[day],
                ]..sort((a, b) => (a.time.firstOrNull ?? 0)
                    .compareTo(b.time.firstOrNull ?? 0)))
                  CupertinoListTile.notched(
                    title: Text(hideDetails ? '课程' : session.name, maxLines: 4),
                    subtitle: Text(
                        [
                          if (session.time.isNotEmpty)
                            '第 ${session.time.join('、')} 节',
                          if (!hideDetails && session.location != null)
                            session.location!,
                        ].join(' · '),
                        maxLines: 3),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => CourseDetailPage.open(context, session.id),
                  ),
              ],
            ),
      ],
    );
  }
}
