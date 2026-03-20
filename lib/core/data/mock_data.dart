/// Mock data generator for testing without Firebase
/// Generates 100 items each for products, customers, bills, and transactions
library;

import 'dart:math';
import 'package:tulasihotels/models/product_model.dart';
import 'package:tulasihotels/models/customer_model.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/transaction_model.dart';

class MockData {
  MockData._();

  static final Random _random = Random(42); // Fixed seed for consistent data

  // ============ PRODUCT DATA ============
  static final List<ProductModel> products = _generateProducts();

  static List<ProductModel> _generateProducts() {
    final List<ProductModel> result = [];
    int id = 1;

    // Groceries (30 items)
    final groceries = [
      ('Tata Salt 1kg', 28, 24, ProductUnit.piece),
      ('Aashirvaad Atta 5kg', 285, 260, ProductUnit.piece),
      ('Aashirvaad Atta 10kg', 520, 480, ProductUnit.piece),
      ('Fortune Sunflower Oil 1L', 145, 130, ProductUnit.liter),
      ('Fortune Sunflower Oil 5L', 680, 620, ProductUnit.liter),
      ('Saffola Gold Oil 1L', 185, 165, ProductUnit.liter),
      ('India Gate Basmati Rice 1kg', 95, 85, ProductUnit.kg),
      ('India Gate Basmati Rice 5kg', 450, 410, ProductUnit.kg),
      ('Toor Dal 1kg', 145, 130, ProductUnit.kg),
      ('Chana Dal 1kg', 95, 85, ProductUnit.kg),
      ('Moong Dal 1kg', 125, 110, ProductUnit.kg),
      ('Urad Dal 1kg', 135, 120, ProductUnit.kg),
      ('Sugar 1kg', 48, 42, ProductUnit.kg),
      ('Sugar 5kg', 225, 200, ProductUnit.kg),
      ('MDH Garam Masala 50g', 65, 55, ProductUnit.piece),
      ('MDH Chana Masala 100g', 55, 45, ProductUnit.piece),
      ('Everest Turmeric 100g', 35, 28, ProductUnit.piece),
      ('Everest Red Chilli 100g', 45, 38, ProductUnit.piece),
      ('Catch Black Pepper 50g', 85, 75, ProductUnit.piece),
      ('Saffron 1g', 150, 130, ProductUnit.gram),
      ('Rajma 1kg', 145, 125, ProductUnit.kg),
      ('Chole 1kg', 95, 80, ProductUnit.kg),
      ('Poha 500g', 35, 28, ProductUnit.piece),
      ('Suji 500g', 32, 26, ProductUnit.piece),
      ('Besan 500g', 55, 45, ProductUnit.piece),
      ('Maida 1kg', 42, 35, ProductUnit.kg),
      ('Coconut Oil 500ml', 125, 110, ProductUnit.ml),
      ('Ghee 500g', 285, 255, ProductUnit.piece),
      ('Ghee 1kg', 545, 495, ProductUnit.kg),
      ('Vinegar 500ml', 45, 38, ProductUnit.ml),
    ];

    for (final item in groceries) {
      result.add(
        ProductModel(
          id: '${id++}',
          name: item.$1,
          price: item.$2.toDouble(),
          purchasePrice: item.$3.toDouble(),
          stock: _random.nextInt(50) + 5,
          lowStockAlert: 5,
          unit: item.$4,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(60)),
          ),
        ),
      );
    }

    // Dairy (15 items)
    final dairy = [
      ('Amul Butter 100g', 58, 52, ProductUnit.piece),
      ('Amul Butter 500g', 275, 255, ProductUnit.piece),
      ('Amul Cheese Slice 10s', 145, 130, ProductUnit.piece),
      ('Amul Cheese Block 200g', 95, 85, ProductUnit.piece),
      ('Mother Dairy Paneer 200g', 85, 75, ProductUnit.piece),
      ('Mother Dairy Paneer 500g', 195, 175, ProductUnit.piece),
      ('Amul Milk 500ml', 30, 27, ProductUnit.ml),
      ('Amul Milk 1L', 58, 54, ProductUnit.liter),
      ('Amul Curd 400g', 35, 30, ProductUnit.piece),
      ('Amul Lassi 200ml', 25, 22, ProductUnit.ml),
      ('Nandini Curd 500g', 32, 28, ProductUnit.piece),
      ('Britannia Cream 200ml', 45, 40, ProductUnit.ml),
      ('Nestle Milkmaid 400g', 145, 130, ProductUnit.piece),
      ('Amul Ice Cream 500ml', 125, 110, ProductUnit.ml),
      ('Mother Dairy Dahi 1kg', 65, 58, ProductUnit.kg),
    ];

    for (final item in dairy) {
      result.add(
        ProductModel(
          id: '${id++}',
          name: item.$1,
          price: item.$2.toDouble(),
          purchasePrice: item.$3.toDouble(),
          stock: _random.nextInt(30) + 3,
          lowStockAlert: 5,
          unit: item.$4,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(60)),
          ),
        ),
      );
    }

    // Snacks (20 items)
    final snacks = [
      ('Parle-G Biscuits', 10, 8, ProductUnit.pack),
      ('Parle-G Family Pack', 45, 40, ProductUnit.pack),
      ('Britannia Good Day', 35, 30, ProductUnit.pack),
      ('Britannia Marie Gold', 30, 26, ProductUnit.pack),
      ('Oreo Biscuits', 35, 30, ProductUnit.pack),
      ('Hide & Seek', 40, 35, ProductUnit.pack),
      ('Dark Fantasy', 45, 40, ProductUnit.pack),
      ('Lays Classic 52g', 20, 17, ProductUnit.pack),
      ('Lays Magic Masala 52g', 20, 17, ProductUnit.pack),
      ('Kurkure 75g', 20, 17, ProductUnit.pack),
      ('Bingo Mad Angles', 20, 17, ProductUnit.pack),
      ('Haldirams Bhujia 200g', 65, 55, ProductUnit.piece),
      ('Haldirams Mixture 200g', 55, 45, ProductUnit.piece),
      ('Haldirams Aloo Bhujia 400g', 95, 80, ProductUnit.piece),
      ('Dairy Milk 25g', 25, 22, ProductUnit.piece),
      ('Dairy Milk Silk', 85, 75, ProductUnit.piece),
      ('5 Star 22g', 20, 17, ProductUnit.piece),
      ('KitKat 2 Finger', 20, 17, ProductUnit.piece),
      ('Munch 23g', 10, 8, ProductUnit.piece),
      ('Perk 15g', 10, 8, ProductUnit.piece),
    ];

    for (final item in snacks) {
      result.add(
        ProductModel(
          id: '${id++}',
          name: item.$1,
          price: item.$2.toDouble(),
          purchasePrice: item.$3.toDouble(),
          stock: _random.nextInt(100) + 10,
          lowStockAlert: 15,
          unit: item.$4,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(60)),
          ),
        ),
      );
    }

    // Beverages (15 items)
    final beverages = [
      ('Tata Tea Gold 250g', 125, 110, ProductUnit.piece),
      ('Tata Tea Premium 500g', 195, 175, ProductUnit.piece),
      ('Red Label Tea 250g', 145, 130, ProductUnit.piece),
      ('Nescafe Classic 50g', 175, 155, ProductUnit.piece),
      ('Bru Instant Coffee 50g', 145, 125, ProductUnit.piece),
      ('Coca Cola 750ml', 40, 35, ProductUnit.ml),
      ('Coca Cola 2L', 85, 75, ProductUnit.liter),
      ('Pepsi 750ml', 40, 35, ProductUnit.ml),
      ('Sprite 750ml', 40, 35, ProductUnit.ml),
      ('Thums Up 750ml', 40, 35, ProductUnit.ml),
      ('Maaza 600ml', 35, 30, ProductUnit.ml),
      ('Frooti 200ml', 15, 12, ProductUnit.ml),
      ('Real Fruit Juice 1L', 99, 85, ProductUnit.liter),
      ('Tropicana Orange 1L', 110, 95, ProductUnit.liter),
      ('Bisleri Water 1L', 20, 15, ProductUnit.liter),
    ];

    for (final item in beverages) {
      result.add(
        ProductModel(
          id: '${id++}',
          name: item.$1,
          price: item.$2.toDouble(),
          purchasePrice: item.$3.toDouble(),
          stock: _random.nextInt(50) + 5,
          lowStockAlert: 10,
          unit: item.$4,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(60)),
          ),
        ),
      );
    }

    // Personal Care (10 items)
    final personalCare = [
      ('Dove Soap 100g', 55, 48, ProductUnit.piece),
      ('Lux Soap 100g', 42, 36, ProductUnit.piece),
      ('Lifebuoy Soap 100g', 35, 30, ProductUnit.piece),
      ('Dettol Soap 125g', 48, 42, ProductUnit.piece),
      ('Head & Shoulders 180ml', 195, 170, ProductUnit.ml),
      ('Dove Shampoo 180ml', 185, 165, ProductUnit.ml),
      ('Clinic Plus 175ml', 95, 82, ProductUnit.ml),
      ('Colgate Strong Teeth 100g', 55, 48, ProductUnit.piece),
      ('Pepsodent 150g', 75, 65, ProductUnit.piece),
      ('Close Up 80g', 58, 50, ProductUnit.piece),
    ];

    for (final item in personalCare) {
      result.add(
        ProductModel(
          id: '${id++}',
          name: item.$1,
          price: item.$2.toDouble(),
          purchasePrice: item.$3.toDouble(),
          stock: _random.nextInt(40) + 5,
          lowStockAlert: 5,
          unit: item.$4,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(60)),
          ),
        ),
      );
    }

    // Household (10 items)
    final household = [
      ('Surf Excel 1kg', 195, 175, ProductUnit.kg),
      ('Surf Excel 500g', 110, 95, ProductUnit.piece),
      ('Tide 1kg', 155, 135, ProductUnit.kg),
      ('Rin Bar 250g', 25, 21, ProductUnit.piece),
      ('Vim Bar 200g', 25, 21, ProductUnit.piece),
      ('Vim Liquid 500ml', 95, 82, ProductUnit.ml),
      ('Harpic 500ml', 95, 82, ProductUnit.ml),
      ('Lizol 500ml', 145, 125, ProductUnit.ml),
      ('Colin Glass Cleaner', 85, 72, ProductUnit.piece),
      ('Good Knight Refill', 65, 55, ProductUnit.piece),
    ];

    for (final item in household) {
      result.add(
        ProductModel(
          id: '${id++}',
          name: item.$1,
          price: item.$2.toDouble(),
          purchasePrice: item.$3.toDouble(),
          stock: _random.nextInt(30) + 5,
          lowStockAlert: 5,
          unit: item.$4,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(60)),
          ),
        ),
      );
    }

    // Add some out of stock and low stock items
    for (int i = 0; i < 5; i++) {
      result[_random.nextInt(result.length)] =
          result[_random.nextInt(result.length)].copyWith(stock: 0);
    }
    for (int i = 0; i < 10; i++) {
      final idx = _random.nextInt(result.length);
      if (result[idx].stock > 5) {
        result[idx] = result[idx].copyWith(stock: _random.nextInt(4) + 1);
      }
    }

    return result;
  }

  // ============ CUSTOMER DATA ============
  static final List<CustomerModel> customers = _generateCustomers();

  static List<CustomerModel> _generateCustomers() {
    final List<CustomerModel> result = [];

    // Hindi names (60)
    final hindiNames = [
      'à¤°à¤¾à¤œà¥‡à¤¶ à¤•à¥à¤®à¤¾à¤°',
      'à¤¸à¥à¤¨à¥€à¤¤à¤¾ à¤¦à¥‡à¤µà¥€',
      'à¤®à¥‹à¤¹à¤¨ à¤²à¤¾à¤²',
      'à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤¶à¤°à¥à¤®à¤¾',
      'à¤…à¤®à¤¿à¤¤ à¤¸à¤¿à¤‚à¤¹',
      'à¤°à¥‡à¤–à¤¾ à¤¯à¤¾à¤¦à¤µ',
      'à¤µà¤¿à¤œà¤¯ à¤µà¤°à¥à¤®à¤¾',
      'à¤…à¤¨à¥€à¤¤à¤¾ à¤—à¥à¤ªà¥à¤¤à¤¾',
      'à¤¸à¥à¤°à¥‡à¤¶ à¤šà¥Œà¤§à¤°à¥€',
      'à¤•à¤µà¤¿à¤¤à¤¾ à¤œà¥ˆà¤¨',
      'à¤°à¤¾à¤¹à¥à¤² à¤®à¤¿à¤¶à¥à¤°à¤¾',
      'à¤ªà¥‚à¤œà¤¾ à¤ªà¤¾à¤‚à¤¡à¥‡',
      'à¤¦à¥€à¤ªà¤• à¤…à¤—à¥à¤°à¤µà¤¾à¤²',
      'à¤¸à¥€à¤®à¤¾ à¤¸à¤•à¥à¤¸à¥‡à¤¨à¤¾',
      'à¤®à¤¨à¥‹à¤œ à¤¤à¤¿à¤µà¤¾à¤°à¥€',
      'à¤®à¤®à¤¤à¤¾ à¤à¤¾',
      'à¤¸à¤‚à¤œà¤¯ à¤¦à¥à¤¬à¥‡',
      'à¤—à¥€à¤¤à¤¾ à¤°à¤¾à¤œà¤ªà¥‚à¤¤',
      'à¤…à¤¶à¥‹à¤• à¤®à¥‡à¤¹à¤¤à¤¾',
      'à¤¨à¤¿à¤§à¤¿ à¤–à¤¨à¥à¤¨à¤¾',
      'à¤µà¤¿à¤•à¤¾à¤¸ à¤¤à¥à¤°à¤¿à¤ªà¤¾à¤ à¥€',
      'à¤¸à¥à¤µà¤¾à¤¤à¤¿ à¤¬à¤¾à¤œà¤ªà¥‡à¤¯à¥€',
      'à¤°à¤¾à¤œ à¤ªà¤Ÿà¥‡à¤²',
      'à¤œà¥à¤¯à¥‹à¤¤à¤¿ à¤®à¤¾à¤¥à¥à¤°',
      'à¤…à¤°à¥à¤œà¥à¤¨ à¤°à¤¾à¤ à¥Œà¤°',
      'à¤¶à¤¿à¤–à¤¾ à¤­à¤¾à¤°à¤¦à¥à¤µà¤¾à¤œ',
      'à¤ªà¥à¤°à¤®à¥‹à¤¦ à¤¨à¥‡à¤—à¥€',
      'à¤°à¥€à¤¨à¤¾ à¤•à¤ªà¥‚à¤°',
      'à¤¸à¥à¤§à¥€à¤° à¤°à¤¾à¤µà¤¤',
      'à¤®à¥€à¤¨à¤¾à¤•à¥à¤·à¥€ à¤¶à¥à¤•à¥à¤²à¤¾',
      'à¤¨à¤°à¥‡à¤¶ à¤œà¥‹à¤¶à¥€',
      'à¤°à¥‚à¤ªà¤¾ à¤šà¤¤à¥à¤°à¥à¤µà¥‡à¤¦à¥€',
      'à¤—à¥‹à¤µà¤¿à¤‚à¤¦ à¤¶à¥à¤°à¥€à¤µà¤¾à¤¸à¥à¤¤à¤µ',
      'à¤•à¤‚à¤šà¤¨ à¤µà¤¾à¤œà¤ªà¥‡à¤¯à¥€',
      'à¤‰à¤®à¥‡à¤¶ à¤¦à¥€à¤•à¥à¤·à¤¿à¤¤',
      'à¤†à¤°à¤¤à¥€ à¤¦à¥à¤µà¤¿à¤µà¥‡à¤¦à¥€',
      'à¤¹à¥‡à¤®à¤‚à¤¤ à¤ªà¤¾à¤ à¤•',
      'à¤¸à¤µà¤¿à¤¤à¤¾ à¤—à¥Œà¤¡à¤¼',
      'à¤ªà¤µà¤¨ à¤®à¤¾à¤²à¤µà¥€à¤¯',
      'à¤µà¤‚à¤¦à¤¨à¤¾ à¤šà¥Œà¤¬à¥‡',
      'à¤…à¤¨à¥à¤œ à¤¸à¥‹à¤¨à¥€',
      'à¤¨à¤¿à¤¶à¤¾ à¤°à¤œà¤ªà¥‚à¤¤',
      'à¤•à¤®à¤² à¤•à¤¿à¤¶à¥‹à¤°',
      'à¤°à¤šà¤¨à¤¾ à¤¸à¥‡à¤ à¥€',
      'à¤¹à¤°à¥€à¤¶ à¤šà¤‚à¤¦à¥à¤°',
      'à¤†à¤¶à¤¾ à¤•à¥Œà¤¶à¤¿à¤•',
      'à¤®à¥‹à¤¹à¤¿à¤¤ à¤°à¤¸à¥à¤¤à¥‹à¤—à¥€',
      'à¤µà¤°à¥à¤·à¤¾ à¤œà¤¾à¤¯à¤¸à¤µà¤¾à¤²',
      'à¤…à¤–à¤¿à¤² à¤¶à¥à¤°à¥€à¤§à¤°',
      'à¤®à¤¾à¤§à¤µà¥€ à¤¬à¤‚à¤¸à¤²',
      'à¤¯à¥‹à¤—à¥‡à¤¶ à¤•à¥à¤²à¤•à¤°à¥à¤£à¥€',
      'à¤ªà¥à¤°à¤­à¤¾ à¤¦à¥‡à¤¶à¤®à¥à¤–',
      'à¤…à¤•à¥à¤·à¤¯ à¤ªà¤¾à¤Ÿà¤¿à¤²',
      'à¤šà¤¿à¤¤à¥à¤°à¤¾ à¤œà¤¾à¤§à¤µ',
      'à¤¸à¤‚à¤¤à¥‹à¤· à¤¸à¤¾à¤ à¥‡',
      'à¤µà¥ˆà¤¶à¤¾à¤²à¥€ à¤—à¥‹à¤–à¤²à¥‡',
      'à¤®à¤¹à¥‡à¤¶ à¤²à¥‹à¤–à¤‚à¤¡à¥‡',
      'à¤…à¤‚à¤œà¤²à¤¿ à¤•à¥à¤²à¤¶à¥à¤°à¥‡à¤·à¥à¤ ',
      'à¤§à¥€à¤°à¤œ à¤¦à¤°à¥à¤µà¤¾',
      'à¤¸à¥‹à¤¨à¤¾à¤²à¥€ à¤•à¤°à¤•à¥‡',
    ];

    // Telugu names (20)
    final teluguNames = [
      'à°µà±†à°‚à°•à°Ÿ à°°à°¾à°µà±',
      'à°²à°•à±à°·à±à°®à°¿ à°¦à±‡à°µà°¿',
      'à°¸à±à°°à±‡à°·à± à°°à±†à°¡à±à°¡à°¿',
      'à°ªà°¦à±à°® à°¨à°¾à°¯à±à°¡à±',
      'à°°à°¾à°œà±‡à°·à± à°•à±à°®à°¾à°°à±',
      'à°…à°¨à±à°ªà°® à°¶à°°à±à°®',
      'à°ªà±à°°à°¸à°¾à°¦à± à°µà°°à±à°®',
      'à°®à°‚à°œà±à°² à°šà±Œà°¦à°°à°¿',
      'à°•à±ƒà°·à±à°£ à°®à±‚à°°à±à°¤à°¿',
      'à°¸à±à°¨à±€à°¤ à°°à°¾à°œà±',
      'à°—à°£à±‡à°·à± à°—à±Œà°¡à±',
      'à°°à°®à°¾ à°¦à±‡à°µà°¿',
      'à°¶à±à°°à±€à°¨à°¿à°µà°¾à°¸à± à°°à°¾à°µà±',
      'à°•à°®à°² à°¨à°¾à°¯à°•à±',
      'à°¨à°°à°¸à°¿à°‚à°¹ à°¶à±†à°Ÿà±à°Ÿà°¿',
      'à°ªà°µà°¨à± à°•à°³à±à°¯à°¾à°£à±',
      'à°…à°¨à±à°·à±à°• à°¨à°¾à°¯à°•à±',
      'à°ªà±à°°à°•à°¾à°·à± à°°à±†à°¡à±à°¡à°¿',
      'à°¦à±€à°ªà±à°¤à°¿ à°¶à°°à±à°®',
      'à°šà°‚à°¦à±à°° à°¶à±‡à°–à°°à±',
    ];

    // English names (20)
    final englishNames = [
      'John Thomas',
      'Mary Joseph',
      'David George',
      'Sarah Williams',
      'Michael James',
      'Jennifer Peter',
      'Robert Paul',
      'Elizabeth John',
      'William David',
      'Patricia Mary',
      'Christopher Thomas',
      'Linda Joseph',
      'Daniel George',
      'Barbara Williams',
      'Matthew James',
      'Susan Peter',
      'Anthony Paul',
      'Jessica John',
      'Mark David',
      'Nancy Mary',
    ];

    int id = 1;

    // Add Hindi customers
    for (final name in hindiNames) {
      final balance = _getRandomBalance();
      result.add(
        CustomerModel(
          id: '${id++}',
          name: name,
          phone: '98${_random.nextInt(100000000).toString().padLeft(8, '0')}',
          balance: balance,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(90) + 1),
          ),
          lastTransactionAt: balance != 0
              ? DateTime.now().subtract(Duration(days: _random.nextInt(30)))
              : null,
        ),
      );
    }

    // Add Telugu customers
    for (final name in teluguNames) {
      final balance = _getRandomBalance();
      result.add(
        CustomerModel(
          id: '${id++}',
          name: name,
          phone: '96${_random.nextInt(100000000).toString().padLeft(8, '0')}',
          balance: balance,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(90) + 1),
          ),
          lastTransactionAt: balance != 0
              ? DateTime.now().subtract(Duration(days: _random.nextInt(30)))
              : null,
        ),
      );
    }

    // Add English customers
    for (final name in englishNames) {
      final balance = _getRandomBalance();
      result.add(
        CustomerModel(
          id: '${id++}',
          name: name,
          phone: '97${_random.nextInt(100000000).toString().padLeft(8, '0')}',
          balance: balance,
          createdAt: DateTime.now().subtract(
            Duration(days: _random.nextInt(90) + 1),
          ),
          lastTransactionAt: balance != 0
              ? DateTime.now().subtract(Duration(days: _random.nextInt(30)))
              : null,
        ),
      );
    }

    return result;
  }

  static double _getRandomBalance() {
    // All customers start with 0 balance for clean demo
    // Udhar bills will add to this balance
    return 0;
  }

  // ============ BILLS DATA ============
  static final List<BillModel> bills = _generateBills();

  static List<BillModel> _generateBills() {
    final List<BillModel> result = [];

    for (int i = 0; i < 100; i++) {
      final daysAgo = _random.nextInt(30);
      final date = DateTime.now().subtract(Duration(days: daysAgo));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Random items (1-5)
      final itemCount = _random.nextInt(5) + 1;
      final List<CartItem> items = [];
      double total = 0;

      for (int j = 0; j < itemCount; j++) {
        final product = products[_random.nextInt(products.length)];
        final qty = _random.nextInt(3) + 1;
        final itemTotal = product.price * qty;
        total += itemTotal;

        items.add(
          CartItem(
            productId: product.id,
            name: product.name,
            price: product.price,
            quantity: qty,
            unit: product.unit.shortName,
          ),
        );
      }

      // Payment method distribution: Cash 50%, UPI 35%, Udhar 15%
      final methodRandom = _random.nextInt(100);
      PaymentMethod paymentMethod;
      String? customerId;
      String? customerName;

      if (methodRandom < 50) {
        paymentMethod = PaymentMethod.cash;
      } else if (methodRandom < 85) {
        paymentMethod = PaymentMethod.upi;
      } else {
        paymentMethod = PaymentMethod.udhar;
        final customer = customers[_random.nextInt(customers.length)];
        customerId = customer.id;
        customerName = customer.name;
      }

      result.add(
        BillModel(
          id: 'bill_${i + 1}',
          billNumber: i + 1,
          items: items,
          total: total,
          paymentMethod: paymentMethod,
          customerId: customerId,
          customerName: customerName,
          receivedAmount: paymentMethod != PaymentMethod.udhar ? total : null,
          createdAt: date,
          date: dateStr,
        ),
      );
    }

    return result;
  }

  // ============ TRANSACTIONS DATA ============
  static final List<TransactionModel> transactions = _generateTransactions();

  static List<TransactionModel> _generateTransactions() {
    final List<TransactionModel> result = [];

    for (int i = 0; i < 100; i++) {
      final daysAgo = _random.nextInt(60);
      final date = DateTime.now().subtract(Duration(days: daysAgo));
      final customer = customers[_random.nextInt(customers.length)];

      // 60% purchases, 40% payments
      final isPurchase = _random.nextInt(100) < 60;

      if (isPurchase) {
        // Purchase (credit given)
        final amount = (_random.nextInt(20) + 1) * 100.0; // 100 to 2000
        result.add(
          TransactionModel(
            id: 'txn_${i + 1}',
            customerId: customer.id,
            type: TransactionType.purchase,
            amount: amount,
            billId: 'bill_${_random.nextInt(100) + 1}',
            createdAt: date,
          ),
        );
      } else {
        // Payment received
        final amount = (_random.nextInt(15) + 1) * 100.0; // 100 to 1500
        final paymentMode = _random.nextInt(100) < 60 ? 'cash' : 'upi';
        result.add(
          TransactionModel(
            id: 'txn_${i + 1}',
            customerId: customer.id,
            type: TransactionType.payment,
            amount: amount,
            note: paymentMode == 'upi' ? 'UPI payment received' : null,
            paymentMode: paymentMode,
            createdAt: date,
          ),
        );
      }
    }

    return result;
  }
}
