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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulasihotels/core/services/thermal_printer_service.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:web/web.dart' as web;

class WebSerialPrinterService {
  WebSerialPrinterService._();

  static JSObject? _port;
  static JSObject? _writer;
  static bool _connected = false;
  static String _connectedPortName = '';
  static const _prefsKey = 'web_serial_printer_name';

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
      _connectedPortName = 'USB Printer';

      // Try to load saved printer name from prefs
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString(_prefsKey);
        if (savedName != null && savedName.isNotEmpty) {
          _connectedPortName = savedName;
        }
      } catch (_) {}

      // If no saved name, try to get port info for vendor-based naming
      if (_connectedPortName == 'USB Printer') {
        try {
          final info = port.callMethod('getInfo'.toJS) as JSObject;
          final vendorId = info['usbVendorId'];
          final productId = info['usbProductId'];
          if (vendorId != null) {
            final vid = (vendorId as JSNumber).toDartInt;
            final pid = productId != null ? (productId as JSNumber).toDartInt : 0;
            _connectedPortName = _lookupPrinterName(vid, pid);
          }
        } catch (_) {}

        // Try to query the printer's model name via ESC/POS GS I command
        final modelName = await _queryPrinterModel(port);
        if (modelName != null && modelName.isNotEmpty) {
          _connectedPortName = modelName;
        }
      }

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

  /// Set a custom name for the connected printer (persisted).
  static Future<void> setCustomName(String name) async {
    if (name.trim().isEmpty) return;
    _connectedPortName = name.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _connectedPortName);
    } catch (_) {}
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

  /// Query printer model name via ESC/POS GS I command.
  /// Sends GS I 1 (get printer model) and reads the response.
  static Future<String?> _queryPrinterModel(JSObject port) async {
    try {
      final readable = port['readable'];
      if (readable == null) return null;

      final reader = (readable as JSObject).callMethod('getReader'.toJS) as JSObject;

      try {
        // Send GS I 1 (0x1D 0x49 0x01) — Get Printer Model ID
        // Some printers respond to GS I 67 (0x1D 0x49 0x43) for model name
        final cmd = Uint8List.fromList([0x1D, 0x49, 0x43]);
        await (_writer!.callMethod('write'.toJS, cmd.toJS) as JSPromise).toDart;

        // Wait briefly for response
        final result = await (reader.callMethod('read'.toJS) as JSPromise<JSObject>)
            .toDart
            .timeout(const Duration(seconds: 2), onTimeout: () => throw TimeoutException(''));

        final done = result['done'];
        if (done != null && (done as JSBoolean).toDart) return null;

        final value = result['value'];
        if (value == null) return null;

        final bytes = (value as JSUint8Array).toDart;
        if (bytes.isEmpty) return null;

        // Parse response — strip control chars, get printable ASCII
        final name = String.fromCharCodes(
          bytes.where((b) => b >= 32 && b < 127),
        ).trim();

        if (name.length >= 2) {
          debugPrint('Web Serial: Printer model query returned: $name');
          return name;
        }
      } finally {
        try {
          reader.callMethod('releaseLock'.toJS);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Web Serial: Model query failed (normal for some printers): $e');
    }
    return null;
  }

  /// Lookup a human-readable printer name from USB VID/PID.
  static String _lookupPrinterName(int vid, int pid) {
    // Common thermal printer USB vendor IDs
    const vendorNames = <int, String>{
      0x0416: 'WinChipHead',       // CH340 (common USB-serial chip in thermal printers)
      0x1A86: 'QinHeng CH340',     // CH340/CH341
      0x067B: 'Prolific PL2303',   // Prolific USB-Serial
      0x0403: 'FTDI',             // FTDI USB-Serial
      0x10C4: 'Silicon Labs',      // CP210x
      0x04B8: 'Epson',
      0x04F9: 'Brother',
      0x0DD4: 'Custom SPA',       // Custom thermal
      0x0FE6: 'ICS',              // Kontron/ICS
      0x0B00: 'MPT',              // Milestone Printer Technology
      0x0493: 'Milestone',
      0x0483: 'STMicroelectronics', // Common in Chinese thermal printers
      0x20D1: 'Rongta',
      0x2730: 'Citizen',
      0x28E9: 'GoDEX',
      0x0519: 'Star Micronics',
      0x154F: 'SNBC',             // Beiyang/SNBC
    };

    final name = vendorNames[vid];
    if (name != null) return name;
    return 'USB Printer (${vid.toRadixString(16).padLeft(4, '0')}:${pid.toRadixString(16).padLeft(4, '0')})';
  }
}
