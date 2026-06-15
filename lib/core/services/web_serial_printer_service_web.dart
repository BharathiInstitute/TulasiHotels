/// Web Serial printer service for Chrome-based USB-serial printing.
///
/// Uses the Web Serial API (`navigator.serial`) to communicate with
/// thermal printers connected via USB/serial-over-USB from the browser.
///
/// **Limitations**:
/// - Chrome/Edge only
/// - Requires HTTPS or localhost
/// - User must grant port access each session
/// - Only available on web platform
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/services/thermal_printer_service.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:web/web.dart' as web;

class WebSerialPrinterService {
  WebSerialPrinterService._();

  static JSObject? _port;
  static JSObject? _writer;
  static bool _connected = false;
  static String _connectedPortName = '';

  static bool get hasPort => _port != null;

  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      final nav = web.window.navigator as JSObject;
      final serial = nav['serial'];
      return serial != null && serial.isA<JSObject>();
    } catch (_) {
      return false;
    }
  }

  static bool get isConnected => _connected && _writer != null;

  static String get connectedPortName => _connectedPortName;

  /// Request a serial port and open the connection.
  static Future<bool> connect({int baudRate = 9600}) async {
    if (!isSupported) return false;

    disconnect();

    try {
      final nav = web.window.navigator as JSObject;
      final serial = nav['serial']! as JSObject;

      // User picks a port from the browser dialog
      final port =
          await (serial.callMethod('requestPort'.toJS, {}.jsify()!)
                  as JSPromise<JSObject>)
              .toDart;

      _port = port;

      // Open with specified baud rate
      await (port.callMethod('open'.toJS, {'baudRate': baudRate}.jsify()!)
              as JSPromise)
          .toDart;

      // Get a writer for the writable stream
      final writable = port['writable']! as JSObject;
      _writer = writable.callMethod('getWriter'.toJS) as JSObject;

      _connected = true;
      _connectedPortName = 'Serial Port';

      // Try to get port info for naming
      try {
        final info = port.callMethod('getInfo'.toJS) as JSObject;
        final vendorId = info['usbVendorId'];
        final productId = info['usbProductId'];
        if (vendorId != null) {
          _connectedPortName =
              'USB Serial (VID:${(vendorId as JSNumber).toDartInt.toRadixString(16).padLeft(4, '0')}'
              ':PID:${productId != null ? (productId as JSNumber).toDartInt.toRadixString(16).padLeft(4, '0') : '????'})';
        }
      } catch (_) {}

      debugPrint('Web Serial: Connected to $_connectedPortName');
      return true;
    } catch (e) {
      debugPrint('Web Serial connect error: $e');
      _connected = false;
      _writer = null;
      _port = null;
      return false;
    }
  }

  /// Disconnect from the serial port.
  static void disconnect() {
    try {
      if (_writer != null) {
        _writer!.callMethod('releaseLock'.toJS);
      }
    } catch (_) {}
    _writer = null;

    try {
      if (_port != null) {
        (_port!.callMethod('close'.toJS) as JSPromise).toDart.catchError(
          (_) => null,
        );
      }
    } catch (_) {}
    _port = null;
    _connected = false;
    _connectedPortName = '';
  }

  /// Send raw bytes to the connected printer.
  static Future<bool> sendBytes(List<int> bytes) async {
    if (_writer == null) return false;

    try {
      final data = Uint8List.fromList(bytes);
      // Send in 512-byte chunks to avoid buffer overflows
      const chunkSize = 512;
      for (var offset = 0; offset < data.length; offset += chunkSize) {
        final end = (offset + chunkSize > data.length)
            ? data.length
            : offset + chunkSize;
        final chunk = Uint8List.fromList(data.sublist(offset, end));
        await (_writer!.callMethod('write'.toJS, chunk.toJS) as JSPromise)
            .toDart;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return true;
    } catch (e) {
      debugPrint('Web Serial send error: $e');
      _connected = false;
      _writer = null;
      return false;
    }
  }

  /// Print a receipt via Web Serial using the shared ESC/POS builder.
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
  }) async {
    final bytes = EscPosBuilder.buildReceipt(
      bill: bill,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      gstNumber: gstNumber,
      receiptFooter: receiptFooter,
    );
    return sendBytes(bytes);
  }

  /// Print a test page.
  static Future<bool> printTestPage() async {
    return sendBytes(EscPosBuilder.buildTestPage());
  }
}
