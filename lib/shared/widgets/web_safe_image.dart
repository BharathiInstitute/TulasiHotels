/// Web-safe image widget that uses HTML <img> on web to bypass CORS.
/// On non-web platforms, uses standard Image.network.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tulasihotels/shared/widgets/web_safe_image_web.dart'
    if (dart.library.io) 'package:tulasihotels/shared/widgets/web_safe_image_stub.dart'
    as platform;

/// Displays a network image that works on all platforms.
/// On web, uses an HTML <img> element to bypass CORS restrictions.
class WebSafeImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? placeholder;

  const WebSafeImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return platform.buildWebImage(
        url: url,
        width: width,
        height: height,
        fit: fit,
        errorWidget: errorWidget,
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
      },
      errorBuilder: (_, _, _) =>
          errorWidget ??
          Image.asset(
            'assets/images/restaurant_logo.png',
            width: width,
            height: height,
            fit: BoxFit.contain,
          ),
    );
  }
}
