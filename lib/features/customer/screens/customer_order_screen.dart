/// Customer-facing order status tracking screen (no auth required)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerOrderScreen extends StatelessWidget {
  final String hotelId;
  const CustomerOrderScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
        centerTitle: true,
      ),
      body: const _OrderLookupBody(),
    );
  }
}

class _OrderLookupBody extends StatefulWidget {
  const _OrderLookupBody();

  @override
  State<_OrderLookupBody> createState() => _OrderLookupBodyState();
}

class _OrderLookupBodyState extends State<_OrderLookupBody> {
  final _phoneCtrl = TextEditingController();
  List<Map<String, dynamic>>? _orders;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Lookup form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Enter your phone number to track orders',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _lookupOrders,
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Track Orders'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results
          if (_orders != null && _orders!.isEmpty)
            const Expanded(
              child: Center(child: Text('No orders found for this phone number')),
            ),

          if (_orders != null && _orders!.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _orders!.length,
                itemBuilder: (context, index) {
                  final order = _orders![index];
                  final status = order['status'] ?? 'unknown';
                  final statusColor = switch (status) {
                    'new' => Colors.blue,
                    'inProgress' || 'preparing' => Colors.orange,
                    'ready' => Colors.green,
                    'served' || 'completed' => Colors.grey,
                    _ => Colors.grey,
                  };

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.restaurant,
                        color: statusColor,
                      ),
                      title: Text('Order #${(order['orderNumber'] ?? index + 1)}'),
                      subtitle: Text(
                        '${(order['items'] as List?)?.length ?? 0} items',
                      ),
                      trailing: Chip(
                        label: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10),
                        ),
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _lookupOrders() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;

    setState(() => _loading = true);
    try {
      // Find the hotelId from the route
      final hotelId = (context.findAncestorWidgetOfExactType<CustomerOrderScreen>())?.hotelId;
      if (hotelId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users/$hotelId/orders')
          .where('customerPhone', isEqualTo: phone)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      setState(() {
        _orders = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }
}
