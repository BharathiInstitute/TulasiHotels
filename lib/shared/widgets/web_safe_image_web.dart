/// Web implementation of WebSafeImage using HtmlElementView
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as html;

/// Track registered view types to avoid duplicate registration errors
final Set<String> _registeredViewTypes = {};

/// Counter for unique view IDs
int _viewIdCounter = 0;

/// Builds an HTML <img> element embedded in Flutter via HtmlElementView.
/// This bypasses CORS restrictions that affect CanvasKit's Image.network.
Widget buildWebImage({
  required String url,
  required double width,
  required double height,
  required BoxFit fit,
  Widget? errorWidget,
}) {
  // Use a unique view type per call to avoid stale cached images
  final viewType = 'web-safe-img-${_viewIdCounter++}';

  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.HTMLImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = _boxFitToCss(fit)
          ..style.display = 'block';
        return img;
      },
      isVisible: true,
    );
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}

String _boxFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitWidth:
      return 'cover';
    case BoxFit.fitHeight:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
