/// Users List Screen for Super Admin
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/super_admin/screens/admin_shell_screen.dart';
import 'package:tulasihotels/features/super_admin/models/admin_user_model.dart';
import 'package:tulasihotels/features/super_admin/providers/super_admin_provider.dart';
import 'package:tulasihotels/features/super_admin/services/admin_firestore_service.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  static const int _pageSize = 25;

  final TextEditingController _searchController = TextEditingController();

  List<AdminUser> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  // Track which filters are currently loaded
  String _loadedSearch = '';
  SubscriptionPlan? _loadedPlan;

  // Emails with multiple restaurants that are expanded
  final Set<String> _expandedEmails = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoadingMore && !reset) return;

    if (reset) {
      setState(() {
        _users = [];
        _lastDoc = null;
        _hasMore = true;
        _isInitialLoading = true;
        _error = null;
      });
    }

    final searchQuery = ref.read(usersSearchQueryProvider);
    final planFilter = ref.read(usersPlanFilterProvider);
    setState(() {
      _loadedSearch = searchQuery;
      _loadedPlan = planFilter;
      if (!reset) _isLoadingMore = true;
    });

    try {
      final page = await AdminFirestoreService.getAllUsers(
        limit: _pageSize,
        startAfter: reset ? null : _lastDoc,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
        planFilter: planFilter,
      );

      // getAllUsers returns a list but doesn't expose the last doc snapshot.
      // We need to fetch that separately via a raw query — grab it from the
      // service's raw snapshot by re-querying with the same params.
      DocumentSnapshot? newLastDoc;
      if (page.isNotEmpty) {
        // Re-query to get the raw DocumentSnapshot for cursor
        Query q = FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true);
        if (planFilter != null) {
          q = q.where('subscription.plan', isEqualTo: planFilter.name);
        }
        if (_lastDoc != null && !reset) q = q.startAfterDocument(_lastDoc!);
        q = q.limit(_pageSize);
        final raw = await q.get();
        if (raw.docs.isNotEmpty) {
          newLastDoc = raw.docs.last;
        }
      }

      if (!mounted) return;
      setState(() {
        if (reset) {
          _users = page;
        } else {
          _users = [..._users, ...page];
        }
        _lastDoc = newLastDoc;
        _hasMore = page.length == _pageSize;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onFiltersChanged() {
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(usersSearchQueryProvider);
    final planFilter = ref.watch(usersPlanFilterProvider);
    final isWide = MediaQuery.of(context).size.width >= 1024;

    // Reset when filters change
    if (searchQuery != _loadedSearch || planFilter != _loadedPlan) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onFiltersChanged());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('All Users (${_users.length}${_hasMore ? '+' : ''})'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    adminShellScaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                        .read(usersSearchQueryProvider.notifier)
                                        .state =
                                    '';
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      ref.read(usersSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<SubscriptionPlan?>(
                    value: planFilter,
                    hint: const Text('All Plans'),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(child: Text('All Plans')),
                      ...adminPlanCatalog.map(
                        (plan) => DropdownMenuItem(
                          value: plan,
                          child: Text(
                            plan.name[0].toUpperCase() + plan.name.substring(1),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(usersPlanFilterProvider.notifier).state = value;
                    },
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty || planFilter != null
                              ? 'No users match your filters'
                              : 'No users found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : isWide
                ? _buildDataTable()
                : _buildUsersList(),
          ),

          // Load More footer
          if (!_isInitialLoading && _users.isNotEmpty) _buildLoadMoreFooter(),
        ],
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.expand_more),
            label: Text('Load More (${_users.length} loaded)'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          'All ${_users.length} users loaded',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }

  // Max active stores per plan: business=3, everything else=1.
  int _planActiveLimit(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.business ? 3 : 1;

  // ── Email-level admin actions ─────────────────────────────────────────────

  void _showChangeSubscriptionForEmail(
    BuildContext context,
    String email,
    List<AdminUser> users,
  ) {
    final effective = _effectivePlan(users);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Change Subscription\n$email'),
        titleTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current plan: ${effective.name.toUpperCase()}  •  ${users.length} restaurant(s)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            ...adminPlanCatalog.map(
              (plan) => ListTile(
                dense: true,
                title: Text(plan.name.toUpperCase()),
                trailing: effective == plan
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(dialogCtx);
                  final newLimit = _planActiveLimit(plan);
                  final activeUsers = users.where((u) => u.isStoreActive).toList();
                  if (activeUsers.length > newLimit) {
                    // Must pick which store(s) to keep active
                    if (context.mounted) {
                      _showSelectActiveStoreDialog(context, email, users, plan, newLimit);
                    }
                  } else {
                    final sub = UserSubscription(
                      plan: plan,
                      startedAt: DateTime.now(),
                      expiresAt: plan == SubscriptionPlan.free
                          ? null
                          : DateTime.now().add(const Duration(days: 30)),
                    );
                    final count = await AdminFirestoreService.updateSubscriptionByEmail(email, sub);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Updated $count restaurant(s) to ${plan.name.toUpperCase()}'),
                        backgroundColor: Colors.green,
                      ));
                      _load(reset: true);
                    }
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  /// Step 2: after a downgrade, pick which store(s) to keep active — rest are suspended.
  void _showSelectActiveStoreDialog(
    BuildContext context,
    String email,
    List<AdminUser> users,
    SubscriptionPlan newPlan,
    int keepCount,
  ) {
    final activeUsers = users.where((u) => u.isStoreActive).toList();
    // Pre-select the most-recently-active store(s)
    final sortedActive = activeUsers.toList()
      ..sort((a, b) {
        final ta = a.activity.lastActiveAt?.millisecondsSinceEpoch ?? 0;
        final tb = b.activity.lastActiveAt?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });
    final preSelected = sortedActive.take(keepCount).map((u) => u.id).toSet();
    final selected = ValueNotifier<Set<String>>(preSelected);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Downgrade — Select Active Store', style: TextStyle(fontSize: 15))),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      '${newPlan.name.toUpperCase()} plan allows only $keepCount active store(s). '
                      'Choose which to keep active — the rest will be suspended and '
                      'cannot be activated until the plan is upgraded to Business.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...users.map((u) {
                    final isSelected = selected.value.contains(u.id);
                    final isCurrentlyActive = u.isStoreActive;
                    return CheckboxListTile(
                      dense: true,
                      title: Text(u.shopName.isNotEmpty ? u.shopName : 'Unknown Shop'),
                      subtitle: Text(u.ownerName, style: const TextStyle(fontSize: 11)),
                      value: isSelected,
                      enabled: isCurrentlyActive, // only active stores can be chosen
                      secondary: isCurrentlyActive
                          ? null
                          : const Icon(Icons.block, size: 16, color: Colors.grey),
                      onChanged: isCurrentlyActive
                          ? (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  if (selected.value.length < keepCount) {
                                    selected.value = {...selected.value, u.id};
                                  }
                                } else {
                                  selected.value = {...selected.value}..remove(u.id);
                                }
                              });
                            }
                          : null,
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ValueListenableBuilder<Set<String>>(
                valueListenable: selected,
                builder: (_, sel, __) => ElevatedButton(
                  onPressed: sel.length == keepCount
                      ? () async {
                          Navigator.pop(ctx);
                          // Update subscription for all stores
                          final sub = UserSubscription(
                            plan: newPlan,
                            startedAt: DateTime.now(),
                            expiresAt: newPlan == SubscriptionPlan.free
                                ? null
                                : DateTime.now().add(const Duration(days: 30)),
                          );
                          await AdminFirestoreService.updateSubscriptionByEmail(email, sub);
                          // Suspend the non-selected active stores
                          for (final u in users) {
                            if (u.isStoreActive && !sel.contains(u.id)) {
                              await AdminFirestoreService.setStoreStatus(u.id, 'suspended');
                            }
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                'Downgraded to ${newPlan.name.toUpperCase()}. '
                                '${users.where((u) => u.isStoreActive && !sel.contains(u.id)).length} store(s) suspended.',
                              ),
                              backgroundColor: Colors.orange,
                            ));
                            _load(reset: true);
                          }
                        }
                      : null,
                  child: Text('Confirm (${ sel.length}/$keepCount selected)'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmResetLimitsForEmail(
    BuildContext context,
    String email,
    List<AdminUser> users,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Monthly Limits'),
          ],
        ),
        content: Text(
          'Reset bill counts for all ${users.length} restaurant(s) under\n$email?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await AdminFirestoreService.resetLimitsByEmail(email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Reset limits for $count restaurant(s)'),
                  backgroundColor: Colors.orange,
                ));
                _load(reset: true);
              }
            },
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emailActionsButton(BuildContext context, String email, List<AdminUser> users) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings, size: 18),
      tooltip: 'Admin Actions',
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'subscription', child: Row(
          children: [Icon(Icons.upgrade, size: 18), SizedBox(width: 8), Text('Change Subscription')],
        )),
        PopupMenuItem(value: 'reset', child: Row(
          children: [Icon(Icons.refresh, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Reset Monthly Limits')],
        )),
      ],
      onSelected: (action) {
        if (action == 'subscription') _showChangeSubscriptionForEmail(context, email, users);
        if (action == 'reset') _confirmResetLimitsForEmail(context, email, users);
      },
    );
  }

  // Group users by email, preserving insertion order.
  Map<String, List<AdminUser>> _groupByEmail() {
    final grouped = <String, List<AdminUser>>{};
    for (final user in _users) {
      grouped.putIfAbsent(user.email, () => []).add(user);
    }
    return grouped;
  }

  // Highest plan across all restaurants in the group — subscription is per-owner, not per-restaurant.
  SubscriptionPlan _effectivePlan(List<AdminUser> users) {
    final rank = {
      for (var i = 0; i < adminPlanCatalog.length; i++) adminPlanCatalog[i]: i,
    };
    return users.map((u) => u.subscription.plan).reduce(
      (a, b) => (rank[a]! >= rank[b]!) ? a : b,
    );
  }

  Widget _buildDataTable() {
    final grouped = _groupByEmail();
    final emails = grouped.keys.toList();

    const nameW = 220.0;
    const planW = 100.0;
    const billsW = 130.0;
    const activeW = 120.0;
    const statusW = 110.0;
    const actionsW = 60.0;
    const totalW = nameW + planW + billsW + activeW + statusW + actionsW + 32;

    Widget nameCell(AdminUser user, SubscriptionPlan effectivePlan) => SizedBox(
          width: nameW,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getPlanColor(effectivePlan),
                radius: 14,
                child: Text(
                  user.shopName.isNotEmpty ? user.shopName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(user.shopName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                    Text(user.ownerName,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );

    Widget billsCell(AdminUser user) => SizedBox(
          width: billsW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${user.limits.billsThisMonth}/${user.limits.billsLimit}'),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  value: user.limits.usagePercentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    user.limits.isNearLimit ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );

    Widget activeCell(AdminUser user) => SizedBox(
          width: activeW,
          child: Text(
            user.activity.lastActiveAgo,
            style: TextStyle(
              color: user.activity.isActiveToday ? Colors.green : Colors.grey.shade600,
              fontWeight: user.activity.isActiveToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );

    Widget actionsCell(AdminUser user) => SizedBox(
          width: actionsW,
          child: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => context.go('/super-admin/users/${user.id}'),
          ),
        );

    // Active/inactive toggle — locked when plan limit is reached and store is inactive.
    Widget statusCell(
      AdminUser user,
      List<AdminUser> groupUsers,
      SubscriptionPlan effectivePlan,
    ) {
      final isActive = user.isStoreActive;
      final activeCount = groupUsers.where((u) => u.isStoreActive).length;
      final limit = _planActiveLimit(effectivePlan);
      // Locked: inactive store and already at limit — need Business to unlock.
      final isLocked = !isActive && activeCount >= limit;
      return SizedBox(
        width: statusW,
        child: Tooltip(
          message: isLocked
              ? 'Upgrade to Business plan to activate more stores'
              : isActive
                  ? 'Click to deactivate'
                  : 'Click to activate',
          child: GestureDetector(
            onTap: isLocked
                ? null
                : () async {
                    await AdminFirestoreService.setStoreStatus(
                        user.id, isActive ? 'suspended' : 'active');
                    _load(reset: true);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : isLocked
                        ? Colors.red.withValues(alpha: 0.06)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? Colors.green
                      : isLocked
                          ? Colors.red.shade200
                          : Colors.grey.shade400),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? Icons.check_circle_outline
                        : isLocked
                            ? Icons.lock_outline
                            : Icons.block,
                    size: 13,
                    color: isActive
                        ? Colors.green
                        : isLocked
                            ? Colors.red.shade300
                            : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'Active' : isLocked ? 'Locked' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.green
                          : isLocked
                              ? Colors.red.shade300
                              : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // A flat row for a single restaurant — uses effectivePlan (owner-level) for plan badge.
    Widget flatRow(AdminUser user, SubscriptionPlan effectivePlan,
        List<AdminUser> groupUsers, {Color? bg}) => Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              nameCell(user, effectivePlan),
              SizedBox(width: planW, child: _buildPlanBadge(effectivePlan)),
              billsCell(user),
              activeCell(user),
              statusCell(user, groupUsers, effectivePlan),
              actionsCell(user),
            ],
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalW,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header row
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: nameW, child: const Text('Restaurant Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: planW, child: const Text('Plan', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: billsW, child: const Text('Bills', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: activeW, child: const Text('Last Active', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: statusW, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: actionsW, child: const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(height: 1),
            // Grouped rows
            ...emails.map((email) {
              final users = grouped[email]!;
              final effective = _effectivePlan(users);
              final planColor = _getPlanColor(effective);
              if (users.length == 1) {
                return Column(
                  children: [flatRow(users.first, effective, users), const Divider(height: 1)],
                );
              }
              // Multi-restaurant email → collapsible
              final isExpanded = _expandedEmails.contains(email);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email header row
                  InkWell(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedEmails.remove(email);
                      } else {
                        _expandedEmails.add(email);
                      }
                    }),
                    child: Container(
                      color: planColor.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: planColor,
                          ),
                          const SizedBox(width: 8),
                          Text(email,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, color: planColor)),
                          const SizedBox(width: 8),
                          _buildPlanBadge(effective),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: planColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${users.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          _emailActionsButton(context, email, users),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    ...users.map((u) => flatRow(u, effective, users, bg: planColor.withValues(alpha: 0.02))),
                  const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    final grouped = _groupByEmail();
    final emails = grouped.keys.toList();

    return ListView.builder(
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        final users = grouped[email]!;

        final effective = _effectivePlan(users);
        final planColor = _getPlanColor(effective);

        Widget restaurantTile(AdminUser user) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: planColor,
                child: Text(
                  user.shopName.isNotEmpty ? user.shopName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.shopName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildPlanBadge(effective),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: user.limits.usagePercentage,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${user.limits.billsThisMonth}/${user.limits.billsLimit}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Active/inactive chip — locked (red lock) when plan limit prevents activation.
                  GestureDetector(
                    onTap: () async {
                      final isActive = user.isStoreActive;
                      final activeCount = users.where((u) => u.isStoreActive).length;
                      final limit = _planActiveLimit(effective);
                      final isLocked = !isActive && activeCount >= limit;
                      if (isLocked) return; // tooltip shows reason
                      await AdminFirestoreService.setStoreStatus(
                          user.id, isActive ? 'suspended' : 'active');
                      _load(reset: true);
                    },
                    child: Tooltip(
                      message: () {
                        final isActive = user.isStoreActive;
                        final activeCount = users.where((u) => u.isStoreActive).length;
                        final limit = _planActiveLimit(effective);
                        if (!isActive && activeCount >= limit) {
                          return 'Upgrade to Business to activate more stores';
                        }
                        return isActive ? 'Tap to deactivate' : 'Tap to activate';
                      }(),
                      child: Builder(builder: (_) {
                        final isActive = user.isStoreActive;
                        final activeCount = users.where((u) => u.isStoreActive).length;
                        final limit = _planActiveLimit(effective);
                        final isLocked = !isActive && activeCount >= limit;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : isLocked
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? Colors.green
                                  : isLocked
                                      ? Colors.red.shade200
                                      : Colors.grey.shade400),
                          ),
                          child: Text(
                            isActive ? 'Active' : isLocked ? 'Locked' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.green
                                  : isLocked
                                      ? Colors.red.shade300
                                      : Colors.grey.shade500,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(user.activity.lastActiveAgo,
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
              onTap: () => context.go('/super-admin/users/${user.id}'),
            );

        if (users.length == 1) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                restaurantTile(users.first),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.upgrade, size: 16),
                      label: const Text('Change Subscription'),
                      onPressed: () => _showChangeSubscriptionForEmail(context, email, users),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.orange),
                      label: const Text('Reset Limits', style: TextStyle(color: Colors.orange)),
                      onPressed: () => _confirmResetLimitsForEmail(context, email, users),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Multiple restaurants → ExpansionTile grouped by email
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: planColor,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(email,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Row(
              children: [
                _buildPlanBadge(effective),
                const SizedBox(width: 8),
                Text('${users.length} restaurants',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _emailActionsButton(context, email, users),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${users.length}',
                      style: TextStyle(color: planColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            children: users.map(restaurantTile).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPlanBadge(SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getPlanColor(plan).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPlanColor(plan)),
      ),
      child: Text(
        plan.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getPlanColor(plan),
        ),
      ),
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Colors.grey;
      case SubscriptionPlan.starter:
        return Colors.teal;
      case SubscriptionPlan.pro:
        return Colors.blue;
      case SubscriptionPlan.business:
        return Colors.purple;
    }
  }
}
