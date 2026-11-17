// Official packages
import 'package:extended_sliver/extended_sliver.dart';
import 'package:flutter/cupertino.dart';
import 'package:celechron/page/scholar/course_list/course_brief_card.dart';
import 'package:celechron/design/content_empty_state.dart';
import 'package:get/get.dart';

import 'search_controller.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});

  final _searchController = Get.put(SearchPageController());

  @override
  Widget build(BuildContext context) {
    final background = CupertinoDynamicColor.resolve(
        CupertinoColors.systemGroupedBackground, context);
    return CupertinoPageScaffold(
        backgroundColor: background,
        child: SafeArea(
            child: CustomScrollView(slivers: [
          SliverPinnedToBoxAdapter(
            child: ColoredBox(
              color: background,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: CupertinoSearchTextField(
                        placeholder: '搜索课程、事项...',
                        placeholderStyle: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                                color: CupertinoColors.systemGrey,
                                height: 1.25,
                                fontSize: 18),
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(height: 1.25, fontSize: 18),
                        borderRadius: BorderRadius.circular(12),
                        itemColor: CupertinoColors.systemGrey,
                        itemSize: 20,
                        suffixInsets:
                            const EdgeInsetsDirectional.fromSTEB(0, 0, 5, 0),
                        prefixInsets:
                            const EdgeInsetsDirectional.fromSTEB(10, 0, 0, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        onChanged: (String value) {
                          _searchController.searchWord.value = value;
                        },
                        autofocus: true,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            final courses = _searchController.courseResult;
            if (courses.isEmpty &&
                _searchController.searchWord.value.isNotEmpty) {
              return const SliverToBoxAdapter(
                child: ContentEmptyState(
                  icon: CupertinoIcons.search,
                  title: '没有匹配的课程',
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
        ])));
  }
}
