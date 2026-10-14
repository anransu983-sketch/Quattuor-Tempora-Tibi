import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dream/panel_prefs.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PanelView extends ConsumerStatefulWidget {
  const PanelView({super.key});

  @override
  ConsumerState<PanelView> createState() => _PanelViewState();
}

class _PanelViewState extends ConsumerState<PanelView> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _controllerAutoOpened = false;

  bool get _isMobile => system.isAndroid;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      unawaited(_prepare());
    }
  }

  /// The dashboard needs the external controller. Opening it here is the
  /// least disruptive option: it applies live through updateConfig without a
  /// full profile rebuild, and the toggle stays reversible in 通用设置.
  Future<void> _prepare() async {
    var patchConfig = ref.read(patchClashConfigProvider);
    if (patchConfig.externalController == ExternalControllerStatus.close) {
      ref
          .read(patchClashConfigProvider.notifier)
          .update(
            (state) => state
                .copyWith(externalController: ExternalControllerStatus.open)
                .ensureControllerSecret(),
          );
      patchConfig = ref.read(patchClashConfigProvider);
      _controllerAutoOpened = true;
    }
    final panel = DreamPanel.fromValue(ref.read(dreamPanelProvider));
    final addressParts = ExternalControllerStatus.open.value.split(':');
    final host = addressParts[0];
    final port = addressParts[1];
    if (_controllerAutoOpened) {
      await _waitForController(host, port);
    }
    final url = panel.dashboardUrl(host, port, patchConfig.secret);
    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onWebResourceError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = error.description;
            });
          }
        },
      ),
    );
    await controller.loadRequest(Uri.parse(url));
    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _controller?.reload();
  }

  /// Any HTTP response, including 401, proves the controller is listening;
  /// only a connection failure keeps waiting.
  Future<void> _waitForController(String host, String port) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ),
    );
    for (var i = 0; i < 16; i++) {
      try {
        await dio.get('http://$host:$port/version');
        return;
      } on DioException catch (e) {
        if (e.response != null) {
          return;
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = ref.watch(
      runTimeProvider.select((state) => state != null),
    );
    return CommonScaffold(
      title: context.appLocalizations.dreamPanel,
      body: _buildBody(isRunning),
    );
  }

  Widget _buildBody(bool isRunning) {
    if (!_isMobile) {
      return Center(
        child: Text(context.appLocalizations.dreamPanelAndroidOnly),
      );
    }
    if (!isRunning) {
      return Center(
        child: Text(context.appLocalizations.dreamPanelStartFirst),
      );
    }
    final controller = _controller;
    final error = _error;
    return Column(
      children: [
        if (_controllerAutoOpened && error == null)
          _AutoOpenedHint(
            onDismiss: () {
              setState(() {
                _controllerAutoOpened = false;
              });
            },
          ),
        Expanded(
          child: Stack(
            children: [
              if (controller != null) WebViewWidget(controller: controller),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              if (error != null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.appLocalizations.dreamPanelLoadFailed),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _retry, child: Text(context.appLocalizations.dreamPanelRetry)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AutoOpenedHint extends StatelessWidget {
  final VoidCallback onDismiss;

  const _AutoOpenedHint({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: AppShape.xs,
      onTap: onDismiss,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: context.colorScheme.surfaceContainerLow,
        child: Text(
          context.appLocalizations.dreamPanelControllerAutoOpened,
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
