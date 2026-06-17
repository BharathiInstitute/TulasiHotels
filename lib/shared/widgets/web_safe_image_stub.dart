/// Stub implementation for non-web platforms.
/// This file is never actually used at runtime on non-web platforms
/// because WebSafeImage checks kIsWeb before calling this.
library;

import 'package:flutter/material.dart';

Widget buildWebImage({
  required String url,
  required double width,
  required double height,
  required BoxFit fit,
  Widget? errorWidget,
}) {
  // This should never be called on non-web platforms
  return Image.network(url, width: width, height: height, fit: fit);
}
