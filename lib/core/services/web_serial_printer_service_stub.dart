/// Stub implementation for non-web platforms.
///
/// All methods return false / no-op since Web Serial
/// is not available outside of a browser.
library;

import 'dart:typed_data';

import 'package:tulasihotels/models/bill_model.dart';

class WebSerialPrinterService {
  WebSerialPrinterService._();

  static bool get isSupported => false;
  static bool get isConnected => false;
  static bool get hasPort => false;
  static String get connectedPortName => '';

  static Future<bool> connect({int baudRate = 9600}) async => false;
  static void disconnect() {}
  static Future<void> setCustomName(String name) async {}
  static Future<bool> sendBytes(List<int> bytes) async => false;

  static Future<bool> printReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
    String? upiId,
    double? taxRate,
    bool partialCut = false,
    bool isHindi = false,
    String? copyLabel,
    bool showHsnOnReceipt = false,
    Uint8List? logoBytes,
  }) async => false;

  static Future<bool> printTestPage() async => false;
}
