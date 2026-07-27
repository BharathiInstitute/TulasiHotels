/// Staff messaging / announcement service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/message_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class MessageService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('$_basePath/messages');

  /// Stream recent messages (last 50)
  static Stream<List<MessageModel>> recentMessagesStream() {
    return _messagesRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream announcements only
  static Stream<List<MessageModel>> announcementsStream() {
    return _messagesRef
        .where('isAnnouncement', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Send a message
  static Future<void> sendMessage(MessageModel message) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.staff,
      PermissionAction.create,
    );
    await _messagesRef.doc(message.id).set(message.toFirestore());
  }

  /// Delete a message
  static Future<void> deleteMessage(String messageId) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.staff,
      PermissionAction.delete,
    );
    await _messagesRef.doc(messageId).delete();
  }

  /// Mark message as read
  static Future<void> markAsRead(String messageId, String staffId) async {
    await ModuleMutationGuard.requireAnyAction([
      const ModuleActionRequirement(
        route: AppRoutes.staff,
        action: PermissionAction.view,
      ),
      const ModuleActionRequirement(
        route: AppRoutes.staff,
        action: PermissionAction.update,
      ),
    ]);
    await _messagesRef.doc(messageId).update({
      'readBy': FieldValue.arrayUnion([staffId]),
    });
  }
}
