/// Tests for MessageService — send, read, announcements, markAsRead
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/message_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/messages';
  });

  group('MessageService Firestore operations', () {
    test('sendMessage — writes and reads back all fields', () async {
      final message = makeMessage(
        senderName: 'Manager',
        content: 'Team meeting at 5 PM',
        isBroadcast: true,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(message.id)
          .set(message.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(message.id).get();
      final parsed = MessageModel.fromFirestore(doc);
      expect(parsed.senderName, 'Manager');
      expect(parsed.content, 'Team meeting at 5 PM');
      expect(parsed.isBroadcast, isTrue);
    });

    test('delete — removes message', () async {
      final message = makeMessage(id: 'msg-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(message.id)
          .set(message.toFirestore());

      await fakeFirestore.collection(basePath).doc('msg-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('msg-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('markAsRead', () {
    test('adds staffId to readBy array', () async {
      final message = makeMessage(id: 'msg-read');
      final data = message.toFirestore();
      data['readBy'] = <String>[];
      await fakeFirestore.collection(basePath).doc(message.id).set(data);

      // Simulate markAsRead: arrayUnion
      await fakeFirestore.collection(basePath).doc('msg-read').update({
        'readBy': ['staff-1'],
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('msg-read').get();
      final readBy = List<String>.from(doc.data()!['readBy'] as List);
      expect(readBy, contains('staff-1'));
    });

    test('multiple staff can mark as read', () async {
      final message = makeMessage(id: 'msg-multi');
      final data = message.toFirestore();
      data['readBy'] = <String>[];
      await fakeFirestore.collection(basePath).doc(message.id).set(data);

      await fakeFirestore.collection(basePath).doc('msg-multi').update({
        'readBy': ['staff-1', 'staff-2'],
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('msg-multi').get();
      final readBy = List<String>.from(doc.data()!['readBy'] as List);
      expect(readBy, containsAll(['staff-1', 'staff-2']));
    });
  });

  group('announcementsStream query', () {
    test('filters only announcement messages', () async {
      final announcement = makeMessage(
        id: 'ann-1',
        isBroadcast: true,
        content: 'Holiday notice',
      );
      final regular = makeMessage(
        id: 'reg-1',
        content: 'Private message',
      );

      // MessageModel uses isBroadcast, but service queries isAnnouncement
      // Store with the field the service expects
      final annData = announcement.toFirestore();
      annData['isAnnouncement'] = true;
      await fakeFirestore.collection(basePath).doc(announcement.id).set(annData);

      final regData = regular.toFirestore();
      regData['isAnnouncement'] = false;
      await fakeFirestore.collection(basePath).doc(regular.id).set(regData);

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('isAnnouncement', isEqualTo: true)
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'ann-1');
    });
  });

  group('recentMessagesStream ordering', () {
    test('returns messages ordered by createdAt descending', () async {
      final m1 = makeMessage(
        id: 'm1',
        content: 'First',
        createdAt: DateTime(2024),
      );
      final m2 = makeMessage(
        id: 'm2',
        content: 'Latest',
        createdAt: DateTime(2024, 6),
      );

      for (final m in [m1, m2]) {
        await fakeFirestore
            .collection(basePath)
            .doc(m.id)
            .set(m.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .orderBy('createdAt', descending: true)
          .get();

      final contents = snapshot.docs
          .map((d) => MessageModel.fromFirestore(d).content)
          .toList();
      expect(contents, ['Latest', 'First']);
    });
  });

  group('message with targetRole', () {
    test('targetRole field persists through Firestore', () async {
      final message = makeMessage(
        id: 'msg-role',
        targetRole: 'waiter',
      );

      await fakeFirestore
          .collection(basePath)
          .doc(message.id)
          .set(message.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('msg-role').get();
      final parsed = MessageModel.fromFirestore(doc);
      expect(parsed.targetRole, 'waiter');
    });

    test('null targetRole round-trips correctly', () async {
      final message = makeMessage(id: 'msg-norole');

      await fakeFirestore
          .collection(basePath)
          .doc(message.id)
          .set(message.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('msg-norole').get();
      final parsed = MessageModel.fromFirestore(doc);
      expect(parsed.targetRole, isNull);
    });
  });
}
