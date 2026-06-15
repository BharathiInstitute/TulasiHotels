/// Web Bluetooth printer service for Chrome-based printing
///
/// Uses the Web Bluetooth API (`navigator.bluetooth`) to connect
/// directly to Bluetooth thermal printers from the browser.
///
/// **Limitations**:
/// - Chrome/Edge only (no Firefox/Safari)
/// - Requires HTTPS or localhost
/// - User must pair device each session (no auto-reconnect across sessions)
/// - Only available on web platform
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/services/thermal_printer_service.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:web/web.dart' as web;

/// Known service/characteristic UUIDs used by various thermal printer brands
const _altServiceUuids = [
  '000018f0-0000-1000-8000-00805f9b34fb', // Standard SPP
  'e7810a71-73ae-499d-8c15-faa9aef0c3f2', // Epson/Star-compatible
  '49535343-fe7d-4ae5-8fa9-9fafd205e455', // Zebra/Honeywell
  '0000ff00-0000-1000-8000-00805f9b34fb', // Generic vendor service
  '0000ffe0-0000-1000-8000-00805f9b34fb', // HM-10 style BLE
];
const _altCharUuids = [
  '00002af1-0000-1000-8000-00805f9b34fb', // Standard SPP write char
  'bef8d6c9-9c21-4c9e-b632-bd58c1009f9f', // Epson/Star write char
  '49535343-8841-43f4-a8d4-ecbe34729bb3', // Zebra/Honeywell write char
  '0000ff02-0000-1000-8000-00805f9b34fb', // Generic vendor write
  '0000ffe1-0000-1000-8000-00805f9b34fb', // HM-10 write char
];

/// Service for printing via Chrome Web Bluetooth API.
class WebBluetoothPrinterService {
  WebBluetoothPrinterService._();

  static JSObject? _device;
  static JSObject? _characteristic;
  static bool _connected = false;
  static String _connectedDeviceName = '';
  static bool _reconnecting = false;
  static JSFunction? _disconnectCallback;

  static bool get hasDevice => _device != null;

  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      final nav = web.window.navigator as JSObject;
      final bt = nav['bluetooth'];
      return bt != null && bt.isA<JSObject>();
    } catch (_) {
      return false;
    }
  }

  static bool get isConnected => _connected && _characteristic != null;

  static String get connectedDeviceName => _connectedDeviceName;

  /// Request a Bluetooth printer and connect to it.
  static Future<bool> connect() async {
    if (!isSupported) return false;

    // Tear down any existing connection
    _connected = false;
    _characteristic = null;
    _connectedDeviceName = '';
    if (_device != null) {
      try {
        final gatt = _device!['gatt'] as JSObject?;
        gatt?.callMethod('disconnect'.toJS);
      } catch (_) {}
      _device = null;
    }

    try {
      final nav = web.window.navigator as JSObject;
      final bluetooth = nav['bluetooth']! as JSObject;

      final options = {
        'acceptAllDevices': true,
        'optionalServices': [..._altServiceUuids, ..._altCharUuids],
      }.jsify()!;

      final device =
          await (bluetooth.callMethod('requestDevice'.toJS, options)
                  as JSPromise<JSObject>)
              .toDart;

      _device = device;

      // Connect to GATT server
      final gatt = device['gatt']! as JSObject;
      final server =
          await (gatt.callMethod('connect'.toJS) as JSPromise<JSObject>).toDart;

      // Try each known service/characteristic UUID pair
      JSObject? foundCharacteristic;
      for (final svcUuid in _altServiceUuids) {
        JSObject? service;
        try {
          service =
              await (server.callMethod('getPrimaryService'.toJS, svcUuid.toJS)
                      as JSPromise<JSObject>)
                  .toDart;
        } catch (_) {
          continue;
        }
        for (final charUuid in _altCharUuids) {
          try {
            foundCharacteristic =
                await (service.callMethod(
                          'getCharacteristic'.toJS,
                          charUuid.toJS,
                        )
                        as JSPromise<JSObject>)
                    .toDart;
            debugPrint(
              'Web Bluetooth: found writable char $charUuid on service $svcUuid',
            );
            break;
          } catch (_) {
            continue;
          }
        }
        if (foundCharacteristic != null) break;
      }

      if (foundCharacteristic == null) {
        debugPrint('Web Bluetooth: no supported write characteristic found');
        _connected = false;
        _characteristic = null;
        _device = null;
        return false;
      }

      _characteristic = foundCharacteristic;
      _connected = true;

      try {
        final nameJs = device['name'];
        if (nameJs != null && nameJs.isA<JSString>()) {
          final name = (nameJs as JSString).toDart.trim();
          _connectedDeviceName = name.isNotEmpty ? name : 'Bluetooth Printer';
        } else {
          _connectedDeviceName = 'Bluetooth Printer';
        }
      } catch (_) {
        _connectedDeviceName = 'Bluetooth Printer';
      }

      _listenForDisconnect(device);

      debugPrint('Web Bluetooth: Connected to $_connectedDeviceName');
      return true;
    } catch (e) {
      debugPrint('Web Bluetooth connect error: $e');
      _connected = false;
      _characteristic = null;
      _device = null;
      return false;
    }
  }

  static void _listenForDisconnect(JSObject device) {
    try {
      if (_disconnectCallback != null) {
        device.callMethod(
          'removeEventListener'.toJS,
          'gattserverdisconnected'.toJS,
          _disconnectCallback!,
        );
      }
      _disconnectCallback = _onGattDisconnected.toJS;
      device.callMethod(
        'addEventListener'.toJS,
        'gattserverdisconnected'.toJS,
        _disconnectCallback!,
      );
    } catch (_) {}
  }

  static void _onGattDisconnected() {
    if (!_connected) return;
    debugPrint('Web Bluetooth: GATT disconnected, attempting auto-reconnect…');
    _characteristic = null;
    Future.microtask(_reconnectGatt);
  }

  static Future<bool> _reconnectGatt() async {
    if (_reconnecting || _device == null) return false;
    _reconnecting = true;
    try {
      final device = _device!;
      final gatt = device['gatt']! as JSObject;
      final server =
          await (gatt.callMethod('connect'.toJS) as JSPromise<JSObject>).toDart;

      JSObject? foundCharacteristic;
      for (final svcUuid in _altServiceUuids) {
        JSObject? service;
        try {
          service =
              await (server.callMethod('getPrimaryService'.toJS, svcUuid.toJS)
                      as JSPromise<JSObject>)
                  .toDart;
        } catch (_) {
          continue;
        }
        for (final charUuid in _altCharUuids) {
          try {
            foundCharacteristic =
                await (service.callMethod(
                          'getCharacteristic'.toJS,
                          charUuid.toJS,
                        )
                        as JSPromise<JSObject>)
                    .toDart;
            break;
          } catch (_) {
            continue;
          }
        }
        if (foundCharacteristic != null) break;
      }

      if (foundCharacteristic == null) {
        throw Exception('No writable char found');
      }
      _characteristic = foundCharacteristic;
      _connected = true;
      _listenForDisconnect(device);
      debugPrint('Web Bluetooth: Auto-reconnected to $_connectedDeviceName');
      return true;
    } catch (e) {
      debugPrint('Web Bluetooth: Auto-reconnect failed: $e');
      _connected = false;
      _characteristic = null;
      return false;
    } finally {
      _reconnecting = false;
    }
  }

  static void disconnect() {
    try {
      if (_device != null) {
        final gatt = _device!['gatt'] as JSObject?;
        gatt?.callMethod('disconnect'.toJS);
      }
    } catch (e) {
      debugPrint('Web Bluetooth disconnect error: $e');
    }
    _device = null;
    _characteristic = null;
    _connected = false;
    _connectedDeviceName = '';
    _reconnecting = false;
  }

  static Future<void> _writeChunk(Uint8List chunk) async {
    try {
      await (_characteristic!.callMethod(
                'writeValueWithoutResponse'.toJS,
                chunk.toJS,
              )
              as JSPromise)
          .toDart;
    } catch (_) {
      await (_characteristic!.callMethod(
                'writeValueWithResponse'.toJS,
                chunk.toJS,
              )
              as JSPromise)
          .toDart;
    }
  }

  static bool get _isAndroid {
    try {
      final nav = web.window.navigator as JSObject;
      final ua = (nav['userAgent'] as JSString?)?.toDart ?? '';
      return ua.toLowerCase().contains('android');
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _sendChunked(Uint8List data) async {
    final isAndroid = _isAndroid;
    final chunkSize = isAndroid ? 20 : 512;
    final delay = isAndroid
        ? const Duration(milliseconds: 50)
        : const Duration(milliseconds: 20);
    for (var offset = 0; offset < data.length; offset += chunkSize) {
      final end = (offset + chunkSize > data.length)
          ? data.length
          : offset + chunkSize;
      final chunk = Uint8List.fromList(data.sublist(offset, end));
      await _writeChunk(chunk);
      await Future<void>.delayed(delay);
    }
    return true;
  }

  /// Send raw bytes to the connected printer.
  static Future<bool> sendBytes(List<int> bytes) async {
    if (_reconnecting) {
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!_reconnecting) break;
      }
    }

    if (_characteristic == null && _device != null) {
      debugPrint('Web Bluetooth: characteristic gone, reconnecting…');
      if (!await _reconnectGatt()) return false;
    }

    if (_characteristic == null) return false;

    try {
      return await _sendChunked(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('Web Bluetooth send error: $e — trying reconnect + retry');
      _connected = false;
      _characteristic = null;
      if (_device != null && await _reconnectGatt()) {
        try {
          return await _sendChunked(Uint8List.fromList(bytes));
        } catch (e2) {
          debugPrint('Web Bluetooth retry failed: $e2');
          _connected = false;
          _characteristic = null;
        }
      }
      return false;
    }
  }

  /// Print a receipt via Web Bluetooth using the shared ESC/POS builder.
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
