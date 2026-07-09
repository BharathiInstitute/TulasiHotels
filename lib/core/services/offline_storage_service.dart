/// Offline storage service - Firestore-based with offline support
///
/// This replaces the previous Hive-based implementation.
/// Firebase Firestore offline persistence handles all local caching.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:tulasihotels/core/constants/app_constants.dart';
import 'package:tulasihotels/core/services/sync_status_service.dart';
import 'package:tulasihotels/core/services/user_usage_service.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/core/utils/windows_firestore_helper.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/customer_model.dart';
import 'package:tulasihotels/models/expense_model.dart';
import 'package:tulasihotels/models/product_model.dart';
import 'package:tulasihotels/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulasihotels/core/services/connectivity_service.dart';

/// Keys for SharedPreferences (for settings only)
class SettingsKeys {
  static const String settings = 'app_settings';
  static const String dataInitialized = 'data_initialized';
  static const String isDarkMode = 'is_dark_mode';
  static const String language = 'language';
  static const String retentionDays = 'retention_days';
  static const String lastCleanupTime = 'last_cleanup_time';
  static const String lastExportTime = 'last_export_time';
  static const String autoCleanupEnabled = 'auto_cleanup_enabled';
}

/// Hive box names (kept for compatibility, now maps to Firestore collections)
class HiveBoxes {
  static const String products = 'products';
  static const String bills = 'bills';
  static const String customers = 'customers';
  static const String pendingSync = 'pending_sync';
  static const String settings = 'settings';
}

/// Printer storage for SharedPreferences
class PrinterStorage {
  static const String isConnected = 'printer_is_connected';
  static const String printerName = 'printer_name';
  static const String printerAddress = 'printer_address';
  static const String paperWidth = 'printer_paper_width';
  static const String _paperSizeKey = 'printer_paper_size';
  static const String _fontSizeKey = 'printer_font_size';
  static const String _customWidthKey = 'printer_custom_width';
  static const String _autoPrintKey = 'printer_auto_print';
  static const String _receiptFooterKey = 'printer_receipt_footer';
  static const String _printerTypeKey = 'printer_type';
  static const String _wifiIpKey = 'printer_wifi_ip';
  static const String _wifiPortKey = 'printer_wifi_port';
  static const String _usbPrinterNameKey = 'printer_usb_name';
  static const String _openCashDrawerKey = 'printer_open_cash_drawer';
  static const String _printCopiesKey = 'printer_copies';
  static const String _showQrOnReceiptKey = 'printer_show_qr';
  static const String _showGstBreakdownKey = 'printer_show_gst';
  static const String _receiptLanguageKey = 'printer_language';
  static const String _showLogoOnThermalKey = 'printer_show_logo';
  static const String _cutModeKey = 'printer_cut_mode';
  static const String _showCopyLabelKey = 'printer_show_copy_label';
  static const String _showHsnOnReceiptKey = 'printer_show_hsn';
  static const String _printDensityKey = 'printer_density';
  static const String _systemPrinterNameKey = 'printer_system_name';
  static const String _systemPrinterUrlKey = 'printer_system_url';

  static SharedPreferences? _prefs;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get saved printer
  static Map<String, String>? getSavedPrinter() {
    final name = _prefs?.getString(printerName);
    final address = _prefs?.getString(printerAddress);
    if (name == null || address == null) return null;
    return {'name': name, 'address': address};
  }

  /// Save printer
  static Future<void> savePrinter(String name, String address) async {
    await _ensurePrefs();
    await _prefs?.setString(printerName, name);
    await _prefs?.setString(printerAddress, address);
    await _prefs?.setBool(isConnected, true);
  }

  /// Clear saved printer
  static Future<void> clearSavedPrinter() async {
    await _ensurePrefs();
    await _prefs?.remove(printerName);
    await _prefs?.remove(printerAddress);
    await _prefs?.setBool(isConnected, false);
  }

  /// Get saved paper size (index)
  static int getSavedPaperSize() {
    return _prefs?.getInt(_paperSizeKey) ?? 0;
  }

  /// Save paper size
  static Future<void> savePaperSize(int sizeIndex) async {
    await _ensurePrefs();
    await _prefs?.setInt(_paperSizeKey, sizeIndex);
  }

  /// Get saved font size (index)
  static int getSavedFontSize() {
    return _prefs?.getInt(_fontSizeKey) ?? 1;
  }

  /// Save font size
  static Future<void> saveFontSize(int fontSizeIndex) async {
    await _ensurePrefs();
    await _prefs?.setInt(_fontSizeKey, fontSizeIndex);
  }

  /// Get saved custom width
  static int getSavedCustomWidth() {
    return _prefs?.getInt(_customWidthKey) ?? 0;
  }

  /// Save custom width
  static Future<void> saveCustomWidth(int width) async {
    await _ensurePrefs();
    await _prefs?.setInt(_customWidthKey, width);
  }

  /// Get auto-print setting
  static bool getAutoPrint() {
    return _prefs?.getBool(_autoPrintKey) ?? false;
  }

  /// Save auto-print setting
  static Future<void> saveAutoPrint(bool autoPrint) async {
    await _ensurePrefs();
    await _prefs?.setBool(_autoPrintKey, autoPrint);
  }

  /// Get receipt footer text
  static String getReceiptFooter() {
    return _prefs?.getString(_receiptFooterKey) ?? '';
  }

  /// Save receipt footer text
  static Future<void> saveReceiptFooter(String footer) async {
    await _ensurePrefs();
    await _prefs?.setString(_receiptFooterKey, footer);
  }

  /// Get printer type (system, bluetooth, usb, wifi)
  static String getPrinterType() {
    return _prefs?.getString(_printerTypeKey) ?? 'system';
  }

  /// Save printer type
  static Future<void> savePrinterType(String type) async {
    await _ensurePrefs();
    await _prefs?.setString(_printerTypeKey, type);
  }

  // â”€â”€ WiFi printer settings â”€â”€

  /// Get saved WiFi printer IP
  static String getWifiPrinterIp() {
    return _prefs?.getString(_wifiIpKey) ?? '';
  }

  /// Save WiFi printer IP
  static Future<void> saveWifiPrinterIp(String ip) async {
    await _ensurePrefs();
    await _prefs?.setString(_wifiIpKey, ip);
  }

  /// Get saved WiFi printer port (default 9100)
  static int getWifiPrinterPort() {
    return _prefs?.getInt(_wifiPortKey) ?? 9100;
  }

  /// Save WiFi printer port
  static Future<void> saveWifiPrinterPort(int port) async {
    await _ensurePrefs();
    await _prefs?.setInt(_wifiPortKey, port);
  }

  // â”€â”€ USB printer settings â”€â”€

  /// Get saved USB printer name (Windows)
  static String getUsbPrinterName() {
    return _prefs?.getString(_usbPrinterNameKey) ?? '';
  }

  /// Save USB printer name (Windows)
  static Future<void> saveUsbPrinterName(String name) async {
    await _ensurePrefs();
    await _prefs?.setString(_usbPrinterNameKey, name);
  }

  // â”€â”€ Cash drawer â”€â”€
  static bool getOpenCashDrawer() =>
      _prefs?.getBool(_openCashDrawerKey) ?? false;
  static Future<void> saveOpenCashDrawer(bool open) async {
    await _ensurePrefs();
    await _prefs?.setBool(_openCashDrawerKey, open);
  }

  // â”€â”€ Print copies â”€â”€
  static int getPrintCopies() => _prefs?.getInt(_printCopiesKey) ?? 1;
  static Future<void> savePrintCopies(int copies) async {
    await _ensurePrefs();
    await _prefs?.setInt(_printCopiesKey, copies);
  }

  // â”€â”€ Show QR on receipt â”€â”€
  static bool getShowQrOnReceipt() =>
      _prefs?.getBool(_showQrOnReceiptKey) ?? false;
  static Future<void> saveShowQrOnReceipt(bool show) async {
    await _ensurePrefs();
    await _prefs?.setBool(_showQrOnReceiptKey, show);
  }

  // â”€â”€ Show GST breakdown â”€â”€
  static bool getShowGstBreakdown() =>
      _prefs?.getBool(_showGstBreakdownKey) ?? false;
  static Future<void> saveShowGstBreakdown(bool show) async {
    await _ensurePrefs();
    await _prefs?.setBool(_showGstBreakdownKey, show);
  }

  // â”€â”€ Receipt language â”€â”€
  static String getReceiptLanguage() =>
      _prefs?.getString(_receiptLanguageKey) ?? 'english';
  static Future<void> saveReceiptLanguage(String lang) async {
    await _ensurePrefs();
    await _prefs?.setString(_receiptLanguageKey, lang);
  }

  // â”€â”€ Show logo on thermal â”€â”€
  static bool getShowLogoOnThermal() =>
      _prefs?.getBool(_showLogoOnThermalKey) ?? false;
  static Future<void> saveShowLogoOnThermal(bool show) async {
    await _ensurePrefs();
    await _prefs?.setBool(_showLogoOnThermalKey, show);
  }

  // â”€â”€ Cut mode â”€â”€
  static String getCutMode() => _prefs?.getString(_cutModeKey) ?? 'fullCut';
  static Future<void> saveCutMode(String mode) async {
    await _ensurePrefs();
    await _prefs?.setString(_cutModeKey, mode);
  }

  // â”€â”€ Show copy label â”€â”€
  static bool getShowCopyLabel() => _prefs?.getBool(_showCopyLabelKey) ?? false;
  static Future<void> saveShowCopyLabel(bool show) async {
    await _ensurePrefs();
    await _prefs?.setBool(_showCopyLabelKey, show);
  }

  // â”€â”€ Show HSN on receipt â”€â”€
  static bool getShowHsnOnReceipt() =>
      _prefs?.getBool(_showHsnOnReceiptKey) ?? false;
  static Future<void> saveShowHsnOnReceipt(bool show) async {
    await _ensurePrefs();
    await _prefs?.setBool(_showHsnOnReceiptKey, show);
  }

  // â”€â”€ Print density â”€â”€
  static int getPrintDensity() => _prefs?.getInt(_printDensityKey) ?? 1;
  static Future<void> savePrintDensity(int density) async {
    await _ensurePrefs();
    await _prefs?.setInt(_printDensityKey, density);
  }

  // â”€â”€ System printer (for direct PDF print) â”€â”€
  static String getSystemPrinterName() =>
      _prefs?.getString(_systemPrinterNameKey) ?? '';
  static String getSystemPrinterUrl() =>
      _prefs?.getString(_systemPrinterUrlKey) ?? '';
  static Future<void> saveSystemPrinter(String name, String url) async {
    await _ensurePrefs();
    await _prefs?.setString(_systemPrinterNameKey, name);
    await _prefs?.setString(_systemPrinterUrlKey, url);
  }

  /// Initialize (called during app startup)
  static Future<void> initialize() async {
    await _ensurePrefs();
  }
}

/// Offline storage service using Firestore with offline persistence
class OfflineStorageService {
  static bool _initialized = false;
  static SharedPreferences? _prefs;
  static final _firestore = FirebaseFirestore.instance;

  /// Expose prefs for direct access (e.g., route persistence)
  static SharedPreferences? get prefs => _prefs;

  /// Reset internal state for testing. MUST be called in test setUp
  /// after SharedPreferences.setMockInitialValues().
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _prefs = null;
  }

  /// Get user's collection path
  static String get _basePath => ActiveStoreManager.basePath;

  /// Initialize storage (Firestore offline is already enabled in SyncSettingsService)
  static Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('âœ… OfflineStorageService initialized (Firestore-based)');
  }

  // ==================== Products ====================

  /// Cache products locally (no-op, Firestore handles caching)
  static Future<void> cacheProducts(List<ProductModel> products) async {
    debugPrint(
      'cacheProducts: Firestore handles caching, ${products.length} products',
    );
  }

  /// Get cached products from Firestore
  @Deprecated('Use productsProvider stream instead')
  static List<ProductModel> getCachedProducts() {
    debugPrint('getCachedProducts: Use productsProvider stream instead');
    return [];
  }

  /// Get cached products async (recommended)
  static Future<List<ProductModel>> getCachedProductsAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/products')
          .limit(500)
          .get();
      UserUsageService.trackRead(count: snapshot.docs.length);
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  /// Get single cached product
  static ProductModel? getCachedProduct(String id) {
    return null;
  }

  /// Get single cached product async
  static Future<ProductModel?> getCachedProductAsync(String id) async {
    if (_basePath.isEmpty) return null;
    try {
      final doc = await _firestore.doc('$_basePath/products/$id').get();
      UserUsageService.trackRead();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Update cached product (saves to Firestore)
  static Future<void> updateCachedProduct(ProductModel product) async {
    if (_basePath.isEmpty) return;
    await _firestore
        .doc('$_basePath/products/${product.id}')
        .set(product.toFirestore());
    UserUsageService.trackWrite();
  }

  /// Delete product
  static Future<void> deleteProduct(String productId) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/products/$productId').delete();
    UserUsageService.trackDelete();
  }

  // ==================== Bills ====================

  /// Cache bills locally (no-op, Firestore handles caching)
  static Future<void> cacheBills(List<BillModel> bills) async {
    debugPrint('cacheBills: Firestore handles caching, ${bills.length} bills');
  }

  /// Get cached bills
  static List<BillModel> getCachedBills() {
    return [];
  }

  /// Get all bills (uses server when online, cache when offline)
  static Future<List<BillModel>> getCachedBillsAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/bills')
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitBills)
          .get();
      UserUsageService.trackRead(count: snapshot.docs.length);
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting bills: $e');
      return [];
    }
  }

  /// Get cached bills in date range
  static Future<List<BillModel>> getCachedBillsInRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/bills')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .limit(1000)
          .get();
      UserUsageService.trackRead(count: snapshot.docs.length);
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting bills in range: $e');
      return [];
    }
  }

  /// Save bill
  static Future<void> saveBill(BillModel bill) async {
    if (_basePath.isEmpty) return;
    final write = _firestore
        .doc('$_basePath/bills/${bill.id}')
        .set(bill.toFirestore());
    if (ConnectivityService.isOffline) {
      // Fire-and-forget when offline — SDK queues the write and syncs when online
      unawaited(write);
    } else {
      // When online, await with timeout so we don't block indefinitely
      await write.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // Timeout — write is still queued by SDK, proceed without blocking
          debugPrint('⚠️ saveBill: write timeout, queued for sync');
        },
      );
    }
    UserUsageService.trackWrite();
  }

  /// Get next sequential bill number using Firestore atomic counter.
  /// Uses runTransaction for atomic read-increment-return to prevent
  /// duplicate bill numbers from concurrent calls.
  /// Falls back to random bill number if Firestore access fails.
  static Future<int> getNextBillNumber() async {
    if (_basePath.isEmpty) return generateBillNumber();

    // Scoped per hotel so multi-hotel bill counters do not collide
    final counterKey = 'local_bill_counter_${_basePath.hashCode}';

    // When offline, use local counter immediately — do not attempt server calls
    // (runTransaction hangs indefinitely on web when offline)
    if (ConnectivityService.isOffline) {
      final local = prefs?.getInt(counterKey) ?? 0;
      if (local > 0) {
        final next = local + 1;
        await prefs?.setInt(counterKey, next);
        debugPrint('Offline bill number: $next (will sync when online)');
        return next;
      }
      return generateBillNumber();
    }

    try {
      final counterRef = _firestore.doc('$_basePath/counters/billing');

      // On Windows, avoid runTransaction — the C++ Firestore SDK sends
      // callbacks on non-platform threads, crashing Flutter.
      if (!kIsWeb && Platform.isWindows) {
        final snapshot = await counterRef.get();
        final current = (snapshot.data()?['billNumber'] as int?) ?? 1000;
        final next = current + 1;
        await counterRef.set({'billNumber': next}, SetOptions(merge: true));
        UserUsageService.trackRead();
        UserUsageService.trackWrite();
        await prefs?.setInt(counterKey, next);
        return next;
      }

      final newBillNumber = await _firestore.runTransaction<int>((
        transaction,
      ) async {
        final snapshot = await transaction.get(counterRef);
        final current = (snapshot.data()?['billNumber'] as int?) ?? 1000;
        final next = current + 1;
        transaction.set(counterRef, {
          'billNumber': next,
        }, SetOptions(merge: true));
        return next;
      }).timeout(const Duration(seconds: 5));
      UserUsageService.trackRead();
      UserUsageService.trackWrite();
      await prefs?.setInt(counterKey, newBillNumber);
      return newBillNumber;
    } catch (e) {
      // Firestore unreachable — use locally cached counter for sequential numbers
      debugPrint('Bill counter fallback (offline/timeout): $e');
      final local = prefs?.getInt(counterKey) ?? 0;
      if (local > 0) {
        final next = local + 1;
        await prefs?.setInt(counterKey, next);
        return next;
      }
      return generateBillNumber();
    }
  }

    /// Save bill locally (alias for saveBill for backward compatibility)
  static Future<void> saveBillLocally(BillModel bill) async {
    await saveBill(bill);
  }

  /// Atomically save a bill + update customer balance + create transaction
  /// for Udhar payments. Uses WriteBatch so all three writes succeed or fail together.
  static Future<void> saveBillWithUdharAtomic({
    required BillModel bill,
    required String customerId,
    required double amount,
  }) async {
    if (_basePath.isEmpty) return;
    final batch = _firestore.batch();

    // 1. Save the bill
    batch.set(
      _firestore.doc('$_basePath/bills/${bill.id}'),
      bill.toFirestore(),
    );

    // 2. Update customer balance (increase for udhar/credit)
    batch.update(_firestore.doc('$_basePath/customers/$customerId'), {
      'balance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Create transaction record
    final txnId = generateSafeId('txn');
    final transaction = TransactionModel(
      id: txnId,
      customerId: customerId,
      type: TransactionType.purchase,
      amount: amount,
      billId: bill.id,
      createdAt: DateTime.now(),
    );
    batch.set(
      _firestore.doc('$_basePath/transactions/$txnId'),
      transaction.toFirestore(),
    );

    // Atomic commit — queued offline by SDK, synced when online
    final batchCommit = batch.commit();
    if (ConnectivityService.isOffline) {
      unawaited(batchCommit);
    } else {
      await batchCommit.timeout(const Duration(seconds: 8),
          onTimeout: () => debugPrint('udhar batch timeout, queued'));
    }
  }

  /// Stream of all bills (real-time updates from Firestore)
  /// Accepts optional [dateRange] and [paymentMethod] for server-side filtering.
  static Stream<List<BillModel>> billsStream({
    DateTimeRange? dateRange,
    String? paymentMethod,
  }) {
    if (_basePath.isEmpty) return Stream.value([]);
    Query<Map<String, dynamic>> query = _firestore.collection(
      '$_basePath/bills',
    );

    // Equality filters first (Firestore requires equality before range/orderBy)
    if (paymentMethod != null) {
      query = query.where('paymentMethod', isEqualTo: paymentMethod);
    }

    query = query.orderBy('createdAt', descending: true);

    // Server-side date filter
    if (dateRange != null) {
      query = query
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(
              dateRange.end.add(const Duration(days: 1)),
            ),
          );
    }

    query = query.limit(AppConstants.queryLimitBills);

    return safeSnapshots(query).map((snapshot) {
      final bills = snapshot.docs
          .map((doc) => BillModel.fromFirestore(doc))
          .toList();
      // Report sync status
      final pendingCount = snapshot.docs
          .where((d) => d.metadata.hasPendingWrites)
          .length;
      SyncStatusService.updateCollection(
        'bills',
        totalDocs: bills.length,
        unsyncedDocs: pendingCount,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
      return bills;
    });
  }

  /// Paginated bills fetch â€” returns (bills, lastDocument) for cursor pagination.
  /// Pass [startAfter] from a previous call to load the next page.
  static Future<(List<BillModel>, DocumentSnapshot?)> fetchBillsPage({
    int pageSize = 50,
    DocumentSnapshot? startAfter,
  }) async {
    if (_basePath.isEmpty) return (<BillModel>[], null);
    var query = _firestore
        .collection('$_basePath/bills')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    UserUsageService.trackRead(count: snap.docs.length);
    final bills = snap.docs.map((d) => BillModel.fromFirestore(d)).toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (bills, lastDoc);
  }

  /// Stream of bills in a date range (real-time)
  static Stream<List<BillModel>> billsInRangeStream(
    DateTime start,
    DateTime end,
  ) {
    if (_basePath.isEmpty) return Stream.value([]);
    return safeSnapshots(
      _firestore
          .collection('$_basePath/bills')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitBills),
    ).map(
      (snapshot) =>
          snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList(),
    );
  }

  /// Delete old bills (data retention) â€” processes in batches of 400
  /// to stay under Firestore's 500-operation batch limit.
  static Future<int> deleteOldBills(DateTime before) async {
    if (_basePath.isEmpty) return 0;
    int totalDeleted = 0;
    final query = _firestore
        .collection('$_basePath/bills')
        .where('createdAt', isLessThan: Timestamp.fromDate(before));

    while (true) {
      final snapshot = await query.limit(400).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      UserUsageService.trackRead(count: snapshot.docs.length);
      UserUsageService.trackDelete(count: snapshot.docs.length);
      totalDeleted += snapshot.docs.length;
    }
    return totalDeleted;
  }

  // ==================== Expenses ====================

  /// Save expense
  static Future<void> saveExpense(ExpenseModel expense) async {
    if (_basePath.isEmpty) return;
    await _firestore
        .doc('$_basePath/expenses/${expense.id}')
        .set(expense.toFirestore());
    UserUsageService.trackWrite();
  }

  /// Get all expenses (uses server when online, cache when offline)
  static Future<List<ExpenseModel>> getCachedExpensesAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/expenses')
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitExpenses)
          .get();
      UserUsageService.trackRead(count: snapshot.docs.length);
      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting expenses: $e');
      return [];
    }
  }

    /// Delete expense
  static Future<void> deleteExpense(String expenseId) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/expenses/$expenseId').delete();
    UserUsageService.trackDelete();
  }

  /// Stream of all expenses (real-time updates from Firestore)
  /// Accepts optional [dateRange] and [paymentMethod] for server-side filtering.
  static Stream<List<ExpenseModel>> expensesStream({
    DateTimeRange? dateRange,
    String? paymentMethod,
  }) {
    if (_basePath.isEmpty) return Stream.value([]);
    Query<Map<String, dynamic>> query = _firestore.collection(
      '$_basePath/expenses',
    );

    // Equality filters first (Firestore requires equality before range/orderBy)
    if (paymentMethod != null) {
      query = query.where('paymentMethod', isEqualTo: paymentMethod);
    }

    query = query.orderBy('createdAt', descending: true);

    // Server-side date filter
    if (dateRange != null) {
      query = query
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(
              dateRange.end.add(const Duration(days: 1)),
            ),
          );
    }

    query = query.limit(AppConstants.queryLimitExpenses);

    return safeSnapshots(query).map((snapshot) {
      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
      // Report sync status
      final pendingCount = snapshot.docs
          .where((d) => d.metadata.hasPendingWrites)
          .length;
      SyncStatusService.updateCollection(
        'expenses',
        totalDocs: expenses.length,
        unsyncedDocs: pendingCount,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
      return expenses;
    });
  }

  /// Paginated expenses fetch â€” returns (expenses, lastDocument) for cursor pagination.
  static Future<(List<ExpenseModel>, DocumentSnapshot?)> fetchExpensesPage({
    int pageSize = 50,
    DocumentSnapshot? startAfter,
  }) async {
    if (_basePath.isEmpty) return (<ExpenseModel>[], null);
    var query = _firestore
        .collection('$_basePath/expenses')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    UserUsageService.trackRead(count: snap.docs.length);
    final expenses = snap.docs
        .map((d) => ExpenseModel.fromFirestore(d))
        .toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (expenses, lastDoc);
  }

  // ==================== Customers ====================

  /// Cache customers (no-op)
  static Future<void> cacheCustomers(List<CustomerModel> customers) async {
    debugPrint(
      'cacheCustomers: Firestore handles caching, ${customers.length} customers',
    );
  }

  /// Get cached customers
  static List<CustomerModel> getCachedCustomers() {
    return [];
  }

  /// Get cached customers async (uses default source for immediate consistency)
  static Future<List<CustomerModel>> getCachedCustomersAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      // D10: Add limit to prevent reading unbounded customer lists
      final snapshot = await _firestore
          .collection('$_basePath/customers')
          .limit(1000)
          .get();
      UserUsageService.trackRead(count: snapshot.docs.length);
      return snapshot.docs
          .map((doc) => CustomerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get single cached customer async
  static Future<CustomerModel?> getCachedCustomerAsync(
    String customerId,
  ) async {
    if (_basePath.isEmpty) return null;
    try {
      final doc = await _firestore
          .doc('$_basePath/customers/$customerId')
          .get();
      UserUsageService.trackRead();
      if (!doc.exists) return null;
      return CustomerModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Save customer
  static Future<void> saveCustomer(CustomerModel customer) async {
    if (_basePath.isEmpty) return;
    final write = _firestore
        .doc('$_basePath/customers/${customer.id}')
        .set(customer.toFirestore());
    if (ConnectivityService.isOffline) {
      unawaited(write);
    } else {
      await write.timeout(const Duration(seconds: 8),
          onTimeout: () => debugPrint('saveCustomer timeout, queued'));
    }
    UserUsageService.trackWrite();
  }

  /// Update cached customer
  static Future<void> updateCachedCustomer(CustomerModel customer) async {
    await saveCustomer(customer);
  }

  /// Delete customer
  static Future<void> deleteCustomer(String customerId) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/customers/$customerId').delete();
    UserUsageService.trackDelete();
  }

  /// Update customer balance by delta (positive = increase, negative = decrease)
  static Future<void> updateCustomerBalance(
    String customerId,
    double delta,
  ) async {
    if (_basePath.isEmpty) return;
    final write = _firestore.doc('$_basePath/customers/$customerId').update({
      'balance': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (ConnectivityService.isOffline) {
      unawaited(write);
    } else {
      await write.timeout(const Duration(seconds: 8),
          onTimeout: () => debugPrint('updateCustomerBalance timeout, queued'));
    }
    UserUsageService.trackWrite();
  }

  /// Atomically update customer balance AND save a transaction in a single
  /// WriteBatch. This prevents data corruption if the app crashes mid-write.
  static Future<void> recordPaymentAtomic({
    required String customerId,
    required double amount,
    String? note,
    String paymentMode = 'cash',
  }) async {
    if (_basePath.isEmpty) return;
    final batch = _firestore.batch();

    // 1. Update customer balance (subtract payment)
    batch.update(_firestore.doc('$_basePath/customers/$customerId'), {
      'balance': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create transaction record
    final txnId = generateSafeId('txn');
    final transaction = TransactionModel(
      id: txnId,
      customerId: customerId,
      type: TransactionType.payment,
      amount: amount,
      note: note ?? paymentMode,
      paymentMode: paymentMode,
      createdAt: DateTime.now(),
    );
    batch.set(
      _firestore.doc('$_basePath/transactions/$txnId'),
      transaction.toFirestore(),
    );

    // Atomic commit — queued offline by SDK, synced when online
    final commit = batch.commit();
    if (ConnectivityService.isOffline) {
      unawaited(commit);
    } else {
      await commit.timeout(const Duration(seconds: 8),
          onTimeout: () => debugPrint('recordPaymentAtomic timeout, queued'));
    }
    UserUsageService.trackWrite(count: 2);
  }

  /// Atomically update customer balance AND save a credit transaction.
  static Future<void> addCreditAtomic({
    required String customerId,
    required double amount,
    String? billId,
    String? note,
  }) async {
    if (_basePath.isEmpty) return;
    final batch = _firestore.batch();

    // 1. Update customer balance (add credit)
    batch.update(_firestore.doc('$_basePath/customers/$customerId'), {
      'balance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create transaction record
    final txnId = generateSafeId('txn');
    final transaction = TransactionModel(
      id: txnId,
      customerId: customerId,
      type: TransactionType.purchase,
      amount: amount,
      note: note ?? 'Credit given',
      billId: billId,
      createdAt: DateTime.now(),
    );
    batch.set(
      _firestore.doc('$_basePath/transactions/$txnId'),
      transaction.toFirestore(),
    );

    // Atomic commit — queued offline by SDK, synced when online
    final commit = batch.commit();
    if (ConnectivityService.isOffline) {
      unawaited(commit);
    } else {
      await commit.timeout(const Duration(seconds: 8),
          onTimeout: () => debugPrint('addCreditAtomic timeout, queued'));
    }
    UserUsageService.trackWrite(count: 2);
  }

  /// Stream of all customers (real-time updates from Firestore)
  static Stream<List<CustomerModel>> customersStream() {
    if (_basePath.isEmpty) return Stream.value([]);
    return safeSnapshots(
      _firestore
          .collection('$_basePath/customers')
          .limit(AppConstants.queryLimitCustomers),
    ).map((snapshot) {
      final customers = snapshot.docs
          .map((doc) => CustomerModel.fromFirestore(doc))
          .toList();
      // Report sync status
      final pendingCount = snapshot.docs
          .where((d) => d.metadata.hasPendingWrites)
          .length;
      SyncStatusService.updateCollection(
        'customers',
        totalDocs: customers.length,
        unsyncedDocs: pendingCount,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
      return customers;
    });
  }

  /// Paginated customers fetch â€” returns (customers, lastDocument) for cursor pagination.
  static Future<(List<CustomerModel>, DocumentSnapshot?)> fetchCustomersPage({
    int pageSize = 50,
    DocumentSnapshot? startAfter,
  }) async {
    if (_basePath.isEmpty) return (<CustomerModel>[], null);
    var query = _firestore
        .collection('$_basePath/customers')
        .orderBy('name')
        .limit(pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    UserUsageService.trackRead(count: snap.docs.length);
    final customers = snap.docs
        .map((d) => CustomerModel.fromFirestore(d))
        .toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (customers, lastDoc);
  }

  /// Stream of a single customer (real-time)
  static Stream<CustomerModel?> customerStream(String customerId) {
    if (_basePath.isEmpty) return Stream.value(null);
    return safeDocSnapshots(
      _firestore.doc('$_basePath/customers/$customerId'),
    ).map((doc) => doc.exists ? CustomerModel.fromFirestore(doc) : null);
  }

  // ==================== Transactions ====================

  /// Save transaction (for Khata) - accepts TransactionModel
  static Future<void> saveTransactionModel(TransactionModel transaction) async {
    if (_basePath.isEmpty) return;
    await _firestore
        .doc('$_basePath/transactions/${transaction.id}')
        .set(transaction.toFirestore());
    UserUsageService.trackWrite();
  }

  /// Save transaction with named parameters (convenience method)
  static Future<void> saveTransaction({
    required String customerId,
    required String type,
    required double amount,
    String? billId,
    String? note,
    String? paymentMode,
  }) async {
    if (_basePath.isEmpty) return;

    final transaction = TransactionModel(
      id: generateSafeId('txn'),
      customerId: customerId,
      type: type == 'payment'
          ? TransactionType.payment
          : TransactionType.purchase,
      amount: amount,
      billId: billId,
      note: note,
      paymentMode: paymentMode,
      createdAt: DateTime.now(),
    );

    final write = _firestore
        .doc('$_basePath/transactions/${transaction.id}')
        .set(transaction.toFirestore());
    if (ConnectivityService.isOffline) {
      unawaited(write);
    } else {
      await write.timeout(const Duration(seconds: 8),
          onTimeout: () => debugPrint('saveTransaction timeout, queued'));
    }
    UserUsageService.trackWrite();
  }

  /// Get customer transactions
  static Future<List<TransactionModel>> getCustomerTransactions(
    String customerId,
  ) async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/transactions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      UserUsageService.trackRead(count: snapshot.docs.length);
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get total payment amount collected today (single query, no N+1)
  static Future<double> getTodayPaymentTotal() async {
    if (_basePath.isEmpty) return 0;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _firestore
          .collection('$_basePath/transactions')
          .where('type', isEqualTo: 'payment')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('createdAt', descending: true)
          .get();
      UserUsageService.trackRead(count: snapshot.docs.length);
      return snapshot.docs.fold<double>(0, (total, doc) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        return total + amount;
      });
    } catch (e) {
      debugPrint('âŒ getTodayPaymentTotal error: $e');
      return 0;
    }
  }

  /// Stream of customer transactions (real-time)
  static Stream<List<TransactionModel>> customerTransactionsStream(
    String customerId,
  ) {
    if (_basePath.isEmpty) return Stream.value([]);
    return safeSnapshots(
      _firestore
          .collection('$_basePath/transactions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitTransactions),
    ).map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      // Report sync status
      final pendingCount = snapshot.docs
          .where((d) => d.metadata.hasPendingWrites)
          .length;
      SyncStatusService.updateCollection(
        'transactions',
        totalDocs: transactions.length,
        unsyncedDocs: pendingCount,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
      return transactions;
    });
  }

  // ==================== Sync Status Streams ====================

  /// Stream of per-document sync status for bills
  /// Only tracks documents with hasPendingWrites=true to keep the map bounded.
  static Stream<Map<String, bool>> billsSyncStream() {
    if (_basePath.isEmpty) return Stream.value({});
    return safeSnapshots(
      _firestore
          .collection('$_basePath/bills')
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitBills),
    ).map(
      (snapshot) => {
        for (final doc in snapshot.docs)
          if (doc.metadata.hasPendingWrites) doc.id: true,
      },
    );
  }

  /// Stream of per-document sync status for customers
  /// Only tracks documents with hasPendingWrites=true to keep the map bounded.
  static Stream<Map<String, bool>> customersSyncStream() {
    if (_basePath.isEmpty) return Stream.value({});
    return safeSnapshots(
      _firestore
          .collection('$_basePath/customers')
          .limit(AppConstants.queryLimitCustomers),
    ).map(
      (snapshot) => {
        for (final doc in snapshot.docs)
          if (doc.metadata.hasPendingWrites) doc.id: true,
      },
    );
  }

  /// Stream of per-document sync status for expenses
  /// Only tracks documents with hasPendingWrites=true to keep the map bounded.
  static Stream<Map<String, bool>> expensesSyncStream() {
    if (_basePath.isEmpty) return Stream.value({});
    return safeSnapshots(
      _firestore
          .collection('$_basePath/expenses')
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitExpenses),
    ).map(
      (snapshot) => {
        for (final doc in snapshot.docs)
          if (doc.metadata.hasPendingWrites) doc.id: true,
      },
    );
  }

  // ==================== Settings ====================

  /// Check if data is initialized
  static bool isDataInitialized() {
    return _prefs?.getBool(SettingsKeys.dataInitialized) ?? false;
  }

  /// Mark data as initialized
  static Future<void> markDataInitialized() async {
    await _prefs?.setBool(SettingsKeys.dataInitialized, true);
  }

  /// Get setting from local SharedPreferences (for backward compatibility)
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _prefs?.get(key);
    if (value == null) return defaultValue;
    // Handle Map types stored as JSON strings
    if (T == dynamic || value is T) {
      return value as T?;
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is T) return decoded;
      } catch (_) {
        // Not valid JSON, return as-is or default
      }
    }
    return defaultValue;
  }

  /// Save setting to both Firestore (for sync) and SharedPreferences (for local cache)
  static Future<void> saveSetting<T>(String key, T value) async {
    _prefs ??= await SharedPreferences.getInstance();

    // Save to SharedPreferences for local cache
    if (value is String) {
      await _prefs?.setString(key, value);
    } else if (value is int) {
      await _prefs?.setInt(key, value);
    } else if (value is double) {
      await _prefs?.setDouble(key, value);
    } else if (value is bool) {
      await _prefs?.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs?.setStringList(key, value);
    } else if (value is Map<String, dynamic>) {
      // For maps, store as JSON string locally
      await _prefs?.setString(key, jsonEncode(value));
    }

    // Also save to Firestore for cross-device sync
    await saveSettingToCloud(key, value);
  }

  /// Save setting to Firestore for cloud sync
  static Future<void> saveSettingToCloud<T>(String key, T value) async {
    if (_basePath.isEmpty) return;
    try {
      await _firestore
          .doc('$_basePath/settings/user_settings')
          .set({key: value}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
      UserUsageService.trackWrite();
    } catch (e) {
      debugPrint('Error saving setting to cloud: $e');
    }
  }

  /// Get setting from Firestore (async, for cloud sync)
  static Future<T?> getSettingFromCloud<T>(String key) async {
    if (_basePath.isEmpty) return null;
    try {
      final doc = await _firestore
          .doc('$_basePath/settings/user_settings')
          .get()
          .timeout(const Duration(seconds: 5));
      UserUsageService.trackRead();
      if (!doc.exists) return null;
      return doc.data()?[key] as T?;
    } catch (e) {
      debugPrint('Error getting setting from cloud: $e');
      return null;
    }
  }

  /// Load all settings from cloud and cache locally
  static Future<Map<String, dynamic>> loadAllSettingsFromCloud() async {
    if (_basePath.isEmpty) return {};
    try {
      final doc = await _firestore
          .doc('$_basePath/settings/user_settings')
          .get()
          .timeout(const Duration(seconds: 5));
      UserUsageService.trackRead();
      if (!doc.exists) return {};
      final data = doc.data() ?? {};

      // Cache to SharedPreferences
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is String) {
          await _prefs?.setString(entry.key, value);
        } else if (value is int) {
          await _prefs?.setInt(entry.key, value);
        } else if (value is double) {
          await _prefs?.setDouble(entry.key, value);
        } else if (value is bool) {
          await _prefs?.setBool(entry.key, value);
        } else if (value is Map) {
          // Cache maps as JSON strings (matches saveSetting behavior)
          await _prefs?.setString(entry.key, jsonEncode(value));
        }
      }

      return data;
    } catch (e) {
      debugPrint('Error loading settings from cloud: $e');
      return {};
    }
  }

  /// Set setting (alias for saveSetting)
  static Future<void> setSetting<T>(String key, T value) async {
    await saveSetting(key, value);
  }

  // ==================== Usage Metrics ====================

  /// Log usage metric
  static Future<void> logUsageMetric(String metricName, int value) async {
    final key = 'usage_$metricName';
    final current = _prefs?.getInt(key) ?? 0;
    await _prefs?.setInt(key, current + value);
  }

  /// Get usage metric
  static int getUsageMetric(String metricName) {
    return _prefs?.getInt('usage_$metricName') ?? 0;
  }

  // ==================== Storage Stats ====================

  /// Get storage stats
  static Future<Map<String, int>> getStorageStats() async {
    return {'products': 0, 'bills': 0, 'customers': 0, 'total': 0};
  }

  /// Clear all local cache
  static Future<void> clearAll() async {
    await _prefs?.clear();
    debugPrint('âœ… clearAll: SharedPreferences cleared');
  }

  /// Clear user-specific local settings on sign-out
  /// Preserves device-level settings (printer config) but clears user data flags
  static Future<void> clearUserLocalSettings() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Keys that are user-specific and should be cleared on sign-out
    final userKeys = [
      SettingsKeys.dataInitialized,
      SettingsKeys.isDarkMode,
      SettingsKeys.language,
      SettingsKeys.retentionDays,
      SettingsKeys.lastCleanupTime,
      SettingsKeys.lastExportTime,
      SettingsKeys.autoCleanupEnabled,
      SettingsKeys.settings,
      // User metrics keys (prevent bill count / user ID leaking between users)
      'bills_this_month',
      'last_reset_month',
      'user_id',
      // Theme settings (each user has their own theme)
      'theme_settings',
      'theme_is_dark',
      'theme_use_system',
      // Route persistence (each user may have different last page)
      'last_route',
    ];

    // Also clear any usage metrics and sync metadata
    final allKeys = _prefs?.getKeys() ?? {};
    for (final key in allKeys) {
      if (key.startsWith('usage_') ||
          key.startsWith('sync_') ||
          key.startsWith('last_sync') ||
          key.startsWith('pending_sync') ||
          userKeys.contains(key)) {
        await _prefs?.remove(key);
      }
    }
    debugPrint('âœ… User-specific local settings cleared');
  }

  /// Clear demo data (used when exiting demo mode)
  static Future<void> clearDemoData() async {
    debugPrint('clearDemoData: Clearing local demo preferences');
    await _prefs?.clear();
  }
}
