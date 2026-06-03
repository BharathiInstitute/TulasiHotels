/// Helper to call Cloud Functions on all platforms including desktop.
///
/// On mobile/web, uses the native `cloud_functions` plugin.
/// On Windows/Linux/macOS, falls back to HTTP REST calls since the
/// native platform channel is not available.
library;

import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudFunctionHelper {
  CloudFunctionHelper._();

  static const _projectId = 'login1-aa21c';
  static const _region = 'asia-south1';

  /// Whether we're on a native desktop platform (no CF plugin support).
  static final bool _isNativeDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Call a Cloud Function by name with optional data.
  /// Returns the response data as a Map.
  static Future<Map<String, dynamic>> call(
    String functionName, [
    Map<String, dynamic>? data,
  ]) async {
    if (_isNativeDesktop) {
      return _callViaHttp(functionName, data);
    }
    return _callViaSdk(functionName, data);
  }

  /// Native SDK path (mobile / web)
  static Future<Map<String, dynamic>> _callViaSdk(
    String functionName,
    Map<String, dynamic>? data,
  ) async {
    final callable = FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(functionName);

    final result = await callable.call<Map<String, dynamic>>(data);
    return result.data;
  }

  /// HTTP REST path (desktop)
  static Future<Map<String, dynamic>> _callViaHttp(
    String functionName,
    Map<String, dynamic>? data,
  ) async {
    final url = Uri.parse(
      'https://$_region-$_projectId.cloudfunctions.net/$functionName',
    );

    // Get auth token if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    String? idToken;
    if (user != null) {
      idToken = await user.getIdToken();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    // Cloud Functions callable protocol wraps data in { "data": ... }
    final body = jsonEncode({'data': data ?? {}});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw FirebaseFunctionsException(
        'cloud-function-error',
        'Cloud Function $functionName returned ${response.statusCode}: ${response.body}',
      );
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    // Callable protocol returns { "result": ... }
    final result = responseBody['result'];
    if (result is Map<String, dynamic>) {
      return result;
    }
    return responseBody;
  }
}

/// Simple exception for CF errors
class FirebaseFunctionsException implements Exception {
  final String code;
  final String message;
  FirebaseFunctionsException(this.code, this.message);

  @override
  String toString() => 'FirebaseFunctionsException($code): $message';
}
