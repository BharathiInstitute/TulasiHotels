/// Printer state management — PrinterState, PrinterNotifier, and providers
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';

/// Printer font size enum
enum PrinterFontSize {
  small(0, 'Small', 'Compact - fits more text'),
  normal(1, 'Normal', 'Default size'),
  large(2, 'Large', 'Easier to read');

  final int value;
  final String label;
  final String description;

  const PrinterFontSize(this.value, this.label, this.description);

  static PrinterFontSize fromValue(int value) {
    return PrinterFontSize.values.firstWhere(
      (f) => f.value == value,
      orElse: () => PrinterFontSize.normal,
    );
  }
}

/// Printer type enum
enum PrinterTypeOption {
  system('System Printer', 'PDF print — select a printer for direct print'),
  bluetooth('Bluetooth', 'Direct ESC/POS via Bluetooth'),
  usb('USB', 'Direct ESC/POS via USB cable'),
  wifi('WiFi', 'Direct ESC/POS via network'),
  sunmi('Sunmi Built-in', 'Built-in printer on Sunmi POS devices'),
  webBluetooth('Web Bluetooth', 'Print via Chrome Web Bluetooth API'),
  webSerial('Web Serial (USB)', 'Print via Chrome Web Serial API — USB cable');

  final String label;
  final String description;
  const PrinterTypeOption(this.label, this.description);

  /// Whether this type uses direct ESC/POS thermal printing
  bool get isThermal => this != system;

  static PrinterTypeOption fromString(String value) {
    return PrinterTypeOption.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PrinterTypeOption.system,
    );
  }
}

/// Receipt language
enum ReceiptLanguage {
  english('English'),
  hindi('हिन्दी');

  final String label;
  const ReceiptLanguage(this.label);

  static ReceiptLanguage fromString(String value) {
    return ReceiptLanguage.values.firstWhere(
      (l) => l.name == value,
      orElse: () => ReceiptLanguage.english,
    );
  }
}

/// Cut mode for thermal paper
enum CutMode {
  fullCut('Full Cut'),
  partialCut('Partial Cut');

  final String label;
  const CutMode(this.label);

  static CutMode fromString(String value) {
    return CutMode.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CutMode.fullCut,
    );
  }
}

/// Printer state
class PrinterState {
  final bool isConnected;
  final String? printerName;
  final String? printerAddress;
  final int paperSizeIndex; // 0 = 58mm, 1 = 80mm
  final int fontSizeIndex; // 0 = Small, 1 = Normal, 2 = Large
  final int customWidth; // 0 = auto, 28-52 = custom chars per line
  final bool isScanning;
  final String? error;
  final PrinterTypeOption printerType;
  final bool autoPrint;
  final String receiptFooter;
  final bool openCashDrawer;
  final int printCopies; // 1-3
  final bool showQrOnReceipt;
  final bool showGstBreakdown;
  final ReceiptLanguage receiptLanguage;
  final bool showLogoOnThermal;
  final CutMode cutMode;
  final bool showCopyLabel;
  final bool showHsnOnReceipt;
  final int printDensity; // 0=Light, 1=Normal, 2=Dark

  const PrinterState({
    this.isConnected = false,
    this.printerName,
    this.printerAddress,
    this.paperSizeIndex = 1, // Default 80mm
    this.fontSizeIndex = 1, // Default Normal
    this.customWidth = 0, // Default auto
    this.isScanning = false,
    this.error,
    this.printerType = PrinterTypeOption.system,
    this.autoPrint = false,
    this.receiptFooter = '',
    this.openCashDrawer = false,
    this.printCopies = 1,
    this.showQrOnReceipt = false,
    this.showGstBreakdown = false,
    this.receiptLanguage = ReceiptLanguage.english,
    this.showLogoOnThermal = false,
    this.cutMode = CutMode.fullCut,
    this.showCopyLabel = false,
    this.showHsnOnReceipt = false,
    this.printDensity = 1,
  });

  String get paperSizeLabel => paperSizeIndex == 0 ? '58mm' : '80mm';

  PrinterFontSize get fontSize => PrinterFontSize.fromValue(fontSizeIndex);

  /// Get effective characters per line
  int get effectiveWidth {
    if (customWidth > 0) return customWidth;
    return paperSizeIndex == 0 ? 32 : 48;
  }

  String get widthLabel {
    if (customWidth > 0) return '$customWidth chars';
    return 'Auto ($effectiveWidth chars)';
  }

  PrinterState copyWith({
    bool? isConnected,
    String? printerName,
    String? printerAddress,
    int? paperSizeIndex,
    int? fontSizeIndex,
    int? customWidth,
    bool? isScanning,
    String? error,
    PrinterTypeOption? printerType,
    bool? autoPrint,
    String? receiptFooter,
    bool? openCashDrawer,
    int? printCopies,
    bool? showQrOnReceipt,
    bool? showGstBreakdown,
    ReceiptLanguage? receiptLanguage,
    bool? showLogoOnThermal,
    CutMode? cutMode,
    bool? showCopyLabel,
    bool? showHsnOnReceipt,
    int? printDensity,
  }) {
    return PrinterState(
      isConnected: isConnected ?? this.isConnected,
      printerName: printerName ?? this.printerName,
      printerAddress: printerAddress ?? this.printerAddress,
      paperSizeIndex: paperSizeIndex ?? this.paperSizeIndex,
      fontSizeIndex: fontSizeIndex ?? this.fontSizeIndex,
      customWidth: customWidth ?? this.customWidth,
      isScanning: isScanning ?? this.isScanning,
      error: error,
      printerType: printerType ?? this.printerType,
      autoPrint: autoPrint ?? this.autoPrint,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      openCashDrawer: openCashDrawer ?? this.openCashDrawer,
      printCopies: printCopies ?? this.printCopies,
      showQrOnReceipt: showQrOnReceipt ?? this.showQrOnReceipt,
      showGstBreakdown: showGstBreakdown ?? this.showGstBreakdown,
      receiptLanguage: receiptLanguage ?? this.receiptLanguage,
      showLogoOnThermal: showLogoOnThermal ?? this.showLogoOnThermal,
      cutMode: cutMode ?? this.cutMode,
      showCopyLabel: showCopyLabel ?? this.showCopyLabel,
      showHsnOnReceipt: showHsnOnReceipt ?? this.showHsnOnReceipt,
      printDensity: printDensity ?? this.printDensity,
    );
  }
}

final printerProvider = StateNotifierProvider<PrinterNotifier, PrinterState>(
  (ref) => PrinterNotifier(),
);

class PrinterNotifier extends StateNotifier<PrinterState> {
  PrinterNotifier() : super(const PrinterState()) {
    _loadSavedPrinter();
  }

  void _loadSavedPrinter() {
    final savedPrinter = PrinterStorage.getSavedPrinter();
    final paperSize = PrinterStorage.getSavedPaperSize();
    final fontSize = PrinterStorage.getSavedFontSize();
    final customWidth = PrinterStorage.getSavedCustomWidth();
    final autoPrint = PrinterStorage.getAutoPrint();
    final receiptFooter = PrinterStorage.getReceiptFooter();
    final openCashDrawer = PrinterStorage.getOpenCashDrawer();
    final printCopies = PrinterStorage.getPrintCopies();
    final showQrOnReceipt = PrinterStorage.getShowQrOnReceipt();
    final showGstBreakdown = PrinterStorage.getShowGstBreakdown();
    final receiptLanguage = ReceiptLanguage.fromString(
      PrinterStorage.getReceiptLanguage(),
    );
    final showLogoOnThermal = PrinterStorage.getShowLogoOnThermal();
    final cutMode = CutMode.fromString(PrinterStorage.getCutMode());
    final showCopyLabel = PrinterStorage.getShowCopyLabel();
    final showHsnOnReceipt = PrinterStorage.getShowHsnOnReceipt();
    var printerType = PrinterTypeOption.fromString(
      PrinterStorage.getPrinterType(),
    );
    // On web, native types are not available — fall back to webBluetooth
    if (kIsWeb &&
        printerType != PrinterTypeOption.system &&
        printerType != PrinterTypeOption.webBluetooth &&
        printerType != PrinterTypeOption.webSerial) {
      printerType = PrinterTypeOption.webBluetooth;
    }
    final printDensity = PrinterStorage.getPrintDensity();

    if (savedPrinter != null) {
      state = PrinterState(
        isConnected: true,
        printerName: savedPrinter['name'],
        printerAddress: savedPrinter['address'],
        paperSizeIndex: paperSize,
        fontSizeIndex: fontSize,
        customWidth: customWidth,
        autoPrint: autoPrint,
        receiptFooter: receiptFooter,
        openCashDrawer: openCashDrawer,
        printCopies: printCopies,
        showQrOnReceipt: showQrOnReceipt,
        showGstBreakdown: showGstBreakdown,
        receiptLanguage: receiptLanguage,
        showLogoOnThermal: showLogoOnThermal,
        cutMode: cutMode,
        printerType: printerType,
        showCopyLabel: showCopyLabel,
        showHsnOnReceipt: showHsnOnReceipt,
        printDensity: printDensity,
      );
    } else {
      state = PrinterState(
        paperSizeIndex: paperSize,
        fontSizeIndex: fontSize,
        customWidth: customWidth,
        autoPrint: autoPrint,
        receiptFooter: receiptFooter,
        openCashDrawer: openCashDrawer,
        printCopies: printCopies,
        showQrOnReceipt: showQrOnReceipt,
        showGstBreakdown: showGstBreakdown,
        receiptLanguage: receiptLanguage,
        showLogoOnThermal: showLogoOnThermal,
        cutMode: cutMode,
        printerType: printerType,
        showCopyLabel: showCopyLabel,
        showHsnOnReceipt: showHsnOnReceipt,
        printDensity: printDensity,
      );
    }
  }

  Future<void> setPaperSize(int sizeIndex) async {
    await PrinterStorage.savePaperSize(sizeIndex);
    state = state.copyWith(paperSizeIndex: sizeIndex);
  }

  Future<void> setFontSize(int fontSizeIndex) async {
    await PrinterStorage.saveFontSize(fontSizeIndex);
    state = state.copyWith(fontSizeIndex: fontSizeIndex);
  }

  Future<void> setCustomWidth(int width) async {
    await PrinterStorage.saveCustomWidth(width);
    state = state.copyWith(customWidth: width);
  }

  Future<void> setPrintDensity(int density) async {
    await PrinterStorage.savePrintDensity(density);
    state = state.copyWith(printDensity: density);
  }

  Future<bool> connectPrinter(String name, String address) async {
    state = state.copyWith(isScanning: true);
    await PrinterStorage.savePrinter(name, address);
    state = state.copyWith(
      isConnected: true,
      printerName: name,
      printerAddress: address,
      isScanning: false,
    );
    return true;
  }

  Future<void> disconnectPrinter() async {
    await PrinterStorage.clearSavedPrinter();
    state = PrinterState(
      paperSizeIndex: state.paperSizeIndex,
      fontSizeIndex: state.fontSizeIndex,
      customWidth: state.customWidth,
      autoPrint: state.autoPrint,
      receiptFooter: state.receiptFooter,
      openCashDrawer: state.openCashDrawer,
      printCopies: state.printCopies,
      showQrOnReceipt: state.showQrOnReceipt,
      showGstBreakdown: state.showGstBreakdown,
      receiptLanguage: state.receiptLanguage,
      showLogoOnThermal: state.showLogoOnThermal,
      cutMode: state.cutMode,
      printerType: state.printerType,
      printDensity: state.printDensity,
    );
  }

  Future<void> setPrinterType(PrinterTypeOption type) async {
    await PrinterStorage.savePrinterType(type.name);
    state = state.copyWith(printerType: type);
  }

  Future<void> setAutoPrint(bool autoPrint) async {
    await PrinterStorage.saveAutoPrint(autoPrint);
    state = state.copyWith(autoPrint: autoPrint);
  }

  Future<void> setReceiptFooter(String footer) async {
    await PrinterStorage.saveReceiptFooter(footer);
    state = state.copyWith(receiptFooter: footer);
  }

  Future<void> setOpenCashDrawer(bool open) async {
    await PrinterStorage.saveOpenCashDrawer(open);
    state = state.copyWith(openCashDrawer: open);
  }

  Future<void> setPrintCopies(int copies) async {
    final clamped = copies.clamp(1, 3);
    await PrinterStorage.savePrintCopies(clamped);
    state = state.copyWith(printCopies: clamped);
  }

  Future<void> setShowQrOnReceipt(bool show) async {
    await PrinterStorage.saveShowQrOnReceipt(show);
    state = state.copyWith(showQrOnReceipt: show);
  }

  Future<void> setShowGstBreakdown(bool show) async {
    await PrinterStorage.saveShowGstBreakdown(show);
    state = state.copyWith(showGstBreakdown: show);
  }

  Future<void> setReceiptLanguage(ReceiptLanguage lang) async {
    await PrinterStorage.saveReceiptLanguage(lang.name);
    state = state.copyWith(receiptLanguage: lang);
  }

  Future<void> setShowLogoOnThermal(bool show) async {
    await PrinterStorage.saveShowLogoOnThermal(show);
    state = state.copyWith(showLogoOnThermal: show);
  }

  Future<void> setCutMode(CutMode mode) async {
    await PrinterStorage.saveCutMode(mode.name);
    state = state.copyWith(cutMode: mode);
  }

  Future<void> setShowCopyLabel(bool show) async {
    await PrinterStorage.saveShowCopyLabel(show);
    state = state.copyWith(showCopyLabel: show);
  }

  Future<void> setShowHsnOnReceipt(bool show) async {
    await PrinterStorage.saveShowHsnOnReceipt(show);
    state = state.copyWith(showHsnOnReceipt: show);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isScanning: false);
  }

  void setConnectionStatus(bool connected) {
    state = state.copyWith(isConnected: connected);
  }

  void clearError() {
    state = state.copyWith();
  }
}
