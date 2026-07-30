/// Hardware Settings Screen - Printer, Barcode, Sync, Preferences
/// Functional printer settings for Bluetooth thermal and system printers
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tulasihotels/core/design/app_colors.dart';
import 'package:tulasihotels/core/services/sunmi_printer_service.dart';
import 'package:tulasihotels/core/services/thermal_printer_service.dart';
import 'package:tulasihotels/core/services/web_bluetooth_printer_service.dart';
import 'package:tulasihotels/core/services/web_serial_printer_service.dart';
import 'package:tulasihotels/features/settings/providers/settings_provider.dart';
import 'package:tulasihotels/core/services/sync_settings_service.dart';
import 'package:tulasihotels/l10n/app_localizations.dart';
import 'package:tulasihotels/main.dart' show appVersion, appBuildNumber;

class HardwareSettingsScreen extends ConsumerStatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  ConsumerState<HardwareSettingsScreen> createState() =>
      _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState
    extends ConsumerState<HardwareSettingsScreen> {
  bool _voiceInput = false;
  bool _isScanning = false;
  List<PrinterDevice> _scannedDevices = [];

  // WiFi printer state
  late TextEditingController _wifiIpController;
  late TextEditingController _wifiPortController;
  bool _isWifiConnecting = false;

  // USB printer state (Windows)
  List<String> _windowsPrinters = [];
  bool _isLoadingUsbPrinters = false;

  late TextEditingController _barcodePrefixController;
  late TextEditingController _barcodeSuffixController;
  late TextEditingController _receiptFooterController;

  @override
  void initState() {
    super.initState();
    _barcodePrefixController = TextEditingController();
    _barcodeSuffixController = TextEditingController();
    _receiptFooterController = TextEditingController();
    _wifiIpController = TextEditingController(
      text: WifiPrinterService.getSavedIp(),
    );
    _wifiPortController = TextEditingController(
      text: WifiPrinterService.getSavedPort().toString(),
    );

    // Load receipt footer from state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final printerState = ref.read(printerProvider);
      _receiptFooterController.text = printerState.receiptFooter;

      // Load USB printers on Windows
      if (UsbPrinterService.isAvailable) {
        unawaited(_loadWindowsPrinters());
      }
    });
  }

  @override
  void dispose() {
    _barcodePrefixController.dispose();
    _barcodeSuffixController.dispose();
    _receiptFooterController.dispose();
    _wifiIpController.dispose();
    _wifiPortController.dispose();
    super.dispose();
  }

  Future<void> _scanBluetoothPrinters() async {
    setState(() {
      _isScanning = true;
      _scannedDevices = [];
    });

    try {
      final devices = await ThermalPrinterService.getPairedDevices();
      if (mounted) {
        setState(() {
          _scannedDevices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    }
  }

  Future<void> _connectToPrinter(PrinterDevice device) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Connecting to ${device.name}...')));

    final success = await ThermalPrinterService.connect(device);
    if (success) {
      await ThermalPrinterService.savePrinter(device);
      await ref
          .read(printerProvider.notifier)
          .connectPrinter(device.name, device.address);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _disconnectPrinter() async {
    await ThermalPrinterService.disconnect();
    await ref.read(printerProvider.notifier).disconnectPrinter();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Printer disconnected')));
    }
  }

  Future<void> _testPrint() async {
    final printerState = ref.read(printerProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    switch (printerState.printerType) {
      case PrinterTypeOption.bluetooth:
        final connected = await ThermalPrinterService.isConnected;
        if (!connected) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No Bluetooth printer connected')),
          );
          return;
        }
        final success = await ThermalPrinterService.printTestPage();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print sent!' : 'Print failed'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.wifi:
        if (!WifiPrinterService.isConnected) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No WiFi printer connected')),
          );
          return;
        }
        final success = await WifiPrinterService.printTestPage();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print sent!' : 'Print failed'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.usb:
        final usbName = UsbPrinterService.getSavedPrinterName();
        if (usbName.isEmpty) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No USB printer selected')),
          );
          return;
        }
        final success = await UsbPrinterService.printTestPage(usbName);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print sent!' : 'Print failed'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.system:
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'System printer: Use the print dialog when printing a receipt',
            ),
          ),
        );
        break;

      case PrinterTypeOption.sunmi:
        final sunmiAvailable = await SunmiPrinterService.isAvailable;
        if (!sunmiAvailable) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Sunmi printer not available')),
          );
          return;
        }
        final sunmiSuccess = await SunmiPrinterService.printTestPage();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(sunmiSuccess ? 'Test print sent!' : 'Print failed'),
            backgroundColor: sunmiSuccess ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.webBluetooth:
        if (!WebBluetoothPrinterService.isSupported) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Web Bluetooth not supported in this browser'),
            ),
          );
          return;
        }
        if (!WebBluetoothPrinterService.isConnected) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No Bluetooth printer connected')),
          );
          return;
        }
        final wbSuccess = await WebBluetoothPrinterService.printTestPage();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(wbSuccess ? 'Test print sent!' : 'Print failed'),
            backgroundColor: wbSuccess ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.webSerial:
        if (!WebSerialPrinterService.isConnected) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No USB serial port connected')),
          );
          return;
        }
        final wsSuccess = await WebSerialPrinterService.printTestPage();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(wsSuccess ? 'Test print sent!' : 'Print failed'),
            backgroundColor: wsSuccess ? AppColors.success : AppColors.error,
          ),
        );
        break;
    }
  }

  // ─── WiFi Printer Methods ───

  Future<void> _connectWifiPrinter() async {
    final ip = _wifiIpController.text.trim();
    final port = int.tryParse(_wifiPortController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a printer IP address')),
      );
      return;
    }

    setState(() => _isWifiConnecting = true);

    final success = await WifiPrinterService.connect(ip, port);

    if (success) {
      await WifiPrinterService.saveWifiPrinter(ip, port);
      unawaited(
        ref
            .read(printerProvider.notifier)
            .connectPrinter('WiFi Printer', '$ip:$port'),
      );
    }

    if (mounted) {
      setState(() => _isWifiConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected to $ip:$port'
                : 'Failed to connect to $ip:$port',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _disconnectWifiPrinter() async {
    await WifiPrinterService.disconnect();
    await ref.read(printerProvider.notifier).disconnectPrinter();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WiFi printer disconnected')),
      );
    }
  }

  // ─── USB Printer Methods (Windows) ───

  Future<void> _loadWindowsPrinters() async {
    setState(() => _isLoadingUsbPrinters = true);
    final printers = await UsbPrinterService.getWindowsPrinters();
    if (mounted) {
      setState(() {
        _windowsPrinters = printers;
        _isLoadingUsbPrinters = false;
      });
    }
  }

  Future<void> _selectUsbPrinter(String name) async {
    await UsbPrinterService.saveUsbPrinter(name);
    await ref.read(printerProvider.notifier).connectPrinter('USB: $name', name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected USB printer: $name'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final printerState = ref.watch(printerProvider);
    final syncInterval = SyncSettingsService.getSyncInterval();

    return Scaffold(
      appBar: AppBar(title: const Text('Hardware Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Printer Section
          _buildSectionHeader(theme, l10n.printer),
          _buildPrinterTypeCard(theme, printerState),
          const SizedBox(height: 16),
          if (printerState.printerType == PrinterTypeOption.bluetooth)
            _buildBluetoothSection(theme, printerState),
          if (printerState.printerType == PrinterTypeOption.wifi)
            _buildWifiSection(theme),
          if (printerState.printerType == PrinterTypeOption.usb)
            _buildUsbSection(theme),
          if (printerState.printerType == PrinterTypeOption.webBluetooth)
            _buildWebBluetoothSection(theme),
          if (printerState.printerType == PrinterTypeOption.webSerial)
            _buildWebSerialSection(theme),
          _buildPaperSettingsCard(theme, printerState),
          const SizedBox(height: 16),
          _buildReceiptSettingsCard(theme, printerState),
          const SizedBox(height: 24),

          // Sync Section
          _buildSectionHeader(theme, l10n.sync),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: Text(l10n.syncInterval),
                  trailing: DropdownButton<SyncInterval>(
                    value: syncInterval,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v != null) {
                        SyncSettingsService.setSyncInterval(v);
                        setState(() {});
                      }
                    },
                    items: SyncInterval.values.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text(interval.displayName),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_delete),
                  title: Text(l10n.dataRetention),
                  trailing: DropdownButton<int>(
                    value: settings.retentionDays,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).setRetentionDays(v);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 60, child: Text('60 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                      DropdownMenuItem(value: 180, child: Text('180 days')),
                      DropdownMenuItem(value: 365, child: Text('1 year')),
                      DropdownMenuItem(value: -1, child: Text('Keep forever')),
                    ],
                  ),
                ),
                if (settings.retentionDays == -1)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'High storage usage — data will never be auto-deleted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Preferences Section
          _buildSectionHeader(theme, 'App Preferences'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.wifi_off, color: Colors.green),
                  title: Text('Offline Billing'),
                  subtitle: Text(
                    'Always enabled — bills are saved locally and sync automatically when back online.',
                  ),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.mic),
                  title: const Text('Voice Input'),
                  subtitle: Row(
                    children: [
                      const Text('Voice search for products'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BETA',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: _voiceInput,
                  onChanged: (v) => setState(() => _voiceInput = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Version
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'v$appVersion+$appBuildNumber',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Printer Type Card ───
  Widget _buildPrinterTypeCard(ThemeData theme, PrinterState printerState) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIOS = !kIsWeb && Platform.isIOS;
    final isMobile = isAndroid || isIOS;

    // On Android/iOS native, only show Bluetooth — other types are not useful
    final showSystem = !isMobile;
    final showBluetooth = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final showWifi = !kIsWeb && !isMobile;
    final showUsb = !kIsWeb && Platform.isWindows;
    const showWebBluetooth = kIsWeb;
    const showWebSerial = kIsWeb;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Printer Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Choose how to connect your printer for direct ESC/POS printing.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),

            if (showSystem)
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.system,
                printerState.printerType,
                Icons.computer,
              ),
            if (showBluetooth) ...[
              if (showSystem) const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.bluetooth,
                printerState.printerType,
                Icons.bluetooth,
              ),
            ],
            if (showWifi) ...[
              const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.wifi,
                printerState.printerType,
                Icons.wifi,
              ),
            ],
            if (showUsb) ...[
              const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.usb,
                printerState.printerType,
                Icons.usb,
              ),
            ],
            if (showWebBluetooth) ...[
              const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.webBluetooth,
                printerState.printerType,
                Icons.bluetooth,
              ),
            ],
            if (showWebSerial) ...[
              const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.webSerial,
                printerState.printerType,
                Icons.usb,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterTypeOption(
    ThemeData theme,
    PrinterTypeOption option,
    PrinterTypeOption selected,
    IconData icon,
  ) {
    final isSelected = option == selected;
    return InkWell(
      onTap: () {
        ref.read(printerProvider.notifier).setPrinterType(option);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // ─── Bluetooth Section ───
  Widget _buildBluetoothSection(ThemeData theme, PrinterState printerState) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with connection indicator
                Row(
                  children: [
                    Icon(
                      Icons.print,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bluetooth Thermal Printer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (printerState.isConnected) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Instructions
                if (!printerState.isConnected)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Pair your printer in phone Bluetooth\n    settings',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2. Tap Scan Printers below',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3. Tap Connect next to your printer',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '4. Use Test Print to verify',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Open App Settings button (for permissions)
                if (!printerState.isConnected)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => openAppSettings(),
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Open App Settings (permissions)'),
                    ),
                  ),

                // Connected printer name
                if (printerState.isConnected)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connected: ${printerState.printerName ?? 'Unknown'}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Scan / Disconnect / Test Print buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isScanning ? null : _scanBluetoothPrinters,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isScanning ? 'Scanning...' : 'Scan Printers',
                        ),
                      ),
                    ),
                    if (printerState.isConnected) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _disconnectPrinter,
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Disconnect'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),

                // Test Print button (separate for visibility)
                if (printerState.isConnected) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testPrint,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Test Print'),
                    ),
                  ),
                ],

                // Scanned devices list
                if (_scannedDevices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Found Devices:', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ..._scannedDevices.map(
                    (device) => ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(device.name),
                      subtitle: Text(
                        device.address,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.link, color: AppColors.success),
                        onPressed: () => _connectToPrinter(device),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── WiFi Printer Section ───
  Widget _buildWifiSection(ThemeData theme) {
    final isConnected = WifiPrinterService.isConnected;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: isConnected ? AppColors.success : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? 'Connected: ${WifiPrinterService.connectedAddress}'
                                : 'WiFi Thermal Printer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isConnected
                                ? 'Connected'
                                : 'Enter printer IP and port (default: 9100)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isConnected
                                  ? AppColors.success
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // IP + Port input
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _wifiIpController,
                        decoration: const InputDecoration(
                          labelText: 'IP Address',
                          hintText: '192.168.1.100',
                          isDense: true,
                          prefixIcon: Icon(Icons.router, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _wifiPortController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '9100',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Connect / Disconnect
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isWifiConnecting
                            ? null
                            : _connectWifiPrinter,
                        icon: _isWifiConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link),
                        label: Text(
                          _isWifiConnecting ? 'Connecting...' : 'Connect',
                        ),
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _disconnectWifiPrinter,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Disconnect'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── USB Printer Section (Windows) ───
  Widget _buildUsbSection(ThemeData theme) {
    final savedName = UsbPrinterService.getSavedPrinterName();

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.usb,
                      color: savedName.isNotEmpty
                          ? AppColors.success
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            savedName.isNotEmpty
                                ? 'USB: $savedName'
                                : 'USB Thermal Printer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            savedName.isNotEmpty
                                ? 'Selected'
                                : 'Select a printer from the list below',
                            style: TextStyle(
                              fontSize: 12,
                              color: savedName.isNotEmpty
                                  ? AppColors.success
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isLoadingUsbPrinters
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isLoadingUsbPrinters
                          ? null
                          : _loadWindowsPrinters,
                      tooltip: 'Refresh printer list',
                    ),
                  ],
                ),

                if (_windowsPrinters.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Available Printers:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ..._windowsPrinters.map(
                    (name) => ListTile(
                      leading: Icon(
                        Icons.print,
                        color: name == savedName ? AppColors.success : null,
                      ),
                      title: Text(name),
                      trailing: name == savedName
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            )
                          : TextButton(
                              onPressed: () => _selectUsbPrinter(name),
                              child: const Text('Select'),
                            ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ] else if (!_isLoadingUsbPrinters) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No printers found. Click refresh to scan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Web Bluetooth Section ───
  Widget _buildWebBluetoothSection(ThemeData theme) {
    final isConnected = WebBluetoothPrinterService.isConnected;
    final deviceName = WebBluetoothPrinterService.connectedDeviceName;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth,
                      color: isConnected ? AppColors.success : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? deviceName : 'Web Bluetooth Printer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isConnected
                                ? 'Connected'
                                : 'Tap "Select Printer" to pair a device',
                            style: TextStyle(
                              fontSize: 12,
                              color: isConnected
                                  ? AppColors.success
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bluetooth_searching),
                        label: Text(
                          isConnected ? 'Reconnect' : 'Select Printer',
                        ),
                        onPressed: () async {
                          final success =
                              await WebBluetoothPrinterService.connect();
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Connected to ${WebBluetoothPrinterService.connectedDeviceName}'
                                      : 'Connection failed or cancelled',
                                ),
                                backgroundColor: success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          WebBluetoothPrinterService.disconnect();
                          setState(() {});
                        },
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ],
                ),
                if (!WebBluetoothPrinterService.isSupported)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Web Bluetooth requires Chrome or Edge on HTTPS.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _editSerialPrinterName(BuildContext context) async {
    final controller = TextEditingController(
      text: WebSerialPrinterService.connectedPortName,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Printer Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter printer name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty && mounted) {
      await WebSerialPrinterService.setCustomName(result);
      setState(() {});
    }
  }

  // ─── Web Serial Section ───
  Widget _buildWebSerialSection(ThemeData theme) {
    final isConnected = WebSerialPrinterService.isConnected;
    final portName = WebSerialPrinterService.connectedPortName;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.usb,
                      color: isConnected ? AppColors.success : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: isConnected
                                ? () => _editSerialPrinterName(context)
                                : null,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isConnected ? portName : 'USB Serial Printer',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (isConnected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            isConnected
                                ? 'Connected'
                                : 'Tap "Connect Port" to select USB port',
                            style: TextStyle(
                              fontSize: 12,
                              color: isConnected
                                  ? AppColors.success
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.usb),
                        label: Text(isConnected ? 'Reconnect' : 'Connect Port'),
                        onPressed: () async {
                          final success =
                              await WebSerialPrinterService.connect();
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Connected to ${WebSerialPrinterService.connectedPortName}'
                                      : 'Connection failed or cancelled',
                                ),
                                backgroundColor: success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          WebSerialPrinterService.disconnect();
                          setState(() {});
                        },
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ],
                ),
                if (!WebSerialPrinterService.isSupported)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Web Serial requires Chrome or Edge on HTTPS.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Paper Settings Card ───
  Widget _buildPaperSettingsCard(ThemeData theme, PrinterState printerState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paper & Font', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),

            // Paper size
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.straighten, size: 20),
                const SizedBox(width: 12),
                const Text('Paper Size'),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('58mm')),
                    ButtonSegment(value: 1, label: Text('80mm')),
                  ],
                  selected: {printerState.paperSizeIndex},
                  onSelectionChanged: (set) {
                    ref.read(printerProvider.notifier).setPaperSize(set.first);
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Font size
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.text_fields, size: 20),
                const SizedBox(width: 12),
                const Text('Font Size'),
                const Spacer(),
                SegmentedButton<int>(
                  segments: PrinterFontSize.values
                      .map(
                        (f) =>
                            ButtonSegment(value: f.value, label: Text(f.label)),
                      )
                      .toList(),
                  selected: {printerState.fontSizeIndex},
                  onSelectionChanged: (set) {
                    ref.read(printerProvider.notifier).setFontSize(set.first);
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Density slider
            if (printerState.printerType.isThermal) ...[
              const Row(
                children: [
                  SizedBox(width: 4),
                  Icon(Icons.contrast, size: 20),
                  SizedBox(width: 12),
                  Text('Density'),
                ],
              ),
              Slider(
                value: printerState.printDensity.toDouble(),
                max: 2,
                divisions: 2,
                label: ['Light', 'Normal', 'Dark'][printerState.printDensity],
                onChanged: (v) {
                  ref
                      .read(printerProvider.notifier)
                      .setPrintDensity(v.round());
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Light',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      ['Light', 'Normal', 'Dark'][printerState.printDensity],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Dark',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Test Print button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testPrint,
                icon: const Icon(Icons.print),
                label: const Text('Test Print'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Receipt Settings Card ───
  Widget _buildReceiptSettingsCard(ThemeData theme, PrinterState printerState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Settings', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),

            // Auto-print toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.autorenew),
              title: const Text('Auto-Print'),
              subtitle: const Text(
                'Print receipt automatically after bill completion',
              ),
              value: printerState.autoPrint,
              onChanged: (v) {
                ref.read(printerProvider.notifier).setAutoPrint(v);
              },
            ),
            const Divider(),

            // Print copies
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.copy_all),
              title: const Text('Print Copies'),
              subtitle: const Text('Number of copies per receipt'),
              trailing: DropdownButton<int>(
                value: printerState.printCopies,
                underline: const SizedBox.shrink(),
                items: [1, 2, 3]
                    .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(printerProvider.notifier).setPrintCopies(v);
                  }
                },
              ),
            ),
            const Divider(),

            // Receipt language
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language),
              title: const Text('Receipt Language'),
              trailing: DropdownButton<ReceiptLanguage>(
                value: printerState.receiptLanguage,
                underline: const SizedBox.shrink(),
                items: ReceiptLanguage.values
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(
                          l.name[0].toUpperCase() + l.name.substring(1),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(printerProvider.notifier).setReceiptLanguage(v);
                  }
                },
              ),
            ),
            const Divider(),

            // Show QR on receipt
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.qr_code),
              title: const Text('UPI QR on Receipt'),
              subtitle: const Text('Print UPI QR code for payment'),
              value: printerState.showQrOnReceipt,
              onChanged: (v) {
                ref.read(printerProvider.notifier).setShowQrOnReceipt(v);
              },
            ),
            const Divider(),

            // Show GST breakdown
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.receipt_long),
              title: const Text('GST Breakdown'),
              subtitle: const Text('Show CGST/SGST details on receipt'),
              value: printerState.showGstBreakdown,
              onChanged: (v) {
                ref.read(printerProvider.notifier).setShowGstBreakdown(v);
              },
            ),
            const Divider(),

            // Show logo on thermal
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.image),
              title: const Text('Logo on Receipt'),
              subtitle: const Text('Print shop logo at the top'),
              value: printerState.showLogoOnThermal,
              onChanged: (v) {
                ref.read(printerProvider.notifier).setShowLogoOnThermal(v);
              },
            ),
            const Divider(),

            // Open cash drawer
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.point_of_sale),
              title: const Text('Open Cash Drawer'),
              subtitle: const Text('Kick cash drawer after printing'),
              value: printerState.openCashDrawer,
              onChanged: (v) {
                ref.read(printerProvider.notifier).setOpenCashDrawer(v);
              },
            ),
            const Divider(),

            // Cut mode
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.content_cut),
              title: const Text('Paper Cut Mode'),
              trailing: DropdownButton<CutMode>(
                value: printerState.cutMode,
                underline: const SizedBox.shrink(),
                items: CutMode.values
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          m == CutMode.fullCut ? 'Full Cut' : 'Partial Cut',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(printerProvider.notifier).setCutMode(v);
                  }
                },
              ),
            ),
            const Divider(),

            // Copy label (ORIGINAL / DUPLICATE)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.label_outline),
              title: const Text('Copy Label'),
              subtitle: const Text('Print ORIGINAL/DUPLICATE on copies'),
              value: printerState.showCopyLabel,
              onChanged: (v) {
                ref.read(printerProvider.notifier).setShowCopyLabel(v);
              },
            ),
            const Divider(),

            // Receipt footer
            TextField(
              controller: _receiptFooterController,
              decoration: const InputDecoration(
                labelText: 'Receipt Footer',
                hintText: 'e.g. Thank you for shopping!',
                helperText: 'Custom text at the bottom of receipts',
              ),
              onChanged: (v) {
                ref.read(printerProvider.notifier).setReceiptFooter(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
