/// App localization utilities with hardcoded strings
library;

import 'package:flutter/material.dart';

/// Supported locales
const supportedLocales = [
  Locale('en'), // English
  Locale('hi'), // Hindi
  Locale('te'), // Telugu
];

/// App localizations class with hardcoded translations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _englishStrings,
    'hi': _hindiStrings,
    'te': _teluguStrings,
  };

  String _translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Getters for common strings
  String get appName => _translate('appName');
  String get appTagline => _translate('appTagline');

  // Navigation
  String get billing => _translate('billing');
  String get khata => _translate('khata');
  String get products => _translate('products');
  String get reports => _translate('reports');
  String get dashboard => _translate('dashboard');
  String get settings => _translate('settings');

  // Common actions
  String get save => _translate('save');
  String get cancel => _translate('cancel');
  String get delete => _translate('delete');
  String get add => _translate('add');
  String get edit => _translate('edit');
  String get search => _translate('search');
  String get searchProducts => _translate('searchProducts');
  String get share => _translate('share');
  String get close => _translate('close');
  String get confirm => _translate('confirm');
  String get retry => _translate('retry');
  String get loading => _translate('loading');
  String get noData => _translate('noData');

  // Billing
  String get total => _translate('total');
  String get subTotal => _translate('subTotal');
  String get cash => _translate('cash');
  String get upi => _translate('upi');
  String get udhar => _translate('udhar');
  String get pay => _translate('pay');
  String get payNow => _translate('payNow');
  String get receivedAmount => _translate('receivedAmount');
  String get change => _translate('change');
  String get quickAmounts => _translate('quickAmounts');
  String get selectPaymentMethod => _translate('selectPaymentMethod');
  String get billComplete => _translate('billComplete');
  String billNumber(int number) =>
      _translate('billNumber').replaceAll('{number}', '$number');
  String get printReceipt => _translate('printReceipt');
  String get shareReceipt => _translate('shareReceipt');
  String get newBill => _translate('newBill');
  String get cart => _translate('cart');
  String get emptyCart => _translate('emptyCart');
  String get addProductsToCart => _translate('addProductsToCart');
  String itemsInCart(int count) =>
      _translate('itemsInCart').replaceAll('{count}', '$count');
  String get scanBarcode => _translate('scanBarcode');
  String get barcode => _translate('barcode');

  // Products
  String get productName => _translate('productName');
  String get price => _translate('price');
  String get sellingPrice => _translate('sellingPrice');
  String get purchasePrice => _translate('purchasePrice');
  String get stock => _translate('stock');
  String get unit => _translate('unit');
  String get lowStock => _translate('lowStock');
  String get outOfStock => _translate('outOfStock');
  String get lowStockAlert => _translate('lowStockAlert');
  String get addProduct => _translate('addProduct');
  String get editProduct => _translate('editProduct');
  String get deleteProduct => _translate('deleteProduct');
  String get deleteProductConfirm => _translate('deleteProductConfirm');
  String get noProducts => _translate('noProducts');
  String get addFirstProduct => _translate('addFirstProduct');
  String get allProducts => _translate('allProducts');
  String get productAdded => _translate('productAdded');
  String get productUpdated => _translate('productUpdated');
  String get productDeleted => _translate('productDeleted');
  String get exportProducts => _translate('exportProducts');
  String get importProducts => _translate('importProducts');
  String get productCatalog => _translate('productCatalog');
  String get selectProducts => _translate('selectProducts');
  String get clear => _translate('clear');

  // Khata (Customers)
  String get customer => _translate('customer');
  String get customers => _translate('customers');
  String get customerName => _translate('customerName');
  String get phone => _translate('phone');
  String get address => _translate('address');
  String get balance => _translate('balance');
  String get payment => _translate('payment');
  String get recordPayment => _translate('recordPayment');
  String get sendReminder => _translate('sendReminder');
  String get reminder => _translate('reminder');
  String get totalDue => _translate('totalDue');
  String get addCustomer => _translate('addCustomer');
  String get editCustomer => _translate('editCustomer');
  String get noCustomers => _translate('noCustomers');
  String get addFirstCustomer => _translate('addFirstCustomer');
  String get allCustomers => _translate('allCustomers');
  String get withDue => _translate('withDue');
  String get paid => _translate('paid');
  String daysAgo(int days) =>
      _translate('daysAgo').replaceAll('{days}', '$days');
  String get paymentRecorded => _translate('paymentRecorded');
  String get transactions => _translate('transactions');
  String get purchase => _translate('purchase');
  String get noTransactions => _translate('noTransactions');

  // Reports
  String get today => _translate('today');
  String get thisWeek => _translate('thisWeek');
  String get thisMonth => _translate('thisMonth');
  String get totalSales => _translate('totalSales');
  String billsCount(int count) =>
      _translate('billsCount').replaceAll('{count}', '$count');
  String get averageBill => _translate('averageBill');
  String get exportPdf => _translate('exportPdf');
  String get topSellingProducts => _translate('topSellingProducts');
  String get noSalesData => _translate('noSalesData');
  String unitsSold(int count) =>
      _translate('unitsSold').replaceAll('{count}', '$count');
  String get recentBills => _translate('recentBills');

  // Settings
  String get shopDetails => _translate('shopDetails');
  String get shopName => _translate('shopName');
  String get ownerName => _translate('ownerName');
  String get gstNumber => _translate('gstNumber');
  String get subscription => _translate('subscription');
  String get freePlan => _translate('freePlan');
  String get premiumPlan => _translate('premiumPlan');
  String get unlimitedAccess => _translate('unlimitedAccess');
  String limitedAccess(int products, int bills) => _translate(
    'limitedAccess',
  ).replaceAll('{products}', '$products').replaceAll('{bills}', '$bills');
  String get upgradeToPremium => _translate('upgradeToPremium');
  String get appearance => _translate('appearance');
  String get darkMode => _translate('darkMode');
  String get language => _translate('language');
  String get selectLanguage => _translate('selectLanguage');
  String get english => _translate('english');
  String get hindi => _translate('hindi');
  String get telugu => _translate('telugu');
  String get printer => _translate('printer');
  String get configurePrinter => _translate('configurePrinter');
  String get dataManagement => _translate('dataManagement');
  String get backupData => _translate('backupData');
  String get exportData => _translate('exportData');
  String get support => _translate('support');
  String get helpCenter => _translate('helpCenter');
  String get sendFeedback => _translate('sendFeedback');
  String get rateApp => _translate('rateApp');
  String get about => _translate('about');
  String get version => _translate('version');
  String get signOut => _translate('signOut');
  String get signOutConfirm => _translate('signOutConfirm');

  // Auth
  String get login => _translate('login');
  String get signUp => _translate('signUp');
  String get email => _translate('email');
  String get password => _translate('password');
  String get forgotPassword => _translate('forgotPassword');
  String get welcomeBack => _translate('welcomeBack');
  String get loginToContinue => _translate('loginToContinue');
  String get dontHaveAccount => _translate('dontHaveAccount');
  String get alreadyHaveAccount => _translate('alreadyHaveAccount');
  String get createAccount => _translate('createAccount');
  String get setupShop => _translate('setupShop');
  String get enterShopDetails => _translate('enterShopDetails');
  String get getStarted => _translate('getStarted');
  String get resetPassword => _translate('resetPassword');
  String get sendResetLink => _translate('sendResetLink');
  String get backToLogin => _translate('backToLogin');

  // Settings extras
  String get syncNow => _translate('syncNow');
  String get syncStatus => _translate('syncStatus');
  String get syncInterval => _translate('syncInterval');
  String get dataRetention => _translate('dataRetention');
  String get paperSize => _translate('paperSize');
  String get fontSize => _translate('fontSize');
  String get printerSettings => _translate('printerSettings');
  String get editShopDetails => _translate('editShopDetails');
  String get connected => _translate('connected');
  String get notConnected => _translate('notConnected');
  String get logout => _translate('logout');
  String get on => _translate('on');
  String get off => _translate('off');
  String get shopInformation => _translate('shopInformation');
  String get appSettings => _translate('appSettings');
  String get sync => _translate('sync');
  String get pendingChanges => _translate('pendingChanges');
  String get uploadPendingChanges => _translate('uploadPendingChanges');
  String get syncCompleted => _translate('syncCompleted');
  String get syncFailed => _translate('syncFailed');
  String get loginEmail => _translate('loginEmail');
  String get days => _translate('days');

  // Errors
  String get error => _translate('error');
  String get somethingWentWrong => _translate('somethingWentWrong');
  String get networkError => _translate('networkError');
  String get tryAgain => _translate('tryAgain');

  // Privacy & Data
  String get accountSettings => _translate('accountSettings');
  String get downloadMyData => _translate('downloadMyData');
  String get exportDataAsJson => _translate('exportDataAsJson');
  String get privacyPolicy => _translate('privacyPolicy');
  String get termsOfService => _translate('termsOfService');
  String get deleteAccountTitle => _translate('deleteAccount');
  String get deleteEverything => _translate('deleteEverything');
  String get typeDeleteToConfirm => _translate('typeDeleteToConfirm');
  String get confirmDelete => _translate('confirmDelete');
  String get deletingAccount => _translate('deletingAccount');
  String get deleteAccountFailed => _translate('deleteAccountFailed');
  String get preparingDataExport => _translate('preparingDataExport');
  String get accountSettingsSaved => _translate('accountSettingsSaved');

  // Subscription
  String get subscriptionPlans => _translate('subscriptionPlans');
  String get current => _translate('current');
  String get upgrade => _translate('upgrade');
  String get manage => _translate('manage');
  String get upgradeComingSoon => _translate('upgradeComingSoon');

  // Referral
  String get shareInviteLink => _translate('shareInviteLink');
  String get enterFriendCode => _translate('enterFriendCode');
  String get enterReferralCode => _translate('enterReferralCode');
  String get apply => _translate('apply');
  String get referralCodeApplied => _translate('referralCodeApplied');
  String get exportFailed => _translate('exportFailed');
  String get comingSoon => _translate('comingSoon');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'te'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for easy access
extension LocalizationsExtension on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizations(const Locale('en'));
}

// ============ ENGLISH STRINGS ============
const Map<String, String> _englishStrings = {
  'appName': 'Tulasi Hotels',
  'appTagline': "India's Easiest Billing App",
  'billing': 'Billing',
  'khata': 'Khata',
  'products': 'Products',
  'reports': 'Reports',
  'dashboard': 'Dashboard',
  'settings': 'Settings',
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'add': 'Add',
  'edit': 'Edit',
  'search': 'Search',
  'searchProducts': 'Search products...',
  'share': 'Share',
  'close': 'Close',
  'confirm': 'Confirm',
  'retry': 'Retry',
  'loading': 'Loading...',
  'noData': 'No data available',
  'total': 'Total',
  'subTotal': 'Sub Total',
  'cash': 'Cash',
  'upi': 'UPI',
  'udhar': 'Credit',
  'pay': 'Pay',
  'payNow': 'Pay Now',
  'receivedAmount': 'Received Amount',
  'change': 'Change',
  'quickAmounts': 'Quick Amounts',
  'selectPaymentMethod': 'Select Payment Method',
  'billComplete': 'Bill Complete!',
  'billNumber': 'Bill #{number}',
  'printReceipt': 'Print Receipt',
  'shareReceipt': 'Share Receipt',
  'newBill': 'New Bill',
  'cart': 'Cart',
  'emptyCart': 'Cart is empty',
  'addProductsToCart': 'Add products to start billing',
  'itemsInCart': '{count} items',
  'scanBarcode': 'Scan Barcode',
  'barcode': 'Barcode',
  'productName': 'Product Name',
  'price': 'Price',
  'sellingPrice': 'Selling Price',
  'purchasePrice': 'Purchase Price',
  'stock': 'Stock',
  'unit': 'Unit',
  'lowStock': 'Low Stock',
  'outOfStock': 'Out of Stock',
  'lowStockAlert': 'Low Stock Alert',
  'addProduct': 'Add Product',
  'editProduct': 'Edit Product',
  'deleteProduct': 'Delete Product',
  'deleteProductConfirm': 'Are you sure you want to delete this product?',
  'noProducts': 'No products yet',
  'addFirstProduct': 'Add your first product to get started',
  'allProducts': 'All',
  'productAdded': 'Product added successfully',
  'productUpdated': 'Product updated successfully',
  'productDeleted': 'Product deleted successfully',
  'exportProducts': 'Export Products',
  'importProducts': 'Import Products',
  'productCatalog': 'Product Catalog',
  'selectProducts': 'Select Products',
  'clear': 'Clear',
  'customer': 'Customer',
  'customers': 'Customers',
  'customerName': 'Customer Name',
  'phone': 'Phone',
  'address': 'Address',
  'balance': 'Balance',
  'payment': 'Payment',
  'recordPayment': 'Record Payment',
  'sendReminder': 'Send Reminder',
  'reminder': 'Reminder',
  'totalDue': 'Total Due',
  'addCustomer': 'Add Customer',
  'editCustomer': 'Edit Customer',
  'noCustomers': 'No customers yet',
  'addFirstCustomer': 'Add your first customer to track credit',
  'allCustomers': 'All',
  'withDue': 'With Due',
  'paid': 'Paid',
  'daysAgo': '{days} days ago',
  'paymentRecorded': 'Payment recorded successfully',
  'transactions': 'Transactions',
  'purchase': 'Purchase',
  'noTransactions': 'No transactions yet',
  'today': 'Today',
  'thisWeek': 'This Week',
  'thisMonth': 'This Month',
  'totalSales': 'Total Sales',
  'billsCount': '{count} bills',
  'averageBill': 'Avg',
  'exportPdf': 'Export PDF',
  'topSellingProducts': 'Top Selling Products',
  'noSalesData': 'No sales data available',
  'unitsSold': '{count} units sold',
  'recentBills': 'Recent Bills',
  'shopDetails': 'Shop Details',
  'shopName': 'Shop Name',
  'ownerName': 'Owner Name',
  'gstNumber': 'GST Number',
  'subscription': 'Subscription',
  'freePlan': 'Free Plan',
  'premiumPlan': 'Premium Plan',
  'unlimitedAccess': 'Unlimited products & bills',
  'limitedAccess': '{products} products, {bills} bills/day',
  'upgradeToPremium': 'Upgrade to Premium',
  'appearance': 'Appearance',
  'darkMode': 'Dark Mode',
  'language': 'Language',
  'selectLanguage': 'Select Language',
  'english': 'English',
  'hindi': 'à¤¹à¤¿à¤‚à¤¦à¥€',
  'telugu': 'à°¤à±†à°²à±à°—à±',
  'printer': 'Printer Settings',
  'configurePrinter': 'Configure Printer',
  'dataManagement': 'Data Management',
  'backupData': 'Backup Data',
  'exportData': 'Export Data',
  'support': 'Support',
  'helpCenter': 'Help Center',
  'sendFeedback': 'Send Feedback',
  'rateApp': 'Rate App',
  'about': 'About',
  'version': 'Version',
  'signOut': 'Sign Out',
  'signOutConfirm': 'Are you sure you want to sign out?',
  'login': 'Login',
  'signUp': 'Sign Up',
  'email': 'Email',
  'password': 'Password',
  'forgotPassword': 'Forgot Password?',
  'welcomeBack': 'Welcome Back!',
  'loginToContinue': 'Login to continue to your shop',
  'dontHaveAccount': "Don't have an account?",
  'alreadyHaveAccount': 'Already have an account?',
  'createAccount': 'Create Account',
  'setupShop': 'Setup Your Shop',
  'enterShopDetails': 'Enter your shop details to get started',
  'getStarted': 'Get Started',
  'resetPassword': 'Reset Password',
  'sendResetLink': 'Send Reset Link',
  'backToLogin': 'Back to Login',
  // Settings extras
  'syncNow': 'Sync Now',
  'syncStatus': 'Sync Status',
  'syncInterval': 'Sync Interval',
  'dataRetention': 'Data Retention',
  'paperSize': 'Paper Size',
  'fontSize': 'Font Size',
  'printerSettings': 'Printer Settings',
  'editShopDetails': 'Edit Shop Details',
  'connected': 'Connected',
  'notConnected': 'Not connected',
  'logout': 'Logout',
  'on': 'On',
  'off': 'Off',
  'shopInformation': 'Shop Information',
  'appSettings': 'App Settings',
  'sync': 'Sync',
  'pendingChanges': 'pending changes',
  'uploadPendingChanges': 'Upload pending changes',
  'syncCompleted': 'Sync completed!',
  'syncFailed': 'Sync failed',
  'loginEmail': 'Login Email',
  'days': 'days',
  'error': 'Error',
  'somethingWentWrong': 'Something went wrong',
  'networkError': 'Network error. Please check your connection.',
  'tryAgain': 'Try Again',
  // Privacy & Data
  'accountSettings': 'Account Settings',
  'downloadMyData': 'Download My Data',
  'exportDataAsJson': 'Export all your data as JSON',
  'privacyPolicy': 'Privacy Policy',
  'termsOfService': 'Terms of Service',
  'deleteAccount': 'Delete Account?',
  'deleteEverything': 'Delete Everything',
  'typeDeleteToConfirm': 'Type DELETE to confirm',
  'confirmDelete': 'Confirm Delete',
  'deletingAccount': 'Deleting account and all data...',
  'deleteAccountFailed': 'Failed to delete account. Please try again.',
  'preparingDataExport': 'Preparing your data export...',
  'accountSettingsSaved': 'Account settings saved',
  // Subscription
  'subscriptionPlans': 'Subscription Plans',
  'current': 'Current',
  'upgrade': 'Upgrade',
  'manage': 'Manage',
  'upgradeComingSoon': 'Upgrade coming soon!',
  // Referral
  'shareInviteLink': 'Share Invite Link',
  'enterFriendCode': "Have a friend's code? Enter it here",
  'enterReferralCode': 'Enter Referral Code',
  'apply': 'Apply',
  'referralCodeApplied': 'Referral code applied!',
  'exportFailed': 'Export failed',
  'comingSoon': 'Coming soon!',
};

// ============ HINDI STRINGS ============
const Map<String, String> _hindiStrings = {
  'appName': 'Tulasi Hotels',
  'appTagline': 'à¤­à¤¾à¤°à¤¤ à¤•à¤¾ à¤¸à¤¬à¤¸à¥‡ à¤†à¤¸à¤¾à¤¨ à¤¬à¤¿à¤²à¤¿à¤‚à¤— à¤à¤ª',
  'billing': 'à¤¬à¤¿à¤²à¤¿à¤‚à¤—',
  'khata': 'à¤–à¤¾à¤¤à¤¾',
  'products': 'à¤¸à¤¾à¤®à¤¾à¤¨',
  'reports': 'à¤°à¤¿à¤ªà¥‹à¤°à¥à¤Ÿ',
  'dashboard': 'à¤¡à¥ˆà¤¶à¤¬à¥‹à¤°à¥à¤¡',
  'settings': 'à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤¸',
  'save': 'à¤¸à¤¹à¥‡à¤œà¥‡à¤‚',
  'cancel': 'à¤°à¤¦à¥à¤¦ à¤•à¤°à¥‡à¤‚',
  'delete': 'à¤¹à¤Ÿà¤¾à¤à¤‚',
  'add': 'à¤œà¥‹à¤¡à¤¼à¥‡à¤‚',
  'edit': 'à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤•à¤°à¥‡à¤‚',
  'search': 'à¤–à¥‹à¤œà¥‡à¤‚',
  'searchProducts': 'à¤¸à¤¾à¤®à¤¾à¤¨ à¤–à¥‹à¤œà¥‡à¤‚...',
  'share': 'à¤¶à¥‡à¤¯à¤° à¤•à¤°à¥‡à¤‚',
  'close': 'à¤¬à¤‚à¤¦ à¤•à¤°à¥‡à¤‚',
  'confirm': 'à¤ªà¥à¤·à¥à¤Ÿà¤¿ à¤•à¤°à¥‡à¤‚',
  'retry': 'à¤ªà¥à¤¨à¤ƒ à¤ªà¥à¤°à¤¯à¤¾à¤¸ à¤•à¤°à¥‡à¤‚',
  'loading': 'à¤²à¥‹à¤¡ à¤¹à¥‹ à¤°à¤¹à¤¾ à¤¹à¥ˆ...',
  'noData': 'à¤•à¥‹à¤ˆ à¤¡à¥‡à¤Ÿà¤¾ à¤¨à¤¹à¥€à¤‚',
  'total': 'à¤•à¥à¤²',
  'subTotal': 'à¤‰à¤ª-à¤•à¥à¤²',
  'cash': 'à¤¨à¤•à¤¦',
  'upi': 'à¤¯à¥‚à¤ªà¥€à¤†à¤ˆ',
  'udhar': 'à¤‰à¤§à¤¾à¤°',
  'pay': 'à¤­à¥à¤—à¤¤à¤¾à¤¨ à¤•à¤°à¥‡à¤‚',
  'payNow': 'à¤…à¤­à¥€ à¤­à¥à¤—à¤¤à¤¾à¤¨ à¤•à¤°à¥‡à¤‚',
  'receivedAmount': 'à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤ à¤°à¤¾à¤¶à¤¿',
  'change': 'à¤µà¤¾à¤ªà¤¸à¥€',
  'quickAmounts': 'à¤¤à¥à¤µà¤°à¤¿à¤¤ à¤°à¤¾à¤¶à¤¿',
  'selectPaymentMethod': 'à¤­à¥à¤—à¤¤à¤¾à¤¨ à¤µà¤¿à¤§à¤¿ à¤šà¥à¤¨à¥‡à¤‚',
  'billComplete': 'à¤¬à¤¿à¤² à¤ªà¥‚à¤°à¥à¤£!',
  'billNumber': 'à¤¬à¤¿à¤² #{number}',
  'printReceipt': 'à¤°à¤¸à¥€à¤¦ à¤ªà¥à¤°à¤¿à¤‚à¤Ÿ à¤•à¤°à¥‡à¤‚',
  'shareReceipt': 'à¤°à¤¸à¥€à¤¦ à¤¶à¥‡à¤¯à¤° à¤•à¤°à¥‡à¤‚',
  'newBill': 'à¤¨à¤¯à¤¾ à¤¬à¤¿à¤²',
  'cart': 'à¤•à¤¾à¤°à¥à¤Ÿ',
  'emptyCart': 'à¤•à¤¾à¤°à¥à¤Ÿ à¤–à¤¾à¤²à¥€ à¤¹à¥ˆ',
  'addProductsToCart': 'à¤¬à¤¿à¤²à¤¿à¤‚à¤— à¤¶à¥à¤°à¥‚ à¤•à¤°à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤¸à¤¾à¤®à¤¾à¤¨ à¤œà¥‹à¤¡à¤¼à¥‡à¤‚',
  'itemsInCart': '{count} à¤†à¤‡à¤Ÿà¤®',
  'scanBarcode': 'à¤¬à¤¾à¤°à¤•à¥‹à¤¡ à¤¸à¥à¤•à¥ˆà¤¨ à¤•à¤°à¥‡à¤‚',
  'barcode': 'à¤¬à¤¾à¤°à¤•à¥‹à¤¡',
  'productName': 'à¤‰à¤¤à¥à¤ªà¤¾à¤¦ à¤•à¤¾ à¤¨à¤¾à¤®',
  'price': 'à¤®à¥‚à¤²à¥à¤¯',
  'sellingPrice': 'à¤¬à¤¿à¤•à¥à¤°à¥€ à¤®à¥‚à¤²à¥à¤¯',
  'purchasePrice': 'à¤–à¤°à¥€à¤¦ à¤®à¥‚à¤²à¥à¤¯',
  'stock': 'à¤¸à¥à¤Ÿà¥‰à¤•',
  'unit': 'à¤‡à¤•à¤¾à¤ˆ',
  'lowStock': 'à¤•à¤® à¤¸à¥à¤Ÿà¥‰à¤•',
  'outOfStock': 'à¤¸à¥à¤Ÿà¥‰à¤• à¤¸à¤®à¤¾à¤ªà¥à¤¤',
  'lowStockAlert': 'à¤•à¤® à¤¸à¥à¤Ÿà¥‰à¤• à¤šà¥‡à¤¤à¤¾à¤µà¤¨à¥€',
  'addProduct': 'à¤¸à¤¾à¤®à¤¾à¤¨ à¤œà¥‹à¤¡à¤¼à¥‡à¤‚',
  'editProduct': 'à¤¸à¤¾à¤®à¤¾à¤¨ à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤•à¤°à¥‡à¤‚',
  'deleteProduct': 'à¤¸à¤¾à¤®à¤¾à¤¨ à¤¹à¤Ÿà¤¾à¤à¤‚',
  'deleteProductConfirm': 'à¤•à¥à¤¯à¤¾ à¤†à¤ª à¤‡à¤¸ à¤‰à¤¤à¥à¤ªà¤¾à¤¦ à¤•à¥‹ à¤¹à¤Ÿà¤¾à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚?',
  'noProducts': 'à¤•à¥‹à¤ˆ à¤¸à¤¾à¤®à¤¾à¤¨ à¤¨à¤¹à¥€à¤‚',
  'addFirstProduct': 'à¤¶à¥à¤°à¥‚ à¤•à¤°à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤ªà¤¹à¤²à¤¾ à¤¸à¤¾à¤®à¤¾à¤¨ à¤œà¥‹à¤¡à¤¼à¥‡à¤‚',
  'allProducts': 'à¤¸à¤­à¥€',
  'productAdded': 'à¤¸à¤¾à¤®à¤¾à¤¨ à¤¸à¤«à¤²à¤¤à¤¾à¤ªà¥‚à¤°à¥à¤µà¤• à¤œà¥‹à¤¡à¤¼à¤¾ à¤—à¤¯à¤¾',
  'productUpdated': 'à¤¸à¤¾à¤®à¤¾à¤¨ à¤…à¤ªà¤¡à¥‡à¤Ÿ à¤¹à¥‹ à¤—à¤¯à¤¾',
  'productDeleted': 'à¤¸à¤¾à¤®à¤¾à¤¨ à¤¹à¤Ÿà¤¾ à¤¦à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾',
  'exportProducts': 'à¤ªà¥à¤°à¥‹à¤¡à¤•à¥à¤Ÿ à¤¨à¤¿à¤°à¥à¤¯à¤¾à¤¤ à¤•à¤°à¥‡à¤‚',
  'importProducts': 'à¤ªà¥à¤°à¥‹à¤¡à¤•à¥à¤Ÿ à¤†à¤¯à¤¾à¤¤ à¤•à¤°à¥‡à¤‚',
  'productCatalog': 'à¤ªà¥à¤°à¥‹à¤¡à¤•à¥à¤Ÿ à¤•à¥ˆà¤Ÿà¤²à¥‰à¤—',
  'selectProducts': 'à¤ªà¥à¤°à¥‹à¤¡à¤•à¥à¤Ÿ à¤šà¥à¤¨à¥‡à¤‚',
  'clear': 'à¤¸à¤¾à¤« à¤•à¤°à¥‡à¤‚',
  'customer': 'à¤—à¥à¤°à¤¾à¤¹à¤•',
  'customers': 'à¤—à¥à¤°à¤¾à¤¹à¤•',
  'customerName': 'à¤—à¥à¤°à¤¾à¤¹à¤• à¤•à¤¾ à¤¨à¤¾à¤®',
  'phone': 'à¤«à¥‹à¤¨',
  'address': 'à¤ªà¤¤à¤¾',
  'balance': 'à¤¬à¤•à¤¾à¤¯à¤¾',
  'payment': 'à¤­à¥à¤—à¤¤à¤¾à¤¨',
  'recordPayment': 'à¤­à¥à¤—à¤¤à¤¾à¤¨ à¤¦à¤°à¥à¤œ à¤•à¤°à¥‡à¤‚',
  'sendReminder': 'à¤¯à¤¾à¤¦ à¤¦à¤¿à¤²à¤¾à¤à¤‚',
  'reminder': 'à¤°à¤¿à¤®à¤¾à¤‡à¤‚à¤¡à¤°',
  'totalDue': 'à¤•à¥à¤² à¤¬à¤•à¤¾à¤¯à¤¾',
  'addCustomer': 'à¤—à¥à¤°à¤¾à¤¹à¤• à¤œà¥‹à¤¡à¤¼à¥‡à¤‚',
  'editCustomer': 'à¤—à¥à¤°à¤¾à¤¹à¤• à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤•à¤°à¥‡à¤‚',
  'noCustomers': 'à¤•à¥‹à¤ˆ à¤—à¥à¤°à¤¾à¤¹à¤• à¤¨à¤¹à¥€à¤‚',
  'addFirstCustomer': 'à¤‰à¤§à¤¾à¤° à¤Ÿà¥à¤°à¥ˆà¤• à¤•à¤°à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤—à¥à¤°à¤¾à¤¹à¤• à¤œà¥‹à¤¡à¤¼à¥‡à¤‚',
  'allCustomers': 'à¤¸à¤­à¥€',
  'withDue': 'à¤¬à¤•à¤¾à¤¯à¤¾ à¤µà¤¾à¤²à¥‡',
  'paid': 'à¤­à¥à¤—à¤¤à¤¾à¤¨ à¤•à¤¿à¤¯à¤¾',
  'daysAgo': '{days} à¤¦à¤¿à¤¨ à¤ªà¤¹à¤²à¥‡',
  'paymentRecorded': 'à¤­à¥à¤—à¤¤à¤¾à¤¨ à¤¦à¤°à¥à¤œ à¤¹à¥‹ à¤—à¤¯à¤¾',
  'transactions': 'à¤²à¥‡à¤¨à¤¦à¥‡à¤¨',
  'purchase': 'à¤–à¤°à¥€à¤¦',
  'noTransactions': 'à¤•à¥‹à¤ˆ à¤²à¥‡à¤¨à¤¦à¥‡à¤¨ à¤¨à¤¹à¥€à¤‚',
  'today': 'à¤†à¤œ',
  'thisWeek': 'à¤‡à¤¸ à¤¸à¤ªà¥à¤¤à¤¾à¤¹',
  'thisMonth': 'à¤‡à¤¸ à¤®à¤¹à¥€à¤¨à¥‡',
  'totalSales': 'à¤•à¥à¤² à¤¬à¤¿à¤•à¥à¤°à¥€',
  'billsCount': '{count} à¤¬à¤¿à¤²',
  'averageBill': 'à¤”à¤¸à¤¤',
  'exportPdf': 'à¤ªà¥€à¤¡à¥€à¤à¤« à¤¨à¤¿à¤°à¥à¤¯à¤¾à¤¤',
  'topSellingProducts': 'à¤¸à¤¬à¤¸à¥‡ à¤œà¥à¤¯à¤¾à¤¦à¤¾ à¤¬à¤¿à¤•à¤¨à¥‡ à¤µà¤¾à¤²à¥‡',
  'noSalesData': 'à¤¬à¤¿à¤•à¥à¤°à¥€ à¤¡à¥‡à¤Ÿà¤¾ à¤‰à¤ªà¤²à¤¬à¥à¤§ à¤¨à¤¹à¥€à¤‚',
  'unitsSold': '{count} à¤¯à¥‚à¤¨à¤¿à¤Ÿ à¤¬à¤¿à¤•à¥‡',
  'recentBills': 'à¤¹à¤¾à¤² à¤•à¥‡ à¤¬à¤¿à¤²',
  'shopDetails': 'à¤¦à¥à¤•à¤¾à¤¨ à¤µà¤¿à¤µà¤°à¤£',
  'shopName': 'à¤¦à¥à¤•à¤¾à¤¨ à¤•à¤¾ à¤¨à¤¾à¤®',
  'ownerName': 'à¤®à¤¾à¤²à¤¿à¤• à¤•à¤¾ à¤¨à¤¾à¤®',
  'gstNumber': 'à¤œà¥€à¤à¤¸à¤Ÿà¥€ à¤¨à¤‚à¤¬à¤°',
  'subscription': 'à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾',
  'freePlan': 'à¤®à¥à¤«à¥à¤¤ à¤ªà¥à¤²à¤¾à¤¨',
  'premiumPlan': 'à¤ªà¥à¤°à¥€à¤®à¤¿à¤¯à¤® à¤ªà¥à¤²à¤¾à¤¨',
  'unlimitedAccess': 'à¤…à¤¸à¥€à¤®à¤¿à¤¤ à¤¸à¤¾à¤®à¤¾à¤¨ à¤”à¤° à¤¬à¤¿à¤²',
  'limitedAccess': '{products} à¤¸à¤¾à¤®à¤¾à¤¨, {bills} à¤¬à¤¿à¤²/à¤¦à¤¿à¤¨',
  'upgradeToPremium': 'à¤ªà¥à¤°à¥€à¤®à¤¿à¤¯à¤® à¤®à¥‡à¤‚ à¤…à¤ªà¤—à¥à¤°à¥‡à¤¡ à¤•à¤°à¥‡à¤‚',
  'appearance': 'à¤¦à¤¿à¤–à¤¾à¤µà¤Ÿ',
  'darkMode': 'à¤¡à¤¾à¤°à¥à¤• à¤®à¥‹à¤¡',
  'language': 'à¤­à¤¾à¤·à¤¾',
  'selectLanguage': 'à¤­à¤¾à¤·à¤¾ à¤šà¥à¤¨à¥‡à¤‚',
  'english': 'English',
  'hindi': 'à¤¹à¤¿à¤‚à¤¦à¥€',
  'telugu': 'à°¤à±†à°²à±à°—à±',
  'printer': 'à¤ªà¥à¤°à¤¿à¤‚à¤Ÿà¤° à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤¸',
  'configurePrinter': 'à¤ªà¥à¤°à¤¿à¤‚à¤Ÿà¤° à¤•à¥‰à¤¨à¥à¤«à¤¼à¤¿à¤—à¤° à¤•à¤°à¥‡à¤‚',
  'dataManagement': 'à¤¡à¥‡à¤Ÿà¤¾ à¤ªà¥à¤°à¤¬à¤‚à¤§à¤¨',
  'backupData': 'à¤¡à¥‡à¤Ÿà¤¾ à¤¬à¥ˆà¤•à¤…à¤ª',
  'exportData': 'à¤¡à¥‡à¤Ÿà¤¾ à¤¨à¤¿à¤°à¥à¤¯à¤¾à¤¤',
  'support': 'à¤¸à¤¹à¤¾à¤¯à¤¤à¤¾',
  'helpCenter': 'à¤¸à¤¹à¤¾à¤¯à¤¤à¤¾ à¤•à¥‡à¤‚à¤¦à¥à¤°',
  'sendFeedback': 'à¤«à¥€à¤¡à¤¬à¥ˆà¤• à¤­à¥‡à¤œà¥‡à¤‚',
  'rateApp': 'à¤à¤ª à¤°à¥‡à¤Ÿ à¤•à¤°à¥‡à¤‚',
  'about': 'à¤¬à¤¾à¤°à¥‡ à¤®à¥‡à¤‚',
  'version': 'à¤µà¤°à¥à¤œà¤¨',
  'signOut': 'à¤¸à¤¾à¤‡à¤¨ à¤†à¤‰à¤Ÿ',
  'signOutConfirm': 'à¤•à¥à¤¯à¤¾ à¤†à¤ª à¤¸à¤¾à¤‡à¤¨ à¤†à¤‰à¤Ÿ à¤•à¤°à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚?',
  'login': 'à¤²à¥‰à¤—à¤¿à¤¨',
  'signUp': 'à¤¸à¤¾à¤‡à¤¨ à¤…à¤ª',
  'email': 'à¤ˆà¤®à¥‡à¤²',
  'password': 'à¤ªà¤¾à¤¸à¤µà¤°à¥à¤¡',
  'forgotPassword': 'à¤ªà¤¾à¤¸à¤µà¤°à¥à¤¡ à¤­à¥‚à¤² à¤—à¤?',
  'welcomeBack': 'à¤µà¤¾à¤ªà¤¸à¥€ à¤ªà¤° à¤¸à¥à¤µà¤¾à¤—à¤¤!',
  'loginToContinue': 'à¤…à¤ªà¤¨à¥€ à¤¦à¥à¤•à¤¾à¤¨ à¤®à¥‡à¤‚ à¤œà¤¾à¤°à¥€ à¤°à¤–à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤²à¥‰à¤—à¤¿à¤¨ à¤•à¤°à¥‡à¤‚',
  'dontHaveAccount': 'à¤–à¤¾à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆ?',
  'alreadyHaveAccount': 'à¤ªà¤¹à¤²à¥‡ à¤¸à¥‡ à¤–à¤¾à¤¤à¤¾ à¤¹à¥ˆ?',
  'createAccount': 'à¤–à¤¾à¤¤à¤¾ à¤¬à¤¨à¤¾à¤à¤‚',
  'setupShop': 'à¤…à¤ªà¤¨à¥€ à¤¦à¥à¤•à¤¾à¤¨ à¤¸à¥‡à¤Ÿà¤…à¤ª à¤•à¤°à¥‡à¤‚',
  'enterShopDetails': 'à¤¶à¥à¤°à¥‚ à¤•à¤°à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤¦à¥à¤•à¤¾à¤¨ à¤µà¤¿à¤µà¤°à¤£ à¤¦à¤°à¥à¤œ à¤•à¤°à¥‡à¤‚',
  'getStarted': 'à¤¶à¥à¤°à¥‚ à¤•à¤°à¥‡à¤‚',
  'resetPassword': 'à¤ªà¤¾à¤¸à¤µà¤°à¥à¤¡ à¤°à¥€à¤¸à¥‡à¤Ÿ à¤•à¤°à¥‡à¤‚',
  'sendResetLink': 'à¤°à¥€à¤¸à¥‡à¤Ÿ à¤²à¤¿à¤‚à¤• à¤­à¥‡à¤œà¥‡à¤‚',
  'backToLogin': 'à¤²à¥‰à¤—à¤¿à¤¨ à¤ªà¤° à¤µà¤¾à¤ªà¤¸ à¤œà¤¾à¤à¤‚',
  // Settings extras
  'syncNow': 'à¤…à¤­à¥€ à¤¸à¤¿à¤‚à¤• à¤•à¤°à¥‡à¤‚',
  'syncStatus': 'à¤¸à¤¿à¤‚à¤• à¤¸à¥à¤¥à¤¿à¤¤à¤¿',
  'syncInterval': 'à¤¸à¤¿à¤‚à¤• à¤…à¤‚à¤¤à¤°à¤¾à¤²',
  'dataRetention': 'à¤¡à¥‡à¤Ÿà¤¾ à¤…à¤µà¤§à¤¿',
  'paperSize': 'à¤ªà¥‡à¤ªà¤° à¤¸à¤¾à¤‡à¤œà¤¼',
  'fontSize': 'à¤«à¥‰à¤¨à¥à¤Ÿ à¤¸à¤¾à¤‡à¤œà¤¼',
  'printerSettings': 'à¤ªà¥à¤°à¤¿à¤‚à¤Ÿà¤° à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤¸',
  'editShopDetails': 'à¤¦à¥à¤•à¤¾à¤¨ à¤µà¤¿à¤µà¤°à¤£ à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤•à¤°à¥‡à¤‚',
  'connected': 'à¤•à¤¨à¥‡à¤•à¥à¤Ÿà¥‡à¤¡',
  'notConnected': 'à¤•à¤¨à¥‡à¤•à¥à¤Ÿ à¤¨à¤¹à¥€à¤‚',
  'logout': 'à¤²à¥‰à¤—à¤†à¤‰à¤Ÿ',
  'on': 'à¤šà¤¾à¤²à¥‚',
  'off': 'à¤¬à¤‚à¤¦',
  'shopInformation': 'à¤¦à¥à¤•à¤¾à¤¨ à¤•à¥€ à¤œà¤¾à¤¨à¤•à¤¾à¤°à¥€',
  'appSettings': 'à¤à¤ª à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤¸',
  'sync': 'à¤¸à¤¿à¤‚à¤•',
  'pendingChanges': 'à¤²à¤‚à¤¬à¤¿à¤¤ à¤ªà¤°à¤¿à¤µà¤°à¥à¤¤à¤¨',
  'uploadPendingChanges': 'à¤²à¤‚à¤¬à¤¿à¤¤ à¤ªà¤°à¤¿à¤µà¤°à¥à¤¤à¤¨ à¤…à¤ªà¤²à¥‹à¤¡ à¤•à¤°à¥‡à¤‚',
  'syncCompleted': 'à¤¸à¤¿à¤‚à¤• à¤ªà¥‚à¤°à¥à¤£!',
  'syncFailed': 'à¤¸à¤¿à¤‚à¤• à¤µà¤¿à¤«à¤²',
  'loginEmail': 'à¤²à¥‰à¤—à¤¿à¤¨ à¤ˆà¤®à¥‡à¤²',
  'days': 'à¤¦à¤¿à¤¨',
  'error': 'à¤¤à¥à¤°à¥à¤Ÿà¤¿',
  'somethingWentWrong': 'à¤•à¥à¤› à¤—à¤²à¤¤ à¤¹à¥‹ à¤—à¤¯à¤¾',
  'networkError': 'à¤¨à¥‡à¤Ÿà¤µà¤°à¥à¤• à¤¤à¥à¤°à¥à¤Ÿà¤¿à¥¤ à¤•à¥ƒà¤ªà¤¯à¤¾ à¤•à¤¨à¥‡à¤•à¥à¤¶à¤¨ à¤œà¤¾à¤‚à¤šà¥‡à¤‚à¥¤',
  'tryAgain': 'à¤ªà¥à¤¨à¤ƒ à¤ªà¥à¤°à¤¯à¤¾à¤¸ à¤•à¤°à¥‡à¤‚',
  // Privacy & Data
  'accountSettings': 'à¤–à¤¾à¤¤à¤¾ à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤¸',
  'downloadMyData': 'à¤®à¥‡à¤°à¤¾ à¤¡à¥‡à¤Ÿà¤¾ à¤¡à¤¾à¤‰à¤¨à¤²à¥‹à¤¡ à¤•à¤°à¥‡à¤‚',
  'exportDataAsJson': 'à¤…à¤ªà¤¨à¤¾ à¤¸à¤¾à¤°à¤¾ à¤¡à¥‡à¤Ÿà¤¾ JSON à¤®à¥‡à¤‚ à¤¨à¤¿à¤°à¥à¤¯à¤¾à¤¤ à¤•à¤°à¥‡à¤‚',
  'privacyPolicy': 'à¤—à¥‹à¤ªà¤¨à¥€à¤¯à¤¤à¤¾ à¤¨à¥€à¤¤à¤¿',
  'termsOfService': 'à¤¸à¥‡à¤µà¤¾ à¤•à¥€ à¤¶à¤°à¥à¤¤à¥‡à¤‚',
  'deleteAccount': 'à¤–à¤¾à¤¤à¤¾ à¤¹à¤Ÿà¤¾à¤à¤‚?',
  'deleteEverything': 'à¤¸à¤¬ à¤•à¥à¤› à¤¹à¤Ÿà¤¾à¤à¤‚',
  'typeDeleteToConfirm': 'à¤ªà¥à¤·à¥à¤Ÿà¤¿ à¤•à¥‡ à¤²à¤¿à¤ DELETE à¤Ÿà¤¾à¤‡à¤ª à¤•à¤°à¥‡à¤‚',
  'confirmDelete': 'à¤¹à¤Ÿà¤¾à¤¨à¤¾ à¤ªà¥à¤·à¥à¤Ÿà¤¿ à¤•à¤°à¥‡à¤‚',
  'deletingAccount': 'à¤–à¤¾à¤¤à¤¾ à¤”à¤° à¤¸à¤¾à¤°à¤¾ à¤¡à¥‡à¤Ÿà¤¾ à¤¹à¤Ÿà¤¾à¤¯à¤¾ à¤œà¤¾ à¤°à¤¹à¤¾ à¤¹à¥ˆ...',
  'deleteAccountFailed': 'à¤–à¤¾à¤¤à¤¾ à¤¹à¤Ÿà¤¾à¤¨à¥‡ à¤®à¥‡à¤‚ à¤µà¤¿à¤«à¤²à¥¤ à¤•à¥ƒà¤ªà¤¯à¤¾ à¤ªà¥à¤¨à¤ƒ à¤ªà¥à¤°à¤¯à¤¾à¤¸ à¤•à¤°à¥‡à¤‚à¥¤',
  'preparingDataExport': 'à¤†à¤ªà¤•à¤¾ à¤¡à¥‡à¤Ÿà¤¾ à¤¨à¤¿à¤°à¥à¤¯à¤¾à¤¤ à¤¤à¥ˆà¤¯à¤¾à¤° à¤•à¤¿à¤¯à¤¾ à¤œà¤¾ à¤°à¤¹à¤¾ à¤¹à¥ˆ...',
  'accountSettingsSaved': 'à¤–à¤¾à¤¤à¤¾ à¤¸à¥‡à¤Ÿà¤¿à¤‚à¤—à¥à¤¸ à¤¸à¤¹à¥‡à¤œà¥€ à¤—à¤ˆà¤‚',
  // Subscription
  'subscriptionPlans': 'à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤¯à¥‹à¤œà¤¨à¤¾à¤à¤‚',
  'current': 'à¤µà¤°à¥à¤¤à¤®à¤¾à¤¨',
  'upgrade': 'à¤…à¤ªà¤—à¥à¤°à¥‡à¤¡',
  'manage': 'à¤ªà¥à¤°à¤¬à¤‚à¤§à¤¿à¤¤ à¤•à¤°à¥‡à¤‚',
  'upgradeComingSoon': 'à¤…à¤ªà¤—à¥à¤°à¥‡à¤¡ à¤œà¤²à¥à¤¦ à¤† à¤°à¤¹à¤¾ à¤¹à¥ˆ!',
  // Referral
  'shareInviteLink': 'à¤†à¤®à¤‚à¤¤à¥à¤°à¤£ à¤²à¤¿à¤‚à¤• à¤¸à¤¾à¤à¤¾ à¤•à¤°à¥‡à¤‚',
  'enterFriendCode': 'à¤¦à¥‹à¤¸à¥à¤¤ à¤•à¤¾ à¤•à¥‹à¤¡ à¤¹à¥ˆ? à¤¯à¤¹à¤¾à¤‚ à¤¦à¤°à¥à¤œ à¤•à¤°à¥‡à¤‚',
  'enterReferralCode': 'à¤°à¥‡à¤«à¤°à¤² à¤•à¥‹à¤¡ à¤¦à¤°à¥à¤œ à¤•à¤°à¥‡à¤‚',
  'apply': 'à¤²à¤¾à¤—à¥‚ à¤•à¤°à¥‡à¤‚',
  'referralCodeApplied': 'à¤°à¥‡à¤«à¤°à¤² à¤•à¥‹à¤¡ à¤²à¤¾à¤—à¥‚ à¤¹à¥‹ à¤—à¤¯à¤¾!',
  'exportFailed': 'à¤¨à¤¿à¤°à¥à¤¯à¤¾à¤¤ à¤µà¤¿à¤«à¤²',
  'comingSoon': 'à¤œà¤²à¥à¤¦ à¤† à¤°à¤¹à¤¾ à¤¹à¥ˆ!',
};

// ============ TELUGU STRINGS ============
const Map<String, String> _teluguStrings = {
  'appName': 'Tulasi Hotels',
  'appTagline': 'à°­à°¾à°°à°¤à°¦à±‡à°¶à°‚ à°¯à±Šà°•à±à°• à°¸à±à°²à°­à°®à±ˆà°¨ à°¬à°¿à°²à±à°²à°¿à°‚à°—à± à°¯à°¾à°ªà±',
  'billing': 'à°¬à°¿à°²à±à°²à°¿à°‚à°—à±',
  'khata': 'à°–à°¾à°¤à°¾',
  'products': 'à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à±',
  'reports': 'à°°à°¿à°ªà±‹à°°à±à°Ÿà±à°²à±',
  'dashboard': 'à°¡à°¾à°·à±â€Œà°¬à±‹à°°à±à°¡à±',
  'settings': 'à°¸à±†à°Ÿà±à°Ÿà°¿à°‚à°—à±à°¸à±',
  'save': 'à°¸à±‡à°µà±',
  'cancel': 'à°°à°¦à±à°¦à±',
  'delete': 'à°¤à±Šà°²à°—à°¿à°‚à°šà±',
  'add': 'à°œà±‹à°¡à°¿à°‚à°šà±',
  'edit': 'à°¸à°µà°°à°¿à°‚à°šà±',
  'search': 'à°µà±†à°¤à°•à°‚à°¡à°¿',
  'searchProducts': 'à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à°¨à± à°µà±†à°¤à°•à°‚à°¡à°¿...',
  'share': 'à°·à±‡à°°à±',
  'close': 'à°®à±‚à°¸à°¿à°µà±‡à°¯à°‚à°¡à°¿',
  'confirm': 'à°¨à°¿à°°à±à°§à°¾à°°à°¿à°‚à°šà±',
  'retry': 'à°®à°³à±à°³à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
  'loading': 'à°²à±‹à°¡à± à°…à°µà±à°¤à±‹à°‚à°¦à°¿...',
  'noData': 'à°¡à±‡à°Ÿà°¾ à°²à±‡à°¦à±',
  'total': 'à°®à±Šà°¤à±à°¤à°‚',
  'subTotal': 'à°‰à°ª à°®à±Šà°¤à±à°¤à°‚',
  'cash': 'à°¨à°—à°¦à±',
  'upi': 'à°¯à±à°ªà°¿à°',
  'udhar': 'à°…à°°à±à°µà±',
  'pay': 'à°šà±†à°²à±à°²à°¿à°‚à°šà±',
  'payNow': 'à°‡à°ªà±à°ªà±à°¡à± à°šà±†à°²à±à°²à°¿à°‚à°šà±',
  'receivedAmount': 'à°…à°‚à°¦à°¿à°¨ à°®à±Šà°¤à±à°¤à°‚',
  'change': 'à°šà°¿à°²à±à°²à°°',
  'quickAmounts': 'à°¤à±à°µà°°à°¿à°¤ à°®à±Šà°¤à±à°¤à°¾à°²à±',
  'selectPaymentMethod': 'à°šà±†à°²à±à°²à°¿à°‚à°ªà± à°µà°¿à°§à°¾à°¨à°‚ à°Žà°‚à°šà±à°•à±‹à°‚à°¡à°¿',
  'billComplete': 'à°¬à°¿à°²à±à°²à± à°ªà±‚à°°à±à°¤à°¿!',
  'billNumber': 'à°¬à°¿à°²à±à°²à± #{number}',
  'printReceipt': 'à°°à°¸à±€à°¦à± à°ªà±à°°à°¿à°‚à°Ÿà±',
  'shareReceipt': 'à°°à°¸à±€à°¦à± à°·à±‡à°°à±',
  'newBill': 'à°•à±Šà°¤à±à°¤ à°¬à°¿à°²à±à°²à±',
  'cart': 'à°•à°¾à°°à±à°Ÿà±',
  'emptyCart': 'à°•à°¾à°°à±à°Ÿà± à°–à°¾à°³à±€à°—à°¾ à°‰à°‚à°¦à°¿',
  'addProductsToCart': 'à°¬à°¿à°²à±à°²à°¿à°‚à°—à± à°ªà±à°°à°¾à°°à°‚à°­à°¿à°‚à°šà°¡à°¾à°¨à°¿à°•à°¿ à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à°¨à± à°œà±‹à°¡à°¿à°‚à°šà°‚à°¡à°¿',
  'itemsInCart': '{count} à°à°Ÿà°®à±à°¸à±',
  'scanBarcode': 'à°¬à°¾à°°à±â€Œà°•à±‹à°¡à± à°¸à±à°•à°¾à°¨à±',
  'barcode': 'à°¬à°¾à°°à±â€Œà°•à±‹à°¡à±',
  'productName': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°ªà±‡à°°à±',
  'price': 'à°§à°°',
  'sellingPrice': 'à°…à°®à±à°®à°•à°ªà± à°§à°°',
  'purchasePrice': 'à°•à±Šà°¨à±à°—à±‹à°²à± à°§à°°',
  'stock': 'à°¸à±à°Ÿà°¾à°•à±',
  'unit': 'à°¯à±‚à°¨à°¿à°Ÿà±',
  'lowStock': 'à°¤à°•à±à°•à±à°µ à°¸à±à°Ÿà°¾à°•à±',
  'outOfStock': 'à°¸à±à°Ÿà°¾à°•à± à°²à±‡à°¦à±',
  'lowStockAlert': 'à°¤à°•à±à°•à±à°µ à°¸à±à°Ÿà°¾à°•à± à°¹à±†à°šà±à°šà°°à°¿à°•',
  'addProduct': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°œà±‹à°¡à°¿à°‚à°šà±',
  'editProduct': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°¸à°µà°°à°¿à°‚à°šà±',
  'deleteProduct': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°¤à±Šà°²à°—à°¿à°‚à°šà±',
  'deleteProductConfirm': 'à°®à±€à°°à± à°ˆ à°‰à°¤à±à°ªà°¤à±à°¤à°¿à°¨à°¿ à°¤à±Šà°²à°—à°¿à°‚à°šà°¾à°²à°¨à±à°•à±à°‚à°Ÿà±à°¨à±à°¨à°¾à°°à°¾?',
  'noProducts': 'à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à± à°²à±‡à°µà±',
  'addFirstProduct': 'à°ªà±à°°à°¾à°°à°‚à°­à°¿à°‚à°šà°¡à°¾à°¨à°¿à°•à°¿ à°®à±Šà°¦à°Ÿà°¿ à°‰à°¤à±à°ªà°¤à±à°¤à°¿à°¨à°¿ à°œà±‹à°¡à°¿à°‚à°šà°‚à°¡à°¿',
  'allProducts': 'à°…à°¨à±à°¨à±€',
  'productAdded': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°µà°¿à°œà°¯à°µà°‚à°¤à°‚à°—à°¾ à°œà±‹à°¡à°¿à°‚à°šà°¬à°¡à°¿à°‚à°¦à°¿',
  'productUpdated': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°¨à°µà±€à°•à°°à°¿à°‚à°šà°¬à°¡à°¿à°‚à°¦à°¿',
  'productDeleted': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°¤à±Šà°²à°—à°¿à°‚à°šà°¬à°¡à°¿à°‚à°¦à°¿',
  'exportProducts': 'à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à°¨à± à°Žà°—à±à°®à°¤à°¿ à°šà±‡à°¯à°‚à°¡à°¿',
  'importProducts': 'à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à°¨à± à°¦à°¿à°—à±à°®à°¤à°¿ à°šà±‡à°¯à°‚à°¡à°¿',
  'productCatalog': 'à°‰à°¤à±à°ªà°¤à±à°¤à°¿ à°•à°¾à°Ÿà°²à°¾à°—à±',
  'selectProducts': 'à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à°¨à± à°Žà°‚à°šà±à°•à±‹à°‚à°¡à°¿',
  'clear': 'à°•à±à°²à°¿à°¯à°°à±',
  'customer': 'à°•à°¸à±à°Ÿà°®à°°à±',
  'customers': 'à°•à°¸à±à°Ÿà°®à°°à±à°²à±',
  'customerName': 'à°•à°¸à±à°Ÿà°®à°°à± à°ªà±‡à°°à±',
  'phone': 'à°«à±‹à°¨à±',
  'address': 'à°šà°¿à°°à±à°¨à°¾à°®à°¾',
  'balance': 'à°¬à±à°¯à°¾à°²à±†à°¨à±à°¸à±',
  'payment': 'à°šà±†à°²à±à°²à°¿à°‚à°ªà±',
  'recordPayment': 'à°šà±†à°²à±à°²à°¿à°‚à°ªà± à°¨à°®à±‹à°¦à±',
  'sendReminder': 'à°°à°¿à°®à±ˆà°‚à°¡à°°à± à°ªà°‚à°ªà±',
  'reminder': 'à°°à°¿à°®à±ˆà°‚à°¡à°°à±',
  'totalDue': 'à°®à±Šà°¤à±à°¤à°‚ à°¬à°•à°¾à°¯à°¿',
  'addCustomer': 'à°•à°¸à±à°Ÿà°®à°°à± à°œà±‹à°¡à°¿à°‚à°šà±',
  'editCustomer': 'à°•à°¸à±à°Ÿà°®à°°à± à°¸à°µà°°à°¿à°‚à°šà±',
  'noCustomers': 'à°•à°¸à±à°Ÿà°®à°°à±à°²à± à°²à±‡à°°à±',
  'addFirstCustomer': 'à°…à°°à±à°µà± à°Ÿà±à°°à°¾à°•à± à°šà±‡à°¯à°¡à°¾à°¨à°¿à°•à°¿ à°•à°¸à±à°Ÿà°®à°°à± à°œà±‹à°¡à°¿à°‚à°šà°‚à°¡à°¿',
  'allCustomers': 'à°…à°‚à°¦à°°à±‚',
  'withDue': 'à°¬à°•à°¾à°¯à°¿ à°‰à°¨à±à°¨à°µà°¾à°°à±',
  'paid': 'à°šà±†à°²à±à°²à°¿à°‚à°šà°¾à°°à±',
  'daysAgo': '{days} à°°à±‹à°œà±à°² à°•à±à°°à°¿à°¤à°‚',
  'paymentRecorded': 'à°šà±†à°²à±à°²à°¿à°‚à°ªà± à°¨à°®à±‹à°¦à± à°…à°¯à°¿à°‚à°¦à°¿',
  'transactions': 'à°²à°¾à°µà°¾à°¦à±‡à°µà±€à°²à±',
  'purchase': 'à°•à±Šà°¨à±à°—à±‹à°²à±',
  'noTransactions': 'à°²à°¾à°µà°¾à°¦à±‡à°µà±€à°²à± à°²à±‡à°µà±',
  'today': 'à°ˆà°°à±‹à°œà±',
  'thisWeek': 'à°ˆ à°µà°¾à°°à°‚',
  'thisMonth': 'à°ˆ à°¨à±†à°²',
  'totalSales': 'à°®à±Šà°¤à±à°¤à°‚ à°…à°®à±à°®à°•à°¾à°²à±',
  'billsCount': '{count} à°¬à°¿à°²à±à°²à±à°²à±',
  'averageBill': 'à°¸à°—à°Ÿà±',
  'exportPdf': 'PDF à°Žà°—à±à°®à°¤à°¿',
  'topSellingProducts': 'à°Žà°•à±à°•à±à°µà°—à°¾ à°…à°®à±à°®à±à°¡à±ˆà°¨à°µà°¿',
  'noSalesData': 'à°…à°®à±à°®à°•à°¾à°² à°¡à±‡à°Ÿà°¾ à°²à±‡à°¦à±',
  'unitsSold': '{count} à°¯à±‚à°¨à°¿à°Ÿà±à°²à± à°…à°®à±à°®à±à°¡à°¯à±à°¯à°¾à°¯à°¿',
  'recentBills': 'à°‡à°Ÿà±€à°µà°²à°¿ à°¬à°¿à°²à±à°²à±à°²à±',
  'shopDetails': 'à°·à°¾à°ªà± à°µà°¿à°µà°°à°¾à°²à±',
  'shopName': 'à°·à°¾à°ªà± à°ªà±‡à°°à±',
  'ownerName': 'à°¯à°œà°®à°¾à°¨à°¿ à°ªà±‡à°°à±',
  'gstNumber': 'GST à°¨à°‚à°¬à°°à±',
  'subscription': 'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à±',
  'freePlan': 'à°«à±à°°à±€ à°ªà±à°²à°¾à°¨à±',
  'premiumPlan': 'à°ªà±à°°à±€à°®à°¿à°¯à°‚ à°ªà±à°²à°¾à°¨à±',
  'unlimitedAccess': 'à°…à°ªà°°à°¿à°®à°¿à°¤ à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à± & à°¬à°¿à°²à±à°²à±à°²à±',
  'limitedAccess': '{products} à°‰à°¤à±à°ªà°¤à±à°¤à±à°²à±, {bills} à°¬à°¿à°²à±à°²à±à°²à±/à°°à±‹à°œà±',
  'upgradeToPremium': 'à°ªà±à°°à±€à°®à°¿à°¯à°‚à°•à± à°…à°ªà±â€Œà°—à±à°°à±‡à°¡à±',
  'appearance': 'à°°à±‚à°ªà°‚',
  'darkMode': 'à°¡à°¾à°°à±à°•à± à°®à±‹à°¡à±',
  'language': 'à°­à°¾à°·',
  'selectLanguage': 'à°­à°¾à°· à°Žà°‚à°šà±à°•à±‹à°‚à°¡à°¿',
  'english': 'English',
  'hindi': 'à¤¹à¤¿à¤‚à¤¦à¥€',
  'telugu': 'à°¤à±†à°²à±à°—à±',
  'printer': 'à°ªà±à°°à°¿à°‚à°Ÿà°°à± à°¸à±†à°Ÿà±à°Ÿà°¿à°‚à°—à±à°¸à±',
  'configurePrinter': 'à°ªà±à°°à°¿à°‚à°Ÿà°°à± à°•à°¾à°¨à±à°«à°¿à°—à°°à±',
  'dataManagement': 'à°¡à±‡à°Ÿà°¾ à°¨à°¿à°°à±à°µà°¹à°£',
  'backupData': 'à°¡à±‡à°Ÿà°¾ à°¬à±à°¯à°¾à°•à°ªà±',
  'exportData': 'à°¡à±‡à°Ÿà°¾ à°Žà°—à±à°®à°¤à°¿',
  'support': 'à°¸à°ªà±‹à°°à±à°Ÿà±',
  'helpCenter': 'à°¸à°¹à°¾à°¯ à°•à±‡à°‚à°¦à±à°°à°‚',
  'sendFeedback': 'à°«à±€à°¡à±â€Œà°¬à±à°¯à°¾à°•à± à°ªà°‚à°ªà±',
  'rateApp': 'à°¯à°¾à°ªà± à°°à±‡à°Ÿà± à°šà±‡à°¯à°‚à°¡à°¿',
  'about': 'à°—à±à°°à°¿à°‚à°šà°¿',
  'version': 'à°µà±†à°°à±à°·à°¨à±',
  'signOut': 'à°¸à±ˆà°¨à± à°”à°Ÿà±',
  'signOutConfirm': 'à°®à±€à°°à± à°¸à±ˆà°¨à± à°”à°Ÿà± à°šà±‡à°¯à°¾à°²à°¨à±à°•à±à°‚à°Ÿà±à°¨à±à°¨à°¾à°°à°¾?',
  'login': 'à°²à°¾à°—à°¿à°¨à±',
  'signUp': 'à°¸à±ˆà°¨à± à°…à°ªà±',
  'email': 'à°‡à°®à±†à°¯à°¿à°²à±',
  'password': 'à°ªà°¾à°¸à±â€Œà°µà°°à±à°¡à±',
  'forgotPassword': 'à°ªà°¾à°¸à±â€Œà°µà°°à±à°¡à± à°®à°°à±à°šà°¿à°ªà±‹à°¯à°¾à°°à°¾?',
  'welcomeBack': 'à°¤à°¿à°°à°¿à°—à°¿ à°¸à±à°µà°¾à°—à°¤à°‚!',
  'loginToContinue': 'à°®à±€ à°·à°¾à°ªà±â€Œà°²à±‹ à°•à±Šà°¨à°¸à°¾à°—à°¿à°‚à°šà°¡à°¾à°¨à°¿à°•à°¿ à°²à°¾à°—à°¿à°¨à± à°…à°µà±à°µà°‚à°¡à°¿',
  'dontHaveAccount': 'à°–à°¾à°¤à°¾ à°²à±‡à°¦à°¾?',
  'alreadyHaveAccount': 'à°‡à°ªà±à°ªà°Ÿà°¿à°•à±‡ à°–à°¾à°¤à°¾ à°‰à°‚à°¦à°¾?',
  'createAccount': 'à°–à°¾à°¤à°¾ à°¸à±ƒà°·à±à°Ÿà°¿à°‚à°šà±',
  'setupShop': 'à°®à±€ à°·à°¾à°ªà± à°¸à±†à°Ÿà°ªà± à°šà±‡à°¯à°‚à°¡à°¿',
  'enterShopDetails': 'à°ªà±à°°à°¾à°°à°‚à°­à°¿à°‚à°šà°¡à°¾à°¨à°¿à°•à°¿ à°·à°¾à°ªà± à°µà°¿à°µà°°à°¾à°²à± à°¨à°®à±‹à°¦à± à°šà±‡à°¯à°‚à°¡à°¿',
  'getStarted': 'à°ªà±à°°à°¾à°°à°‚à°­à°¿à°‚à°šà±',
  'resetPassword': 'à°ªà°¾à°¸à±â€Œà°µà°°à±à°¡à± à°°à±€à°¸à±†à°Ÿà±',
  'sendResetLink': 'à°°à±€à°¸à±†à°Ÿà± à°²à°¿à°‚à°•à± à°ªà°‚à°ªà±',
  'backToLogin': 'à°²à°¾à°—à°¿à°¨à±â€Œà°•à± à°¤à°¿à°°à°¿à°—à°¿ à°µà±†à°³à±à°³à±',
  // Settings extras
  'syncNow': 'à°‡à°ªà±à°ªà±à°¡à± à°¸à°¿à°‚à°•à±',
  'syncStatus': 'à°¸à°¿à°‚à°•à± à°¸à±à°¥à°¿à°¤à°¿',
  'syncInterval': 'à°¸à°¿à°‚à°•à± à°µà±à°¯à°µà°§à°¿',
  'dataRetention': 'à°¡à±‡à°Ÿà°¾ à°¨à°¿à°²à±à°ªà±à°¦à°²',
  'paperSize': 'à°ªà±‡à°ªà°°à± à°¸à±ˆà°œà±',
  'fontSize': 'à°«à°¾à°‚à°Ÿà± à°¸à±ˆà°œà±',
  'printerSettings': 'à°ªà±à°°à°¿à°‚à°Ÿà°°à± à°¸à±†à°Ÿà±à°Ÿà°¿à°‚à°—à±à°¸à±',
  'editShopDetails': 'à°·à°¾à°ªà± à°µà°¿à°µà°°à°¾à°²à± à°¸à°µà°°à°¿à°‚à°šà±',
  'connected': 'à°•à°¨à±†à°•à±à°Ÿà± à°…à°¯à°¿à°‚à°¦à°¿',
  'notConnected': 'à°•à°¨à±†à°•à±à°Ÿà± à°•à°¾à°²à±‡à°¦à±',
  'logout': 'à°²à°¾à°—à±Œà°Ÿà±',
  'on': 'à°†à°¨à±',
  'off': 'à°†à°«à±',
  'shopInformation': 'à°·à°¾à°ªà± à°¸à°®à°¾à°šà°¾à°°à°‚',
  'appSettings': 'à°¯à°¾à°ªà± à°¸à±†à°Ÿà±à°Ÿà°¿à°‚à°—à±à°¸à±',
  'sync': 'à°¸à°¿à°‚à°•à±',
  'pendingChanges': 'à°ªà±†à°‚à°¡à°¿à°‚à°—à± à°®à°¾à°°à±à°ªà±à°²à±',
  'uploadPendingChanges': 'à°ªà±†à°‚à°¡à°¿à°‚à°—à± à°®à°¾à°°à±à°ªà±à°²à± à°…à°ªà±â€Œà°²à±‹à°¡à±',
  'syncCompleted': 'à°¸à°¿à°‚à°•à± à°ªà±‚à°°à±à°¤à°¯à°¿à°‚à°¦à°¿!',
  'syncFailed': 'à°¸à°¿à°‚à°•à± à°µà°¿à°«à°²à°®à±ˆà°‚à°¦à°¿',
  'loginEmail': 'à°²à°¾à°—à°¿à°¨à± à°‡à°®à±†à°¯à°¿à°²à±',
  'days': 'à°°à±‹à°œà±à°²à±',
  'error': 'à°²à±‹à°ªà°‚',
  'somethingWentWrong': 'à°à°¦à±‹ à°¤à°ªà±à°ªà± à°œà°°à°¿à°—à°¿à°‚à°¦à°¿',
  'networkError': 'à°¨à±†à°Ÿà±â€Œà°µà°°à±à°•à± à°²à±‹à°ªà°‚. à°¦à°¯à°šà±‡à°¸à°¿ à°•à°¨à±†à°•à±à°·à°¨à± à°¤à°¨à°¿à°–à±€ à°šà±‡à°¯à°‚à°¡à°¿.',
  'tryAgain': 'à°®à°³à±à°³à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
  // Privacy & Data
  'accountSettings': 'à°–à°¾à°¤à°¾ à°¸à±†à°Ÿà±à°Ÿà°¿à°‚à°—à±à°¸à±',
  'downloadMyData': 'à°¨à°¾ à°¡à±‡à°Ÿà°¾ à°¡à±Œà°¨à±â€Œà°²à±‹à°¡à±',
  'exportDataAsJson': 'à°®à±€ à°¡à±‡à°Ÿà°¾ à°®à±Šà°¤à±à°¤à°‚ JSON à°²à±‹ à°Žà°—à±à°®à°¤à°¿ à°šà±‡à°¯à°‚à°¡à°¿',
  'privacyPolicy': 'à°—à±‹à°ªà±à°¯à°¤à°¾ à°µà°¿à°§à°¾à°¨à°‚',
  'termsOfService': 'à°¸à±‡à°µà°¾ à°¨à°¿à°¬à°‚à°§à°¨à°²à±',
  'deleteAccount': 'à°–à°¾à°¤à°¾ à°¤à±Šà°²à°—à°¿à°‚à°šà°¾à°²à°¾?',
  'deleteEverything': 'à°…à°‚à°¤à°¾ à°¤à±Šà°²à°—à°¿à°‚à°šà±',
  'typeDeleteToConfirm': 'à°¨à°¿à°°à±à°§à°¾à°°à°¿à°‚à°šà°¡à°¾à°¨à°¿à°•à°¿ DELETE à°Ÿà±ˆà°ªà± à°šà±‡à°¯à°‚à°¡à°¿',
  'confirmDelete': 'à°¤à±Šà°²à°—à°¿à°‚à°ªà± à°¨à°¿à°°à±à°§à°¾à°°à°¿à°‚à°šà±',
  'deletingAccount': 'à°–à°¾à°¤à°¾ à°®à°°à°¿à°¯à± à°®à±Šà°¤à±à°¤à°‚ à°¡à±‡à°Ÿà°¾ à°¤à±Šà°²à°—à°¿à°‚à°šà°¬à°¡à±à°¤à±‹à°‚à°¦à°¿...',
  'deleteAccountFailed':
      'à°–à°¾à°¤à°¾ à°¤à±Šà°²à°—à°¿à°‚à°šà°¡à°‚ à°µà°¿à°«à°²à°®à±ˆà°‚à°¦à°¿. à°¦à°¯à°šà±‡à°¸à°¿ à°®à°³à±à°³à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
  'preparingDataExport': 'à°®à±€ à°¡à±‡à°Ÿà°¾ à°Žà°—à±à°®à°¤à°¿ à°¸à°¿à°¦à±à°§à°®à°µà±à°¤à±‹à°‚à°¦à°¿...',
  'accountSettingsSaved': 'à°–à°¾à°¤à°¾ à°¸à±†à°Ÿà±à°Ÿà°¿à°‚à°—à±à°¸à± à°­à°¦à±à°°à°ªà°°à°šà°¬à°¡à±à°¡à°¾à°¯à°¿',
  // Subscription
  'subscriptionPlans': 'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à± à°ªà±à°²à°¾à°¨à±à°¸à±',
  'current': 'à°ªà±à°°à°¸à±à°¤à±à°¤à°‚',
  'upgrade': 'à°…à°ªà±â€Œà°—à±à°°à±‡à°¡à±',
  'manage': 'à°¨à°¿à°°à±à°µà°¹à°¿à°‚à°šà±',
  'upgradeComingSoon': 'à°…à°ªà±â€Œà°—à±à°°à±‡à°¡à± à°¤à±à°µà°°à°²à±‹ à°µà°¸à±à°¤à±à°‚à°¦à°¿!',
  // Referral
  'shareInviteLink': 'à°†à°¹à±à°µà°¾à°¨ à°²à°¿à°‚à°•à± à°·à±‡à°°à± à°šà±‡à°¯à°‚à°¡à°¿',
  'enterFriendCode': 'à°¸à±à°¨à±‡à°¹à°¿à°¤à±à°¨à°¿ à°•à±‹à°¡à± à°‰à°‚à°¦à°¾? à°‡à°•à±à°•à°¡ à°¨à°®à±‹à°¦à± à°šà±‡à°¯à°‚à°¡à°¿',
  'enterReferralCode': 'à°°à°¿à°«à°°à°²à± à°•à±‹à°¡à± à°¨à°®à±‹à°¦à± à°šà±‡à°¯à°‚à°¡à°¿',
  'apply': 'à°µà°°à±à°¤à°¿à°‚à°šà±',
  'referralCodeApplied': 'à°°à°¿à°«à°°à°²à± à°•à±‹à°¡à± à°µà°°à±à°¤à°¿à°‚à°šà°¬à°¡à°¿à°‚à°¦à°¿!',
  'exportFailed': 'à°Žà°—à±à°®à°¤à°¿ à°µà°¿à°«à°²à°®à±ˆà°‚à°¦à°¿',
  'comingSoon': 'à°¤à±à°µà°°à°²à±‹ à°µà°¸à±à°¤à±à°‚à°¦à°¿!',
};
