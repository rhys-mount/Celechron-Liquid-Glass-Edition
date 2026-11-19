import 'package:celechron/utils/platform_features.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:celechron/model/scholar.dart';

import '../../worker/ecard_widget_messenger.dart';
import 'option_controller.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _option = Get.find<OptionController>(tag: 'optionController');
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_submitting || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final scholar = Get.find<Rx<Scholar>>(tag: 'scholar');
    final account = scholar.value
      ..username = _username.text.trim()
      ..password = _password.text;
    try {
      final errors = (await account.login()).whereType<String>().toList();
      if (errors.isNotEmpty) {
        if (mounted) setState(() => _error = errors.join('\n'));
        return;
      }
      await account.refresh(onPartialUpdate: scholar.refresh);
      scholar.refresh();
      _option.pushOnGradeChange = PlatformFeatures.hasBackgroundRefresh;
      if (mounted) Navigator.of(context).pop(true);
    } on Exception {
      if (mounted) setState(() => _error = '登录暂时未完成，请稍后重试。');
    } finally {
      if (mounted) setState(() => _submitting = false);
      ECardWidgetMessenger.update();
    }
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
                          child: Text('统一身份认证登录',
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .navTitleTextStyle)),
                      CupertinoButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    margin: const EdgeInsets.only(bottom: 16),
                    children: [
                      CupertinoTextFormFieldRow(
                        controller: _username,
                        prefix: const Text('学号'),
                        placeholder: '请输入学号',
                        enabled: !_submitting,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? '请填写学号'
                                : null,
                      ),
                      CupertinoTextFormFieldRow(
                        controller: _password,
                        prefix: const Text('密码'),
                        placeholder: '请输入密码',
                        enabled: !_submitting,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (value) =>
                            value == null || value.isEmpty ? '请填写密码' : null,
                      ),
                      CupertinoButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword),
                        child: Text(_obscurePassword ? '显示密码' : '隐藏密码'),
                      ),
                    ],
                  ),
                  if (_error case final error?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(liveRegion: true, child: Text(error)),
                    ),
                  CupertinoButton.filled(
                    onPressed: _submitting ? null : _login,
                    child: _submitting
                        ? Semantics(
                            label: '正在登录', child: CupertinoActivityIndicator())
                        : const Text('登录'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
