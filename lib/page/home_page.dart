import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:celechron/page/scholar/scholar_view.dart';
import 'package:celechron/page/flow/flow_view.dart';
import 'package:celechron/page/task/task_view.dart';
import 'package:celechron/page/calendar/calendar_view.dart';
import 'package:celechron/page/option/option_view.dart';
import 'package:celechron/design/liquid_glass/glass_appearance.dart';
import 'package:celechron/design/liquid_glass/home_scroll_insets.dart';
import 'package:celechron/design/liquid_glass/home_tab_bar.dart';

import 'package:celechron/worker/fuse.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _indexNum = 0;
  final PageController _pageController = PageController();

  // 只构建一次，保持各页 widget 身份稳定，切页时不会重跑各页构造器里的 Get.put
  late final List<Widget> _pages = [
    _KeepAlivePage(child: FlowPage()),
    _KeepAlivePage(child: CalendarPage()),
    _KeepAlivePage(child: TaskPage()),
    _KeepAlivePage(child: ScholarPage()),
    _KeepAlivePage(child: OptionPage()),
  ];

  @override
  void initState() {
    super.initState();
    initFuse();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = Get.find<GlassAppearance>();
    return Obx(() {
      final enabled = appearance.enabled.value;
      return _buildPage(context, useGlass: appearance.available && enabled);
    });
  }

  Widget _buildPage(BuildContext context, {required bool useGlass}) {
    final media = MediaQuery.of(context);
    final glassTabFits =
        useGlass && !media.disableAnimations && media.textScaler.scale(12) < 17;
    final showNavigation = media.viewInsets.bottom == 0;
    final railWidth = showNavigation &&
            useGlass &&
            defaultTargetPlatform == TargetPlatform.android
        ? homeNavigationRailWidth(media.size)
        : null;
    final tabBar = showNavigation && railWidth == null
        ? buildHomeTabBar(
            context,
            useGlass: glassTabFits,
            selectedIndex: _indexNum,
            onSelected: _pageController.jumpToPage,
          )
        : null;

    final ScrollBehavior scrollBehavior = ScrollConfiguration.of(context);
    // HeroMode 关闭：原先嵌套 CupertinoTabView 导航器会屏蔽标签页内的 Hero
    // 飞行动画（如学业页成绩卡片），这里显式关闭以保持原有行为
    final content = HeroMode(
      enabled: false,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (index != _indexNum) {
            setState(() {
              _indexNum = index;
            });
          }
        },
        // 允许鼠标拖动切页（与原 GestureDetector 行为一致），只作用于本 PageView，
        // 不影响页面内部列表；scrollbars 必须关掉，否则桌面端会叠一条横向滚动条
        scrollBehavior: scrollBehavior.copyWith(
          scrollbars: false,
          dragDevices: {
            ...scrollBehavior.dragDevices,
            PointerDeviceKind.mouse,
          },
        ),
        children: _pages,
      ),
    );

    // 玻璃栏覆盖滚动视口，列表只在滚动末尾为栏和系统手势区留空。
    var newMediaQuery = media.removeViewInsets(removeBottom: true);
    var scrollEnd = 0.0;
    var leadingSpace = 0.0;
    const railMargin = 12.0;
    if (tabBar != null) {
      final bottomPadding = tabBar.preferredSize.height + media.padding.bottom;
      if (glassTabFits) {
        scrollEnd = bottomPadding;
        newMediaQuery = newMediaQuery.removePadding(removeBottom: true);
      } else {
        newMediaQuery = newMediaQuery.copyWith(
          padding: newMediaQuery.padding.copyWith(bottom: bottomPadding),
        );
      }
    } else if (railWidth != null) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final safeInset = rtl ? media.padding.right : media.padding.left;
      leadingSpace = railWidth + railMargin * 2 + safeInset;
      newMediaQuery = newMediaQuery.removePadding(
        removeLeft: !rtl,
        removeRight: rtl,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          // 内容在下层，半透明标签栏的 BackdropFilter 才有内容可模糊
          MediaQuery(
            data: newMediaQuery,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: leadingSpace,
                bottom: media.viewInsets.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: railWidth == null ? double.infinity : 1040,
                  ),
                  child: HomeScrollInsets(bottom: scrollEnd, child: content),
                ),
              ),
            ),
          ),
          if (tabBar != null)
            Align(
              alignment: Alignment.bottomCenter,
              child:
                  glassTabFits ? SafeArea(top: false, child: tabBar) : tabBar,
            ),
          if (railWidth != null)
            Align(
              alignment: AlignmentDirectional.topStart,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(railMargin),
                  child: GlassHomeNavigationRail(
                    width: railWidth,
                    selectedIndex: _indexNum,
                    onSelected: _pageController.jumpToPage,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> initFuse() async {
    await Future.delayed(const Duration(seconds: 1));
    var fuse = Get.find<Rx<Fuse>>(tag: 'fuse');
    var response =
        await fuse.value.checkUpdate().whenComplete(() => fuse.refresh());
    if (response != null) {
      if (!mounted) return;
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('更新可用'),
              content: Text(response),
              actions: [
                CupertinoDialogAction(
                  child: const Text('忽略'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('访问网站'),
                  onPressed: () async {
                    await launchUrlString(
                      'https://celechron.top',
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            );
          });
    }
  }
}

// 离屏页面保活：保留滚动位置等临时状态，等价于原先 CupertinoTabScaffold
// 对已构建标签页的常驻行为
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
