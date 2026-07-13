/// Embedded WebView2 login for Windows desktop.
/// Uses the system's WebView2 runtime (pre-installed on Windows 10/11)
/// so the app doesn't depend on any external browser.
///
/// If Google blocks the embedded WebView or WebView2 is unavailable,
/// falls back to opening the system browser (Edge is always present on
/// Windows 10/11 and cannot be uninstalled).
library;

import 'dart:async' show unawaited;
import 'dart:io' show Process;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';

class WindowsWebViewLogin extends StatefulWidget {
  final String url;
  final String? linkCode;
  final DateTime? expiresAt;
  final VoidCallback onCancel;

  const WindowsWebViewLogin({
    super.key,
    required this.url,
    this.linkCode,
    this.expiresAt,
    required this.onCancel,
  });

  @override
  State<WindowsWebViewLogin> createState() => _WindowsWebViewLoginState();
}

class _WindowsWebViewLoginState extends State<WindowsWebViewLogin> {
  final _controller = WebviewController();
  bool _controllerInitialized = false;
  bool _isInitializing = true;
  bool _isLoading = true;
  String? _initError;
  bool _openedInBrowser = false;

  @override
  void initState() {
    super.initState();
    // Use the system browser by default so Google Sign-In can reuse existing
    // logged-in accounts (same expectation as Android/Web account chooser).
    unawaited(_openInBrowser());
  }

  /// Open sign-in in the system browser as fallback.
  /// Edge is always present on Windows 10/11 (it's a system component).
  Future<void> _openInBrowser() async {
    if (mounted) {
      setState(() {
        _openedInBrowser = true;
        _isInitializing = false;
      });
    }

    // Try Edge app mode first (clean window, no address bar)
    try {
      final check = await Process.run('where', ['msedge']);
      if (check.exitCode == 0) {
        await Process.start('cmd', [
          '/c',
          'start',
          '',
          'msedge',
          '--app=${widget.url}',
          '--window-size=500,700',
        ]);
        return;
      }
    } catch (_) {}

    // Final fallback: whatever default browser exists
    final launched = await launchUrl(
      Uri.parse(widget.url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      setState(() {
        _initError = 'Could not open browser. Please check default browser settings.';
      });
    }
  }

  @override
  void dispose() {
    if (_controllerInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
          tooltip: 'Cancel sign in',
        ),
        title: const Text('Sign In'),
        centerTitle: true,
        elevation: 1,
        actions: [
          // Always allow opening in browser as escape hatch
          if (!_openedInBrowser && _initError == null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: _openInBrowser,
              tooltip: 'Open in browser instead',
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // WebView2 failed or user chose browser — show waiting UI
    if (_initError != null || _openedInBrowser) {
      return _buildBrowserFallbackUI(theme);
    }

    // Still initializing WebView2
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing sign-in...'),
          ],
        ),
      );
    }

    // WebView2 ready
    return Stack(
      children: [
        Webview(_controller),
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  /// Fallback UI when using external browser.
  Widget _buildBrowserFallbackUI(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete sign-in in your browser',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'A sign-in window has been opened.\n'
              'Complete the login there with your existing Google accounts — '
              'this screen will update automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.linkCode != null) ...[
              const SizedBox(height: 24),
              Text('Link Code', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              SelectableText(
                widget.linkCode!,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Waiting for sign-in to complete...'),
              ],
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                _openedInBrowser = false;
                _openInBrowser();
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Browser Again'),
            ),
          ],
        ),
      ),
    );
  }
}
