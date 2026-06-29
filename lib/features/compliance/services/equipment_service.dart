/// Equipment and maintenance tracking service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/equipment_model.dart';

class EquipmentService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _equipmentRef =>
      _firestore.collection('$_basePath/equipment');

  /// Stream all equipment
  static Stream<List<EquipmentModel>> equipmentStream() {
    return _equipmentRef.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => EquipmentModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream equipment needing service (next service date approaching)
  static Stream<List<EquipmentModel>> needsServiceStream() {
    final thirtyDaysFromNow =
        DateTime.now().add(const Duration(days: 30));

    return _equipmentRef
        .where('nextServiceDate',
            isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EquipmentModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create equipment
  static Future<void> createEquipment(EquipmentModel equipment) async {
    await _equipmentRef.doc(equipment.id).set(equipment.toFirestore());
  }

  /// Update equipment
  static Future<void> updateEquipment(EquipmentModel equipment) async {
    await _equipmentRef.doc(equipment.id).update(equipment.toFirestore());
  }

  /// Add a service record to equipment
  static Future<void> addServiceRecord(
      String equipmentId, ServiceRecord record) async {
    await _equipmentRef.doc(equipmentId).update({
      'serviceHistory': FieldValue.arrayUnion([record.toMap()]),
      'lastServiceDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete equipment
  static Future<void> deleteEquipment(String equipmentId) async {
    await _equipmentRef.doc(equipmentId).delete();
  }
}
