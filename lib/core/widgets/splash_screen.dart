/// Flutter splash screen for app initialization
library;

import 'package:flutter/material.dart';

/// Minimal splash: logo centered + linear progress indicator at bottom.
/// Replaces the full-screen gradient splash.
class SplashScreen extends StatelessWidget {
  final String? message;
  final bool showError;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const SplashScreen({
    super.key,
    this.message,
    this.showError = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Logo centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/splash_logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (_, e, stack) => const Icon(
                      Icons.storefront_outlined,
                      size: 80,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  if (showError) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        errorMessage ?? 'Failed to load app',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (onRetry != null)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                  ],
                ],
              ),
            ),

            // Loading indicator at bottom
            if (!showError)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
      ),
    );
  }
}
