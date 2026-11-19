// Official packages
import 'package:celechron/page/scholar/todo/todo_card.dart';
import 'package:celechron/http/zjuServices/exceptions.dart';
import 'package:celechron/utils/platform_features.dart';
import 'package:celechron/design/floating_filter_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:celechron/design/liquid_glass/home_scroll_insets.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Custom widgets and colors
import 'package:celechron/design/multiple_columns.dart';
import 'package:celechron/design/two_line_card.dart';
import 'package:celechron/design/round_rectangle_card.dart';
import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/design/semester_chips.dart';
import 'package:celechron/design/refresh_status_indicator.dart';
import 'package:celechron/design/rolling_shimmer_text.dart';

import 'package:celechron/page/search/search_view.dart';
import 'course_list/course_list_view.dart';
import 'course_schedule/course_hours_cards.dart';
import 'course_schedule/course_schedule_view.dart';
import 'exam_list/exam_list_view.dart';
import 'grade_detail/grade_detail_view.dart';
import 'practice_score/practice_score_page.dart';
import 'scholar_controller.dart';
import 'package:celechron/page/option/option_controller.dart';

Future<void> showRefreshResultDialog(
    BuildContext context, List<String?> results) async {
  final messages = results.whereType<String>().toList();
  // 完全成功只通过数据、更新时间和页面状态反馈，不主动打断用户。
  if (messages.isEmpty) return;
  final degraded =
      messages.where(isDegradedRefreshText).toList(growable: false);
  final failures = messages
      .where((message) => !isDegradedRefreshText(message))
      .toList(growable: false);
  if (!context.mounted) return;
  final summaryLines = messages.map((error) {
    final compact =
        shortErrorText(error).replaceAll(RegExp(r'\s+'), ' ').trim();
    final prefix = isDegradedRefreshText(error) ? '沿用已有数据：' : '失败：';
    final line = '$prefix$compact';
    return line.length <= 100 ? line : '${line.substring(0, 100)}…';
  }).toList();

  await showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(
        '刷新遇到问题：${degraded.length} 项降级，${failures.length} 项失败',
      ),
      content: Text(summaryLines.join('\n')),
      actions: [
        if (messages.isNotEmpty)
          CupertinoDialogAction(
            child: const Text('查看详情'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showCupertinoDialog<void>(
                context: context,
                builder: (detailContext) => CupertinoAlertDialog(
                  title: const Text('刷新详情'),
                  content: SingleChildScrollView(
                    child: Text(
                      messages.map((error) {
                        final short = shortErrorText(error);
                        final details = detailedErrorText(error);
                        return details == short ? short : '$short\n$details';
                      }).join('\n\n'),
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('确定'),
                      onPressed: () => Navigator.of(detailContext).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        CupertinoDialogAction(
          child: const Text('确定'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

class ScholarPage extends StatelessWidget {
  ScholarPage({super.key});

  final _scholarController = Get.put(ScholarController());
  final ValueNotifier<bool> _isRefreshing = ValueNotifier(false);

  // 让页内横向列表在桌面端也响应鼠标拖动。外层 PageView 为支持鼠标切页开启了
  // 鼠标拖动，横向列表若不响应鼠标，拖动会漏到 PageView 上造成误切页；
  // 内层可滚动组件在手势竞技中优先，包上后拖动由列表自己消费（触屏行为不变）
  Widget _mouseDraggable(BuildContext context, Widget child) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        dragDevices: {
          ...ScrollConfiguration.of(context).dragDevices,
          PointerDeviceKind.mouse,
        },
      ),
      child: child,
    );
  }

  Widget _refreshHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Duration age,
  }) {
    return _moduleHeader(
      context,
      title: title,
      icon: icon,
      detail: age.inMinutes > 10000000 ? '尚未同步' : '更新于 ${age.inMinutes} 分钟前',
      highlighted: age.inMinutes >= 5,
    );
  }

  Widget _moduleHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? detail,
    required bool highlighted,
  }) {
    final foreground = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 7,
        children: [
          Icon(icon, size: 17, color: foreground),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (detail != null)
            Expanded(
              child: Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    highlighted
                        ? CupertinoIcons.exclamationmark_circle
                        : CupertinoIcons.check_mark_circled,
                    size: 14,
                    color: secondary,
                  ),
                  Flexible(
                    child: Text(
                      detail,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradeBrief(BuildContext context) {
    final optionController =
        Get.find<OptionController>(tag: 'optionController');

    String maskGPA(String s) {
      // 绩点隐藏功能
      if (!optionController.hideHomeGpa) return s;
      return s.replaceAll('.', '').replaceAll(RegExp(r'[\d.]'), '*');
    }

    return RoundRectangleCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Hero(
                        tag: 'gradeBrief',
                        child: RoundRectangleCardWithForehead(
                            foreheadColor: CustomCupertinoDynamicColors
                                .okGreen.darkColor
                                .withValues(alpha: 0.13),
                            forehead: Obx(() => _refreshHeader(
                                  context,
                                  title: '成绩',
                                  icon: CupertinoIcons.chart_bar,
                                  age: _scholarController
                                      .durationToLastUpdateGrade,
                                )),
                            onTap: () async =>
                                Navigator.of(context, rootNavigator: true).push(
                                    CupertinoPageRoute(
                                        builder: (context) => GradeDetailPage(),
                                        fullscreenDialog: true)),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Obx(() => TwoLineCard(
                                          mutedTint: true,
                                          title: '五分制',
                                          content: maskGPA(_scholarController
                                              .gpa[0]
                                              .toStringAsFixed(2)),
                                          backgroundColor:
                                              CustomCupertinoDynamicColors
                                                  .cyan)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Obx(() => TwoLineCard(
                                          mutedTint: true,
                                          title: '获得学分',
                                          content: maskGPA(_scholarController
                                              .scholar.credit
                                              .toStringAsFixed(1)),
                                          backgroundColor:
                                              CustomCupertinoDynamicColors
                                                  .peach)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Obx(() => TwoLineCard(
                                          mutedTint: true,
                                          title: '四分制',
                                          content: maskGPA(_scholarController
                                              .gpa[1]
                                              .toStringAsFixed(2)),
                                          extraContent: maskGPA(
                                              _scholarController.gpa[2]
                                                  .toStringAsFixed(2)),
                                          backgroundColor:
                                              CustomCupertinoDynamicColors
                                                  .spring)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Obx(() => TwoLineCard(
                                          mutedTint: true,
                                          title: '主修均绩',
                                          content: maskGPA(_scholarController
                                              .scholar.majorGpaAndCredit[0]
                                              .toStringAsFixed(2)),
                                          backgroundColor:
                                              CustomCupertinoDynamicColors
                                                  .sakura)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Obx(() => TwoLineCard(
                                          mutedTint: true,
                                          title: '主修学分',
                                          content: maskGPA(_scholarController
                                              .scholar.majorGpaAndCredit[1]
                                              .toStringAsFixed(1)),
                                          backgroundColor:
                                              CustomCupertinoDynamicColors
                                                  .sand)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Obx(() => TwoLineCard(
                                          mutedTint: true,
                                          title: '百分制',
                                          content: maskGPA(_scholarController
                                              .gpa[3]
                                              .toStringAsFixed(2)),
                                          backgroundColor:
                                              CustomCupertinoDynamicColors
                                                  .magenta)),
                                    ),
                                  ],
                                ),
                              ],
                            )))),
              ],
            ),
          ],
        ));
  }

  Widget _buildSemester(BuildContext context) {
    return RoundRectangleCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: RoundRectangleCardWithForehead(
                        animate: false,
                        foreheadColor: CustomCupertinoDynamicColors
                            .cyan.darkColor
                            .withValues(alpha: 0.13),
                        forehead: Obx(() => _refreshHeader(
                              context,
                              title: '课程',
                              icon: CupertinoIcons.calendar,
                              age:
                                  _scholarController.durationToLastUpdateCourse,
                            )),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            MultipleColumns(
                              contents: [
                                Text(
                                    _scholarController
                                        .selectedSemester.courses.length
                                        .toString(),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .navTitleTextStyle
                                        .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                Text(
                                    _scholarController
                                        .selectedSemester.courseCredit
                                        .toString(),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .navTitleTextStyle
                                        .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                Text(
                                    _scholarController
                                        .selectedSemester.examCount
                                        .toString(),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .navTitleTextStyle
                                        .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                              ],
                              titles: const ['课程', '学分', '考试'],
                              onTaps: [
                                () => Navigator.of(context, rootNavigator: true)
                                    .push(CupertinoPageRoute(
                                        builder: (context) => CourseListPage(
                                            initialSemesterName:
                                                _scholarController
                                                    .selectedSemester.name),
                                        title: '课程')),
                                null,
                                () => Navigator.of(context, rootNavigator: true)
                                    .push(CupertinoPageRoute(
                                        builder: (context) => ExamListPage(
                                            initialSemesterName:
                                                _scholarController
                                                    .selectedSemester.name),
                                        title: '考试'))
                              ],
                            ),
                            const SizedBox(height: 16),
                            CourseHoursCards(
                              semester: _scholarController.selectedSemester,
                              onSelect: (first) {
                                final semester =
                                    _scholarController.selectedSemester;
                                Navigator.of(context, rootNavigator: true).push(
                                  CupertinoPageRoute(
                                    builder: (_) => CourseSchedulePage(
                                        semester.name, first),
                                    title: '课表',
                                  ),
                                );
                              },
                            ),
                          ],
                        ))),
              ],
            ),
          ],
        ));
  }

  Widget _buildTodos(BuildContext context) {
    return RoundRectangleCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: RoundRectangleCardWithForehead(
                        animate: false,
                        foreheadColor: CustomCupertinoDynamicColors
                            .magenta.darkColor
                            .withValues(alpha: 0.13),
                        forehead: Obx(() => _refreshHeader(
                              context,
                              title: '作业',
                              icon: CupertinoIcons.check_mark_circled,
                              age: _scholarController
                                  .durationToLastUpdateHomework,
                            )),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            MultipleColumns(
                              contents: [
                                Text(_scholarController.todos.length.toString(),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .navTitleTextStyle
                                        .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                Text(
                                    _scholarController.todosInOneDay.length
                                        .toString(),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .navTitleTextStyle
                                        .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                Text(
                                    _scholarController.todosInOneWeek.length
                                        .toString(),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .navTitleTextStyle
                                        .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                              ],
                              titles: const ["总计", "一天内", "本周截止"],
                              onTaps: const [null, null, null],
                            ),
                            const SizedBox(height: 16),
                            if (_scholarController.todos.isNotEmpty)
                              SizedBox(
                                  height: MediaQuery.textScalerOf(context)
                                      .scale(136),
                                  child: _mouseDraggable(
                                      context,
                                      ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              _scholarController.todos.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(width: 8),
                                          itemBuilder: (context, index) {
                                            final todo =
                                                _scholarController.todos[index];
                                            return SizedBox(
                                                width: MediaQuery.textScalerOf(
                                                        context)
                                                    .scale(200)
                                                    .clamp(200.0, 280.0),
                                                child: TodoCard(todo: todo));
                                          })))
                          ],
                        ))),
              ],
            ),
          ],
        ));
  }

  Widget _buildPractice(BuildContext context) {
    return RoundRectangleCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: RoundRectangleCardWithForehead(
                        animate: false,
                        foreheadColor: CustomCupertinoDynamicColors
                            .peach.darkColor
                            .withValues(alpha: 0.13),
                        forehead: Obx(() {
                          final available =
                              _scholarController.scholar.isPracticeScoresGet;
                          return _moduleHeader(
                            context,
                            title: '实践',
                            icon: CupertinoIcons.star,
                            detail: available ? null : '获取实践记点时遇到问题',
                            highlighted: !available,
                          );
                        }),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Obx(
                              () => PracticeScoreColumns(
                                scholar: _scholarController.scholar,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ))),
              ],
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        /*backgroundColor: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGroupedBackground, context),*/
        child: CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('学业'),
          border: null,
        ),
        Obx(() {
          if (!_scholarController.scholar.isLogan) {
            return const SliverToBoxAdapter();
          }
          return CupertinoSliverRefreshControl(
            builder: (context, refreshState, pulledExtent,
                    refreshTriggerPullDistance, refreshIndicatorExtent) =>
                Obx(() => RefreshStatusIndicator(
                      refreshState: refreshState,
                      pulledExtent: pulledExtent,
                      refreshTriggerPullDistance: refreshTriggerPullDistance,
                      refreshIndicatorExtent: refreshIndicatorExtent,
                      message: _scholarController.refreshStatusMessage.value,
                    )),
            onRefresh: () async {
              final results = await _scholarController.fetchData();
              if (context.mounted && results.any((result) => result != null)) {
                await showRefreshResultDialog(context, results);
              }
            },
          );
        }),
        SliverFloatingFilterPanel(
          child: Column(children: [
            Row(
              children: [
                const Expanded(child: CourseSearchLauncher()),
                if (PlatformFeatures.isDesktop)
                  ValueListenableBuilder(
                      valueListenable: _isRefreshing,
                      builder: (context, isRefreshing, child) =>
                          CupertinoButton(
                            onPressed: isRefreshing
                                ? null
                                : () async {
                                    _isRefreshing.value = true;
                                    late final List<String?> results;
                                    try {
                                      results =
                                          await _scholarController.fetchData();
                                    } finally {
                                      _isRefreshing.value = false;
                                    }
                                    if (context.mounted &&
                                        results
                                            .any((result) => result != null)) {
                                      await showRefreshResultDialog(
                                          context, results);
                                    }
                                  },
                            child: isRefreshing
                                ? const CupertinoActivityIndicator()
                                : Icon(
                                    CupertinoIcons.refresh,
                                    color: CupertinoDynamicColor.resolve(
                                        CupertinoColors.systemBlue, context),
                                    size: 20,
                                  ),
                          ))
              ],
            ),
            Obx(() {
              final semesters = _scholarController.semesters;
              if (semesters.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _mouseDraggable(
                  context,
                  SemesterChips(
                    names: [for (final semester in semesters) semester.name],
                    selectedIndex: _scholarController.semesterIndex.value,
                    onSelected: (index) {
                      _scholarController.semesterIndex.value = index;
                      _scholarController.semesterIndex.refresh();
                    },
                  ),
                ),
              );
            }),
            // 桌面端刷新超过 5 秒后的状态条：小转圈 + 滚动文案，随刷新结束收起。
            // 移动端的状态文案由下方 CupertinoSliverRefreshControl 的 builder 展示
            if (PlatformFeatures.isDesktop)
              Obx(() {
                final message = _scholarController.refreshStatusMessage.value;
                return AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  // AnimatedSwitcher 让收起时末条文案先淡出、条带再合拢，
                  // 而不是内容瞬间消失
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: message == null
                        ? const SizedBox(
                            key: ValueKey('refreshStatusStripEmpty'),
                            width: double.infinity)
                        : Padding(
                            key: const ValueKey('refreshStatusStrip'),
                            padding: const EdgeInsets.only(top: 6, bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CupertinoActivityIndicator(radius: 7),
                                const SizedBox(width: 6),
                                Flexible(child: RollingShimmerText(message)),
                              ],
                            ),
                          ),
                  ),
                );
              }),
          ]),
        ),
        SliverToBoxAdapter(
          child: Obx(() {
            if (_scholarController.scholar.semesters.isNotEmpty) {
              return Padding(
                padding: EdgeInsets.only(
                    top: 8,
                    right: 16,
                    left: 16,
                    bottom: MediaQuery.paddingOf(context).bottom + 4),
                child: Column(
                  children: _scholarController.scholar.isGrs
                      ? [
                          const SizedBox(height: 12),
                          _buildSemester(context),
                          const SizedBox(height: 12),
                          Divider(
                            thickness: 0,
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.separator, context),
                            height: 14,
                          ),
                          const SizedBox(height: 12),
                          _buildTodos(context),
                        ]
                      : [
                          _buildGradeBrief(context),
                          const SizedBox(height: 12),
                          Divider(
                            thickness: 0,
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.separator, context),
                            height: 14,
                          ),
                          const SizedBox(height: 12),
                          _buildSemester(context),
                          const SizedBox(height: 12),
                          Divider(
                            thickness: 0,
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.separator, context),
                            height: 14,
                          ),
                          const SizedBox(height: 12),
                          _buildTodos(context),
                          const SizedBox(height: 12),
                          Divider(
                            thickness: 0,
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.separator, context),
                            height: 14,
                          ),
                          const SizedBox(height: 12),
                          _buildPractice(context),
                          const SizedBox(height: 20),
                        ],
                ),
              );
            } else {
              return SizedBox(
                  height: 500,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Icon(
                          _scholarController.scholar.isLogan
                              ? CupertinoIcons.arrow_clockwise
                              : CupertinoIcons.person_crop_circle,
                          size: 48,
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.secondaryLabel, context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                            _scholarController.scholar.isLogan
                                ? '下拉刷新以获取数据'
                                : '未登录',
                            style:
                                CupertinoTheme.of(context).textTheme.textStyle),
                        if (_scholarController.scholar.isLogan)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '离线数据将在同步失败时自动使用',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoDynamicColor.resolve(
                                    CupertinoColors.secondaryLabel, context),
                              ),
                            ),
                          ),
                        const Spacer()
                      ]));
            }
          }),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: HomeScrollInsets.bottomOf(context)),
        ),
      ],
    ));
  }
}
