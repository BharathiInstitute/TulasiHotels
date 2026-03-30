/// Table management service — Firestore CRUD for tables
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/models/table_model.dart';

class TableService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _tablesRef =>
      _firestore.collection('$_basePath/tables');

  /// Stream all tables (real-time)
  static Stream<List<TableModel>> tablesStream() {
    return _tablesRef.orderBy('number').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => TableModel.fromFirestore(doc)).toList(),
    );
  }

  /// Get a single table by ID
  static Future<TableModel?> getTable(String tableId) async {
    final doc = await _tablesRef.doc(tableId).get();
    if (!doc.exists) return null;
    return TableModel.fromFirestore(doc);
  }

  /// Create a new table
  static Future<TableModel> createTable({
    required int number,
    String? label,
    int capacity = 4,
    int floor = 0,
  }) async {
    final id = generateSafeId('table');
    final now = DateTime.now();
    final table = TableModel(
      id: id,
      number: number,
      label: label,
      capacity: capacity,
      floor: floor,
      createdAt: now,
    );

    await _tablesRef.doc(id).set(table.toFirestore());
    debugPrint('✅ Created table: ${table.displayName}');
    return table;
  }

  /// Update an existing table
  static Future<void> updateTable(TableModel table) async {
    await _tablesRef.doc(table.id).update({
      ...table.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a table
  static Future<void> deleteTable(String tableId) async {
    await _tablesRef.doc(tableId).delete();
  }

  /// Update table status (e.g., available → occupied)
  static Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? currentOrderId,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (currentOrderId != null) {
      updates['currentOrderId'] = currentOrderId;
    }
    if (status == TableStatus.available) {
      updates['currentOrderId'] = null;
    }
    await _tablesRef.doc(tableId).update(updates);
  }

  /// Bulk-create tables (e.g., "Add tables 1–20")
  static Future<void> createBulkTables({
    required int from,
    required int to,
    int capacity = 4,
    int floor = 0,
  }) async {
    final batch = _firestore.batch();
    for (var i = from; i <= to; i++) {
      final id = generateSafeId('table');
      final table = TableModel(
        id: id,
        number: i,
        capacity: capacity,
        floor: floor,
        createdAt: DateTime.now(),
      );
      batch.set(_tablesRef.doc(id), table.toFirestore());
    }
    await batch.commit();
    debugPrint('✅ Created ${to - from + 1} tables ($from–$to)');
  }

  /// Assign a server (waiter) to a table
  static Future<void> assignServer(
      String tableId, String staffId, String staffName) async {
    await _tablesRef.doc(tableId).update({
      'assignedServerId': staffId,
      'assignedServerName': staffName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream tables assigned to a specific server
  static Stream<List<TableModel>> serverTablesStream(String staffId) {
    return _tablesRef
        .where('assignedServerId', isEqualTo: staffId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TableModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number)),
        );
  }

  /// Clear server assignment from a table
  static Future<void> clearServerAssignment(String tableId) async {
    await _tablesRef.doc(tableId).update({
      'assignedServerId': null,
      'assignedServerName': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
