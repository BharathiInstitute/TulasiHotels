/// Staff messaging providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/services/message_service.dart';
import 'package:tulasihotels/models/message_model.dart';

/// Stream recent messages
final recentMessagesProvider =
    StreamProvider.autoDispose<List<MessageModel>>((ref) {
  return MessageService.recentMessagesStream();
});

/// Stream announcements
final announcementsProvider =
    StreamProvider.autoDispose<List<MessageModel>>((ref) {
  return MessageService.announcementsStream();
});
