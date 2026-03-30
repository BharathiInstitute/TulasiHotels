/// Staff messaging model for internal communication
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final bool isBroadcast;
  final String? targetRole;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.isBroadcast = false,
    this.targetRole,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      isBroadcast: (data['isBroadcast'] as bool?) ?? false,
      targetRole: data['targetRole'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'isBroadcast': isBroadcast,
      'targetRole': targetRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  MessageModel copyWith({
    String? content,
    bool? isBroadcast,
    String? targetRole,
    bool? isRead,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content ?? this.content,
      isBroadcast: isBroadcast ?? this.isBroadcast,
      targetRole: targetRole ?? this.targetRole,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
