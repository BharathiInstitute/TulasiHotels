/// Centralized website URL helper.
///
/// Production web (Firebase hosting):
///   App at /app/, website at / — same domain, always works.
///
/// Windows desktop:
///   Open the public website URL in the default browser.
///
/// Local dev (flutter run):
///   - Preview mode (preview.ps1 on port 9000): / works directly
///   - Dev mode (flutter run + http-server): website at localhost:8080
///
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

const _productionWebsiteUrl = 'https://restaurants.tulasierp.com';

/// Whether the current platform should show website navigation links.
/// Web and Windows desktop show the website link.
bool get showWebsiteLink => kIsWeb || Platform.isWindows;

/// The URL that takes the user from the Flutter app to the marketing website.
///
/// On web production: / (same domain root)
/// On Windows: public website URL
/// On web debug: localhost:8080 website server
String get websiteUrl {
  if (!kIsWeb) return _productionWebsiteUrl;
  if (!kDebugMode) return '/';
  // In debug, we might be on preview.ps1 (port 9000) where / is the website,
  // or on flutter run (port 5050) where website is on 8080.
  // Use / which works in preview mode. The JS on the website handles the
  // reverse direction. For flutter run mode, 8080 is the fallback.
  return 'http://localhost:8080';
}

/// The URL that takes the user from the marketing website to the Flutter app.
/// (Primarily used in the static website HTML, listed here for reference.)
String get appUrl => '/app/';
