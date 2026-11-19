import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:celechron/design/content_empty_state.dart';
import 'package:celechron/design/persistent_headers.dart';
import '../../http/zjuServices/ecard.dart';
import '../../http/zjuServices/exceptions.dart';
import '../../utils/utils.dart';
import 'login_page.dart';
import 'option_controller.dart';

enum _PaymentCodeState { loading, signedOut, failed, ready }

class ECardPayPage extends StatefulWidget {
  const ECardPayPage({super.key});

  @override
  State<ECardPayPage> createState() => _ECardPayPageState();
}

class _ECardPayPageState extends State<ECardPayPage> {
  static const _testAccount = '3200000000';
  final _httpClient = HttpClient();
  var _state = _PaymentCodeState.loading;
  String? _barcode;

  @override
  void initState() {
    super.initState();
    _requestNewCode(initial: true);
  }

  @override
  void dispose() {
    _httpClient.close(force: true);
    super.dispose();
  }

  void _showState(_PaymentCodeState state, {String? barcode}) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _barcode = barcode;
    });
  }

  Future<void> _requestNewCode({bool initial = false}) async {
    if (!initial && _state == _PaymentCodeState.loading) return;
    if (!initial) _showState(_PaymentCodeState.loading);
    try {
      const secureStorage = FlutterSecureStorage();
      final auth = await secureStorage.read(
          key: 'synjonesAuth', iOptions: secureStorageIOSOptions);
      if (!mounted) return;
      if (auth == null || auth.trim().isEmpty || auth == _testAccount) {
        _showState(_PaymentCodeState.signedOut);
        return;
      }
      final storedAccount = await secureStorage.read(
          key: 'eCardAccount', iOptions: secureStorageIOSOptions);
      if (!mounted) return;
      final account =
          storedAccount ?? await ECard.getAccount(_httpClient, auth);
      if (!mounted) return;
      _httpClient.userAgent =
          'E-CampusZJU/2.3.20 (iPhone; iOS 17.5.1; Scale/3.00)';
      final barcode = await ECard.getBarcode(_httpClient, auth, account);
      _showState(_PaymentCodeState.ready, barcode: barcode);
    } on AuthenticationExpiredException {
      _showState(_PaymentCodeState.signedOut);
    } on Exception {
      _showState(_PaymentCodeState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            const CelechronSliverTextHeader(subtitle: '付款码'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: switch (_state) {
                      _PaymentCodeState.loading => const [
                          CupertinoActivityIndicator(),
                          SizedBox(height: 12),
                          Text('正在获取付款码…'),
                        ],
                      _PaymentCodeState.signedOut => [
                          const ContentEmptyState(
                            icon: CupertinoIcons.person_crop_circle,
                            title: '校园卡未登录或登录已过期',
                            verticalPadding: 8,
                          ),
                          const Text('请登录校园账号后再试。',
                              textAlign: TextAlign.center),
                          if (Get.isRegistered<OptionController>(
                              tag: 'optionController'))
                            CupertinoButton(
                              onPressed: () async {
                                final signedIn =
                                    await showCupertinoModalPopup<bool>(
                                  context: context,
                                  builder: (_) => const LoginForm(),
                                );
                                if (mounted && signedIn == true) {
                                  await _requestNewCode();
                                }
                              },
                              child: const Text('去登录'),
                            ),
                        ],
                      _PaymentCodeState.failed => [
                          const ContentEmptyState(
                            icon: CupertinoIcons.exclamationmark_circle,
                            title: '暂时无法获取付款码',
                          ),
                          const Text('请检查网络连接后重试。',
                              textAlign: TextAlign.center),
                          CupertinoButton(
                            onPressed: _requestNewCode,
                            child: const Text('重试'),
                          ),
                        ],
                      _PaymentCodeState.ready => [
                          ExcludeSemantics(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _barcode!.length < 30
                                  ? QrImageView(
                                      data: _barcode!, version: 3, size: 200)
                                  : Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(_barcode!,
                                          style: const TextStyle(
                                              color: CupertinoColors.black)),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_barcode!.length < 30)
                            ExcludeSemantics(
                              child: Text('付款码：$_barcode',
                                  textAlign: TextAlign.center),
                            ),
                          Semantics(
                            liveRegion: true,
                            child: const Text('付款码已就绪'),
                          ),
                          CupertinoButton(
                            onPressed: _requestNewCode,
                            child: const Text('刷新二维码'),
                          ),
                        ],
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
