/// Persistent queue for deferred product image uploads.
///
/// When a user selects an image while offline, bytes are stored locally.
/// After the related product is created, the draft is attached to a product ID.
/// On connectivity restore, queued images are uploaded to Firebase Storage and
/// corresponding product docs are updated with the final download URL.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/connectivity_service.dart';

class PendingImageQueueStats {
  final int drafts;
  final int pending;
  final int failed;
  final bool syncing;

  const PendingImageQueueStats({
    required this.drafts,
    required this.pending,
    required this.failed,
    required this.syncing,
  });

  int get total => drafts + pending + failed;
}

class PendingProductImageUpload {
  PendingProductImageUpload({
    required this.id,
    required this.storeId,
    required this.imageBase64,
    required this.createdAt,
    this.productId,
    this.attempts = 0,
    this.lastError,
    DateTime? lastAttemptAt,
  }) : lastAttemptAt = lastAttemptAt ?? DateTime.now();

  final String id;
  final String storeId;
  String? productId;
  final String imageBase64;
  int attempts;
  String? lastError;
  DateTime lastAttemptAt;
  final DateTime createdAt;

  bool get isDraft => productId == null || productId!.isEmpty;
  bool get isFailed => attempts >= PendingProductImageUploadService.maxRetries;

  Map<String, dynamic> toJson() => {
    'id': id,
    'storeId': storeId,
    'productId': productId,
    'imageBase64': imageBase64,
    'attempts': attempts,
    'lastError': lastError,
    'lastAttemptAt': lastAttemptAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingProductImageUpload.fromJson(Map<String, dynamic> json) {
    return PendingProductImageUpload(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      productId: json['productId'] as String?,
      imageBase64: json['imageBase64'] as String,
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      lastAttemptAt:
          DateTime.tryParse(json['lastAttemptAt'] as String? ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PendingProductImageUploadService {
  static const String _storageKey = 'pending_product_image_uploads_v1';
  static const int maxRetries = 5;

  static SharedPreferences? _prefs;
  static StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  static bool _isInitialized = false;
  static bool _isSyncing = false;
  static Timer? _retryTimer;

  static final ValueNotifier<PendingImageQueueStats> statsNotifier =
      ValueNotifier<PendingImageQueueStats>(
        const PendingImageQueueStats(
          drafts: 0,
          pending: 0,
          failed: 0,
          syncing: false,
        ),
      );

  static Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    _refreshStats();

    _connectivitySubscription = ConnectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        unawaited(processPendingUploads());
      }
    });

    if (ConnectivityService.isOnline) {
      unawaited(processPendingUploads());
    }
  }

  static Future<String> createDraft({
    required Uint8List imageBytes,
    String? storeId,
  }) async {
    await _ensureInitialized();

    final resolvedStoreId =
        storeId ?? ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedStoreId == null || resolvedStoreId.isEmpty) {
      throw StateError('No active store found for pending image upload draft');
    }

    final queue = _loadQueue();
    final draft = PendingProductImageUpload(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      storeId: resolvedStoreId,
      imageBase64: base64Encode(imageBytes),
      createdAt: DateTime.now(),
    );
    queue.add(draft);
    await _saveQueue(queue);
    debugPrint('🖼️ PendingImageQueue: Draft created ${draft.id}');
    return draft.id;
  }

  static Future<void> attachDraftToProduct({
    required String draftId,
    required String productId,
    String? storeId,
  }) async {
    await _ensureInitialized();

    final queue = _loadQueue();
    final resolvedStoreId =
        storeId ?? ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;

    final index = queue.indexWhere((item) {
      if (item.id != draftId) return false;
      if (resolvedStoreId == null || resolvedStoreId.isEmpty) return true;
      return item.storeId == resolvedStoreId;
    });

    if (index == -1) {
      debugPrint('⚠️ PendingImageQueue: Draft not found: $draftId');
      return;
    }

    queue[index].productId = productId;
    queue[index].attempts = 0;
    queue[index].lastError = null;
    queue[index].lastAttemptAt = DateTime.now();

    await _saveQueue(queue);
    debugPrint('🖼️ PendingImageQueue: Draft $draftId linked to product $productId');

    if (ConnectivityService.isOnline) {
      unawaited(processPendingUploads());
    }
  }

  static Future<void> retryFailedUploads() async {
    await _ensureInitialized();

    final queue = _loadQueue();
    var changed = false;
    for (final item in queue) {
      if (item.isFailed) {
        item.attempts = 0;
        item.lastError = null;
        item.lastAttemptAt = DateTime.now();
        changed = true;
      }
    }

    if (changed) {
      await _saveQueue(queue);
    }

    if (ConnectivityService.isOnline) {
      await processPendingUploads();
    }
  }

  static Future<void> processPendingUploads({bool force = false}) async {
    await _ensureInitialized();
    if (_isSyncing || ConnectivityService.isOffline) {
      _refreshStats();
      return;
    }

    _isSyncing = true;
    _refreshStats();

    try {
      final queue = _loadQueue();
      if (queue.isEmpty) return;

      final remaining = <PendingProductImageUpload>[];
      int? nextRetryDelayMs;
      for (final item in queue) {
        if (item.isDraft || item.isFailed) {
          remaining.add(item);
          continue;
        }

        final backoffMs = (1 << item.attempts) * 1000;
        final elapsedMs = DateTime.now().difference(item.lastAttemptAt).inMilliseconds;
        if (!force && elapsedMs < backoffMs) {
          final waitMs = backoffMs - elapsedMs;
          if (nextRetryDelayMs == null || waitMs < nextRetryDelayMs) {
            nextRetryDelayMs = waitMs;
          }
          remaining.add(item);
          continue;
        }

        try {
          await _uploadAndAttach(item);
        } catch (e) {
          item.attempts += 1;
          item.lastAttemptAt = DateTime.now();
          item.lastError = e.toString();
          remaining.add(item);
          final retryBackoffMs = (1 << item.attempts) * 1000;
          if (nextRetryDelayMs == null || retryBackoffMs < nextRetryDelayMs) {
            nextRetryDelayMs = retryBackoffMs;
          }
          debugPrint(
            '⚠️ PendingImageQueue: upload failed for ${item.productId} '
            '(attempt ${item.attempts}/$maxRetries): $e',
          );
        }
      }

      await _saveQueue(remaining);

      final hasRetryablePending = remaining.any(
        (item) => !item.isDraft && !item.isFailed,
      );
      if (hasRetryablePending && ConnectivityService.isOnline) {
        _scheduleRetry(nextRetryDelayMs ?? 5000);
      } else {
        _retryTimer?.cancel();
        _retryTimer = null;
      }
    } finally {
      _isSyncing = false;
      _refreshStats();
    }
  }

  static void _scheduleRetry(int delayMs) {
    _retryTimer?.cancel();
    final clampedDelayMs = delayMs.clamp(1000, 30000);
    _retryTimer = Timer(Duration(milliseconds: clampedDelayMs), () {
      if (ConnectivityService.isOnline) {
        unawaited(processPendingUploads());
      }
    });
  }

  static Future<void> _uploadAndAttach(PendingProductImageUpload item) async {
    final productId = item.productId;
    if (productId == null || productId.isEmpty) return;
    final uploadOwnerUid = FirebaseAuth.instance.currentUser?.uid;
    if (uploadOwnerUid == null || uploadOwnerUid.isEmpty) {
      throw StateError('Cannot sync pending image: not signed in');
    }
    final targetStoreId = await _resolveStoreIdForProduct(
      productId: productId,
      preferredStoreId: item.storeId,
    );

    final bytes = base64Decode(item.imageBase64);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final storageRef = FirebaseStorage.instance.ref().child(
      'users/$uploadOwnerUid/products/product_${productId}_$timestamp.jpg',
    );

    await storageRef
        .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
        .timeout(const Duration(seconds: 20));

    final downloadUrl =
        await storageRef.getDownloadURL().timeout(const Duration(seconds: 10));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetStoreId)
        .collection('products')
        .doc(productId)
        .update({
          'imageUrl': downloadUrl,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

    debugPrint('✅ PendingImageQueue: synced image for product $productId');
  }

  static Future<String> _resolveStoreIdForProduct({
    required String productId,
    required String preferredStoreId,
  }) async {
    final candidates = <String>{
      preferredStoreId,
      ActiveStoreManager.storeId ?? '',
      FirebaseAuth.instance.currentUser?.uid ?? '',
    }.where((id) => id.isNotEmpty).toList();

    for (final storeId in candidates) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(storeId)
            .collection('products')
            .doc(productId)
            .get();
        if (doc.exists) {
          return storeId;
        }
      } catch (_) {
        // Ignore and continue probing candidate store IDs.
      }
    }

    return preferredStoreId;
  }

  static List<PendingProductImageUpload> _loadQueue() {
    final json = _prefs?.getString(_storageKey);
    if (json == null || json.isEmpty) return [];

    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((item) => PendingProductImageUpload.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ PendingImageQueue: Failed to parse queue: $e');
      return [];
    }
  }

  static Future<void> _saveQueue(List<PendingProductImageUpload> queue) async {
    final json = jsonEncode(queue.map((item) => item.toJson()).toList());
    await _prefs?.setString(_storageKey, json);
    _refreshStats(queue: queue);
  }

  static void _refreshStats({List<PendingProductImageUpload>? queue}) {
    final items = queue ?? _loadQueue();
    var drafts = 0;
    var pending = 0;
    var failed = 0;

    for (final item in items) {
      if (item.isDraft) {
        drafts += 1;
      } else if (item.isFailed) {
        failed += 1;
      } else {
        pending += 1;
      }
    }

    statsNotifier.value = PendingImageQueueStats(
      drafts: drafts,
      pending: pending,
      failed: failed,
      syncing: _isSyncing,
    );
  }

  static Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await initialize();
  }

  static Future<void> dispose() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
  }
}
