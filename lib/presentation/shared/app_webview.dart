import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:genshindb/generated/l10n.dart';
import 'package:genshindb/presentation/shared/page_message.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:webview_windows/webview_windows.dart';

import 'loading.dart';

class AppWebView extends StatelessWidget {
  final String url;
  final String userAgent;
  final bool hasInternetConnection;
  final bool isLoading;
  final String? script;
  final AppBar? appBar;

  const AppWebView({
    Key? key,
    required this.url,
    required this.userAgent,
    required this.hasInternetConnection,
    this.isLoading = false,
    this.script,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _DesktopWebView(
        url: url,
        hasInternetConnection: hasInternetConnection,
        appBar: appBar,
        script: script,
        isLoading: isLoading,
      );
    }

    return _MobileWebView(
      url: url,
      userAgent: userAgent,
      hasInternetConnection: hasInternetConnection,
      appBar: appBar,
      script: script,
      isLoading: isLoading,
    );
  }
}

class _MobileWebView extends StatefulWidget {
  final String url;
  final String userAgent;
  final bool hasInternetConnection;
  final bool isLoading;
  final String? script;
  final AppBar? appBar;

  const _MobileWebView({
    Key? key,
    required this.url,
    required this.userAgent,
    required this.hasInternetConnection,
    this.isLoading = false,
    this.script,
    this.appBar,
  }) : super(key: key);

  @override
  _MobileWebViewState createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<_MobileWebView> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    if (!widget.hasInternetConnection) {
      final s = S.of(context);
      return PageMessage(text: s.noInternetConnection);
    }
    if (widget.isLoading) {
      return const Loading();
    }
    final device = getDeviceType(MediaQuery.of(context).size);
    return Stack(
      children: [
        Scaffold(
          appBar: widget.appBar,
          body: InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
            initialOptions: InAppWebViewGroupOptions(
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              ),
              crossPlatform: InAppWebViewOptions(
                preferredContentMode: device == DeviceScreenType.mobile ? UserPreferredContentMode.MOBILE : UserPreferredContentMode.RECOMMENDED,
                //This may fail on weird devices (chinese ones ?)...
                userAgent: widget.userAgent,
                transparentBackground: true,
              ),
            ),
            onLoadStop: (controller, url) async {
              if (widget.script != null) {
                await controller.evaluateJavascript(source: widget.script!);
              }
              setState(() {
                _loading = false;
              });
            },
          ),
        ),
        if (_loading) const Loading(),
      ],
    );
  }
}

class _DesktopWebView extends StatefulWidget {
  final String url;
  final bool hasInternetConnection;
  final bool isLoading;
  final String? script;
  final AppBar? appBar;

  const _DesktopWebView({
    Key? key,
    required this.url,
    required this.hasInternetConnection,
    this.isLoading = false,
    this.script,
    this.appBar,
  }) : super(key: key);

  @override
  _DesktopWebViewState createState() => _DesktopWebViewState();
}

class _DesktopWebViewState extends State<_DesktopWebView> {
  late WebviewController _controller;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    if (!widget.hasInternetConnection) {
      return;
    }

    _controller = WebviewController();
    await _controller.initialize();
    await _controller.loadUrl(widget.url);
    _subscription = _controller.loadingState.listen(_onStateChanged);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasInternetConnection) {
      final s = S.of(context);
      return PageMessage(text: s.noInternetConnection);
    }
    if (widget.isLoading) {
      return const Loading();
    }
    return Scaffold(
      appBar: widget.appBar,
      body: _controller.value.isInitialized ? Webview(_controller) : const Loading(),
    );
  }

  Future<void> _onStateChanged(LoadingState event) async {
    if (event == LoadingState.navigationCompleted && widget.script != null) {
      await _controller.executeScript(widget.script!);
    }
  }
}
