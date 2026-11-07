import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// 应用内 H5 页面（隐私政策等外链）。
///
/// - Android / iOS：使用系统 WebView 内嵌加载；
/// - Web 及不支持的平台：提供跳转外部浏览器按钮。
class PrivacyPolicyScreen extends StatefulWidget {
  final String url;
  final String title;

  const PrivacyPolicyScreen({super.key, required this.url, required this.title});

  /// 当前平台是否有可用的内嵌 WebView。
  static bool get supportsEmbeddedWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static void open(
    BuildContext context, {
    required String url,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivacyPolicyScreen(url: url, title: title),
      ),
    );
  }

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _loading = true;

  Uri get _uri => Uri.parse(widget.url);

  @override
  void initState() {
    super.initState();
    if (!PrivacyPolicyScreen.supportsEmbeddedWebView) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) return;
            setState(() => _progress = value);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _progress = 100;
            });
          },
        ),
      )
      ..loadRequest(_uri);
  }

  Future<void> _openInBrowser() async {
    final ok = await launchUrl(_uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open browser')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final embedded = _controller != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: embedded
          ? Column(
              children: [
                if (_loading)
                  LinearProgressIndicator(
                    value: _progress <= 0 || _progress >= 100
                        ? null
                        : _progress / 100,
                    minHeight: 2,
                    backgroundColor: AppTheme.surface,
                    color: AppTheme.accent,
                  )
                else
                  const SizedBox(height: 2),
                Expanded(child: WebViewWidget(controller: _controller!)),
              ],
            )
          : _UnsupportedView(uri: _uri, onOpen: _openInBrowser),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  final Uri uri;
  final VoidCallback onOpen;

  const _UnsupportedView({required this.uri, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.public_rounded,
                size: 28,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              uri.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open in browser'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
