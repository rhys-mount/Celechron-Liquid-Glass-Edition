import 'package:celechron/design/floating_filter_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:celechron/design/card_detail_line.dart';
import 'package:celechron/design/content_empty_state.dart';

import 'package:get/get.dart';

import 'package:celechron/model/exam.dart';
import 'package:celechron/design/sub_title.dart';
import 'package:celechron/design/persistent_headers.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/design/semester_chips.dart';

import 'exam_list_controller.dart';

class ExamListPage extends StatefulWidget {
  final String initialSemesterName;

  const ExamListPage({required this.initialSemesterName, super.key});

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  late final ExamListController _examListController;

  @override
  void initState() {
    super.initState();
    Get.delete<ExamListController>();
    _examListController =
        Get.put(ExamListController(initialName: widget.initialSemesterName));
  }

  @override
  void dispose() {
    // 离开页面即释放 controller，onClose 里会取消定时器
    Get.delete<ExamListController>();
    super.dispose();
  }

  Widget _examCard(BuildContext context, List<Exam> exams) {
    final first = exams.first;
    final clock = DateFormat('HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SubSubtitleRow(
            subtitle: first.time.isEmpty ? '日期待定' : first.chineseDate),
        RoundRectangleCard(
          animate: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, exam) in exams.indexed) ...[
                if (index > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ColoredBox(
                      color: CupertinoColors.separator.resolveFrom(context),
                      child: const SizedBox(width: double.infinity, height: 1),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        exam.type == ExamType.midterm
                            ? CupertinoIcons.circle_fill
                            : CupertinoIcons.square_fill,
                        color: CupertinoColors.systemPink.resolveFrom(context),
                        size: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        exam.type == ExamType.midterm
                            ? '${exam.name}（期中）'
                            : exam.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                CardDetailLine(
                  CupertinoIcons.clock,
                  exam.time.length < 2
                      ? '时间待定'
                      : '${clock.format(exam.time.first)} – ${clock.format(exam.time.last)}',
                ),
                CardDetailLine(
                    CupertinoIcons.location, '地点 ${exam.location ?? '未知'}'),
                CardDetailLine(
                    CupertinoIcons.person, '座位 ${exam.seat ?? '未知'}'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _semesterPicker(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final warningBackground =
        dark ? const Color(0xFF471F23) : const Color(0xFFFFE8E7);
    final warningForeground =
        dark ? const Color(0xFFFFB4B0) : const Color(0xFF9B241F);
    return SliverFloatingFilterPanel(
      childOpacity: 0.97,
      banner: DecoratedBox(
        decoration: BoxDecoration(
          color: warningBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            spacing: 4,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                color: warningForeground,
                size: 14,
              ),
              Flexible(
                child: Text('请务必前往教务网核对',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: warningForeground,
                    )),
              ),
            ],
          ),
        ),
      ),
      child: Obx(
        () => SemesterChips(
          names: [
            for (final semester in _examListController.semesters) semester.name
          ],
          selectedIndex: _examListController.selectedIndex,
          onSelected: (index) {
            _examListController.semesterIndex.value = index;
            _examListController.semesterIndex.refresh();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGroupedBackground, context),
      child: CustomScrollView(
        slivers: [
          const CelechronSliverTextHeader(
            subtitle: '考试',
          ),
          _semesterPicker(context),
          Obx(() {
            final exams = _examListController.exams;
            if (exams.isEmpty) {
              return const SliverToBoxAdapter(
                child: ContentEmptyState(
                  icon: CupertinoIcons.calendar,
                  title: '本学期暂无考试',
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, MediaQuery.paddingOf(context).bottom + 12),
              sliver: SliverList.builder(
                itemCount: exams.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _examCard(context, exams[index]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
