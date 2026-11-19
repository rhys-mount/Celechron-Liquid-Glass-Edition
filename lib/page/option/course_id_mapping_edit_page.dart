import 'package:celechron/design/action_dialogs.dart';
import 'package:celechron/design/content_empty_state.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:celechron/design/persistent_headers.dart';
import 'package:celechron/model/option.dart';
import 'option_controller.dart';

class CourseIdMappingEditForm extends StatefulWidget {
  const CourseIdMappingEditForm({super.key, required this.title});

  final String title;

  @override
  State<CourseIdMappingEditForm> createState() =>
      _CourseIdMappingEditFormState();
}

class _CourseIdMappingEditFormState extends State<CourseIdMappingEditForm> {
  final _form = GlobalKey<FormState>();
  final _oldId = TextEditingController();
  final _newId = TextEditingController();
  final _comment = TextEditingController();
  final _option = Get.find<OptionController>(tag: 'optionController');
  bool _saving = false;

  @override
  void dispose() {
    _oldId.dispose();
    _newId.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final oldId = _oldId.text.trim();
    final newId = _newId.text.trim();
    final comment = _comment.text.trim();
    final mappings = _option.courseIdMappingList;
    bool conflicts(CourseIdMap entry) =>
        entry.id1 == oldId ||
        entry.id2 == oldId ||
        entry.id1 == newId ||
        entry.id2 == newId;
    setState(() => _saving = true);
    if (mappings.any(conflicts)) {
      final confirmed = await confirmDestructiveAction(
        context,
        title: '替换现有映射？',
        message: '已有使用相同课号的映射将被替换。',
        action: '替换并保存',
      );
      if (!mounted) return;
      if (!confirmed) {
        setState(() => _saving = false);
        return;
      }
    }
    mappings.removeWhere(conflicts);
    mappings.add(CourseIdMap(id1: oldId, id2: newId, comment: comment));
    Navigator.of(context).pop();
    await _option.scholar.value.recalculateGpa();
    _option.scholar.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(widget.title,
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .navTitleTextStyle)),
                      CupertinoButton(
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    margin: const EdgeInsets.only(bottom: 16),
                    children: [
                      _field('原课号', _oldId),
                      _field('新课号', _newId),
                      _field('备注名', _comment, last: true),
                    ],
                  ),
                  CupertinoButton.filled(
                    onPressed: _saving ? null : _save,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool last = false}) {
    return CupertinoTextFormFieldRow(
      controller: controller,
      decoration: const BoxDecoration(),
      prefix: Text(label),
      placeholder: '请输入$label',
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _save() : null,
      validator: (value) =>
          value == null || value.trim().isEmpty ? '请填写$label' : null,
    );
  }
}

class CourseIdMappingEditPage extends StatelessWidget {
  final courseIdMappingList =
      Get.find<OptionController>(tag: 'optionController').courseIdMappingList;
  final scholar = Get.find<OptionController>(tag: 'optionController').scholar;

  CourseIdMappingEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            const CelechronSliverTextHeader(subtitle: '自定义课程代码映射'),
            Obx(() => courseIdMappingList.isEmpty
                ? const SliverToBoxAdapter(
                    child: ContentEmptyState(
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    title: '暂无课程代码映射',
                  ))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (context, index) => Container(
                              padding: index == 0
                                  ? const EdgeInsets.only(
                                      top: 0, bottom: 5, left: 16, right: 16)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 5),
                              child: CupertinoFormRow(
                                prefix: Text(
                                    '${courseIdMappingList[index].comment}： ${courseIdMappingList[index].id1} <-> ${courseIdMappingList[index].id2}',
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final mapping =
                                            courseIdMappingList[index];
                                        final confirmed =
                                            await confirmDestructiveAction(
                                          context,
                                          title: '删除课程代码映射？',
                                          message: mapping.comment,
                                          action: '删除',
                                        );
                                        if (!confirmed || !context.mounted)
                                          return;
                                        courseIdMappingList.remove(mapping);
                                        await scholar.value.recalculateGpa();
                                        scholar.refresh();
                                      },
                                      child: const Icon(
                                        CupertinoIcons.delete,
                                        semanticLabel: '删除映射',
                                        color: CupertinoColors.destructiveRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        childCount: courseIdMappingList.length),
                  )),
            SliverToBoxAdapter(
                child: Column(
              children: [
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: () async {
                    showCupertinoModalPopup(
                        context: context,
                        builder: (BuildContext context) {
                          return const CourseIdMappingEditForm(
                              title: '添加新的映射关系');
                        });
                  },
                  child: const Text('添加新的映射关系'),
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
