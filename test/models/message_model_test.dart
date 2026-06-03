import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/message_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('MessageModel', () {
    test('constructor defaults', () {
      final m = makeMessage();
      expect(m.isBroadcast, false);
      expect(m.isRead, false);
      expect(m.targetRole, isNull);
    });

    test('copyWith updates content and isRead', () {
      final m = makeMessage();
      final updated = m.copyWith(content: 'Updated', isRead: true);
      expect(updated.content, 'Updated');
      expect(updated.isRead, true);
      expect(updated.id, m.id);
      expect(updated.senderId, m.senderId);
    });

    test('copyWith updates broadcast and targetRole', () {
      final m = makeMessage();
      final updated = m.copyWith(isBroadcast: true, targetRole: 'chef');
      expect(updated.isBroadcast, true);
      expect(updated.targetRole, 'chef');
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeMessage(content: 'Original', isBroadcast: true);
      final updated = m.copyWith();
      expect(updated.content, 'Original');
      expect(updated.isBroadcast, true);
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeMessage(
          isBroadcast: true,
          targetRole: 'waiter',
          isRead: true,
        );
        final map = m.toFirestore();
        expect(map['senderId'], 'user-1');
        expect(map['senderName'], 'Test User');
        expect(map['content'], 'Hello test');
        expect(map['isBroadcast'], true);
        expect(map['targetRole'], 'waiter');
        expect(map['isRead'], true);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeMessage(
          content: 'Meeting at 5pm',
          isBroadcast: true,
          targetRole: 'chef',
          isRead: false,
        );
        await firestore
            .collection('messages')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('messages')
            .doc(original.id)
            .get();
        final restored = MessageModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.senderId, original.senderId);
        expect(restored.content, 'Meeting at 5pm');
        expect(restored.isBroadcast, true);
        expect(restored.targetRole, 'chef');
        expect(restored.isRead, false);
      });
    });
  });
}
