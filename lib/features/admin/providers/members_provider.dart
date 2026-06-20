/// Riverpod providers for store member management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/admin/services/member_service.dart';

/// Real-time stream of all store members
final membersStreamProvider =
    StreamProvider.autoDispose<List<StoreMember>>((ref) {
  return MemberService.membersStream();
});

/// Real-time stream of active members only
final activeMembersStreamProvider =
    StreamProvider.autoDispose<List<StoreMember>>((ref) {
  return MemberService.activeMembersStream();
});

/// Filter by role (null = all roles)
final memberRoleFilterProvider = StateProvider<StoreRole?>((ref) => null);

/// Search query for member list
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered member list by role and search
final filteredMembersProvider =
    Provider.autoDispose<AsyncValue<List<StoreMember>>>((ref) {
  final membersAsync = ref.watch(membersStreamProvider);
  final roleFilter = ref.watch(memberRoleFilterProvider);
  final searchQuery = ref.watch(memberSearchQueryProvider).toLowerCase();

  return membersAsync.whenData((members) {
    var filtered = members;

    if (roleFilter != null) {
      filtered = filtered.where((m) => m.role == roleFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (m) =>
                m.displayName.toLowerCase().contains(searchQuery) ||
                m.email.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    return filtered;
  });
});
