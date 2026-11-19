import 'package:celechron/design/floating_filter_panel.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:celechron/page/scholar/course_list/course_brief_card.dart';
import 'package:celechron/design/persistent_headers.dart';
import 'package:celechron/design/semester_chips.dart';
import 'package:celechron/design/content_empty_state.dart';
import 'course_list_controller.dart';

class CourseListPage extends StatelessWidget {
  late final CourseListController _courseListController;

  CourseListPage({required String initialSemesterName, super.key}) {
    Get.delete<CourseListController>();
    _courseListController =
        Get.put(CourseListController(initialName: initialSemesterName));
  }

  Widget _semesterPicker() {
    return Obx(
      () => SemesterChips(
        names: [
          for (final semester in _courseListController.semesters) semester.name
        ],
        selectedIndex: _courseListController.semesterIndex.value,
        onSelected: (index) {
          _courseListController.semesterIndex.value = index;
          _courseListController.semesterIndex.refresh();
        },
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
          const CelechronSliverTextHeader(subtitle: '课程'),
          SliverFloatingFilterPanel(child: _semesterPicker()),
          Obx(() {
            final courses = _courseListController.courses;
            if (courses.isEmpty) {
              return const SliverToBoxAdapter(
                child: ContentEmptyState(
                  icon: CupertinoIcons.book,
                  title: '这个学期暂无课程',
                ),
              );
            }
            return SliverList.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: CourseBriefCard(
                  course: courses[index],
                  allowDirect: true,
                ),
              ),
            );
          }),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
          ),
        ],
      ),
    );
  }
}
