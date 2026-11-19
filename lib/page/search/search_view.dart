import 'dart:math' as math;

import 'package:celechron/design/content_empty_state.dart';
import 'package:celechron/design/course_search_field.dart';
import 'package:celechron/page/scholar/course_list/course_brief_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'search_controller.dart';

class CourseSearchLauncher extends StatefulWidget {
  const CourseSearchLauncher({super.key});

  @override
  State<CourseSearchLauncher> createState() => _CourseSearchLauncherState();
}

class _CourseSearchLauncherState extends State<CourseSearchLauncher> {
  bool _inFlight = false;
  bool _hideSource = false;

  Future<void> _openSearch() async {
    if (_inFlight) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final field = context.findRenderObject()! as RenderBox;
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final origin =
        field.localToGlobal(Offset.zero, ancestor: overlay) & field.size;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final route = _CourseSearchRoute(origin, reduceMotion);
    _inFlight = true;
    try {
      final popped = navigator.push(route);
      final animation = route.motion;
      // Leave the original visible at the two ends of the transition.
      void syncSource() {
        final hidden = animation.value > 0;
        if (mounted && hidden != _hideSource) {
          setState(() => _hideSource = hidden);
        }
      }

      animation.addListener(syncSource);
      syncSource();
      await popped;
      await route.completed;
    } finally {
      _inFlight = false;
      if (mounted && _hideSource) setState(() => _hideSource = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !_hideSource,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: CourseSearchField.launcher(onPressed: _openSearch),
    );
  }
}

class _CourseSearchRoute extends PageRoute<void> {
  _CourseSearchRoute(this.origin, this.reduceMotion);

  final Rect origin;
  final bool reduceMotion;

  // ModalRoute temporarily reports a completed animation during Hero layout.
  // This search flight uses measured bounds rather than a Hero.
  Animation<double> get motion => controller!.view;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 340);

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 260);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      SearchPage(origin: origin, animation: motion);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.origin, this.animation});

  final Rect? origin;
  final Animation<double>? animation;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _focus = FocusNode();
  late final _search = Get.put(SearchPageController());
  late final _animation =
      widget.animation ?? const AlwaysStoppedAnimation<double>(1);

  @override
  void initState() {
    super.initState();
    _search.searchWord.value = '';
    widget.animation?.addStatusListener(_onStatus);
    if (_animation.value == 1) _focusAfterFrame();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _focusAfterFrame();
    if (status == AnimationStatus.reverse) _focus.unfocus();
  }

  void _focusAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _animation.value == 1 &&
          ModalRoute.of(context)?.isCurrent == true) {
        _focus.requestFocus();
      }
    });
  }

  void _cancel() {
    _focus.unfocus();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    widget.animation?.removeStatusListener(_onStatus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safe = media.viewPadding;
    final height = CourseSearchField.height(context);
    final background = CupertinoColors.systemBackground.resolveFrom(context);
    final input = CourseSearchField(
      focusNode: _focus,
      onChanged: (value) => _search.searchWord.value = value,
    );
    final cancel = Semantics(
      label: '取消',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _cancel,
        child: CourseSearchSurface(
          height: height,
          child: Center(
            child: Icon(CupertinoIcons.xmark,
                size: 19, color: CupertinoColors.label.resolveFrom(context)),
          ),
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
      child: LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth - safe.left - safe.right - 32)
            .clamp(0.0, 680.0);
        final left = safe.left +
            (constraints.maxWidth - safe.left - safe.right - width) / 2;
        final target = Rect.fromLTWH(
            left, safe.top + 8, math.max(0, width - height - 8), height);
        final origin = widget.origin ?? target;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, results) {
            final progress = _animation.value;
            final flight = Curves.easeInOutCubic.transform(progress);
            final fade = const Interval(0.05, 0.8, curve: Curves.easeInOut)
                .transform(progress);
            final reveal = const Interval(0.5, 1, curve: Curves.easeOut)
                .transform(progress);
            final settled = progress == 1;
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: background.withValues(alpha: fade)),
                Positioned(
                  top: target.bottom + 8,
                  left: left,
                  right: constraints.maxWidth - left - width,
                  bottom: math.max(media.viewInsets.bottom, safe.bottom),
                  child: IgnorePointer(
                    ignoring: !settled,
                    child: ExcludeSemantics(
                      excluding: !settled,
                      child: Opacity(opacity: reveal, child: results),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: Rect.lerp(origin, target, flight)!,
                  child: IgnorePointer(
                    ignoring: !settled,
                    child: ExcludeSemantics(
                      excluding: !settled,
                      child: Opacity(
                        opacity: progress == 0 && widget.origin != null ? 0 : 1,
                        child: input,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: target.top,
                  left: target.right + 8,
                  width: height,
                  height: height,
                  child: IgnorePointer(
                    ignoring: !settled,
                    child: ExcludeSemantics(
                      excluding: !settled,
                      child: Opacity(opacity: reveal, child: cancel),
                    ),
                  ),
                ),
              ],
            );
          },
          child: CustomScrollView(slivers: [_buildResults(context)]),
        );
      }),
    );
  }

  Widget _buildResults(BuildContext context) => Obx(() {
        final courses = _search.courseResult;
        if (_search.searchWord.value.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text('输入课程名称，查找已同步的课程。',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  )),
            ),
          );
        }
        if (courses.isEmpty) {
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
            padding: const EdgeInsets.only(bottom: 8),
            child: CourseBriefCard(
              course: courses[index],
              allowDirect: true,
            ),
          ),
        );
      });
}
