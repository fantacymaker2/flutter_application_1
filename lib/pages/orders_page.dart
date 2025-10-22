import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  Stream<QuerySnapshot> getOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(String id, String status, {List<dynamic>? items}) async {
  final firestore = FirebaseFirestore.instance;
  final orderRef = firestore.collection('orders').doc(id);
  final inventoryRef = firestore.collection('inventory');

  await firestore.runTransaction((transaction) async {
    // 🔹 Update order status
    transaction.update(orderRef, {'status': status});

    // 🔹 When order starts preparing → update inventory
    if (status == 'preparing' && items != null) {
      // 🧩 1. Combine ingredient usage across all items
      final Map<String, int> totalUsed = {};

      for (var item in items) {
        final ingredients = List<String>.from(item['ingredients'] ?? []);
        final quantity = (item['quantity'] ?? 1).toInt();

        for (var ingredient in ingredients) {
  final int qty = (quantity is num) ? quantity.toInt() : 1;
  totalUsed[ingredient] = (totalUsed[ingredient] ?? 0) + qty;
}
      }

      // 🧮 2. Deduct combined quantities from inventory
      for (var entry in totalUsed.entries) {
        final ingredient = entry.key;
        final totalQuantity = entry.value;

        // Find ingredient document in inventory
        final snapshot = await inventoryRef
            .where('name', isEqualTo: ingredient)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final docRef = doc.reference;
          final currentStock = (doc['stock'] ?? 0).toInt();
          final newStock = (currentStock - totalQuantity).clamp(0, 999999).toInt();

          print('🧮 $ingredient stock updated: $currentStock → $newStock');

          transaction.update(docRef, {'stock': newStock});
        } else {
          print('⚠️ Ingredient "$ingredient" not found in inventory.');
        }
      }
    }
  });
}


  Future<void> cancelOrder(String id) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(id)
        .update({'status': 'cancelled'});
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'received':
        return Colors.orange;
      case 'preparing':
        return Colors.blueAccent;
      case 'ready':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Orders Dashboard"),
        backgroundColor: Colors.brown.shade800,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No orders yet.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          // Calculate dashboard stats
          final today = DateTime.now();
          int pendingCount = 0;
          int completedCount = 0;
          int totalToday = 0;
          double revenueToday = 0;

          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            DateTime createdAt;

final rawDate = data['createdAt'];
if (rawDate is Timestamp) {
  createdAt = rawDate.toDate();
} else if (rawDate is String) {
  createdAt = DateTime.tryParse(rawDate) ?? DateTime.now();
} else {
  createdAt = DateTime.now();
}
            final isToday = createdAt.year == today.year &&
                createdAt.month == today.month &&
                createdAt.day == today.day;

            if (status == 'received') pendingCount++;
            if (status == 'completed') completedCount++;
            if (isToday) {
              totalToday++;
              if (status == 'completed') {
  revenueToday += (data['totalAmount'] ?? data['subtotal'] ?? 0).toDouble();
}
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ───── DASHBOARD STATS ─────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Pending", "$pendingCount", Colors.orange),
                      _buildStatCard("Completed", "$completedCount", Colors.green),
                      _buildStatCard("Orders Today", "$totalToday", Colors.blue),
                      _buildStatCard("Revenue", "₱${revenueToday.toStringAsFixed(2)}", Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ───── ORDERS LIST ─────
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final data = order.data() as Map<String, dynamic>;
                      final items = data['items'] as List<dynamic>? ?? [];
                      final status = data['status'] ?? 'unknown';
                      final customer = data['customerName'] ?? 'Guest';
                      final payment = data['paymentMethod'] ?? 'Cash';
                      final total = (data['totalAmount'] ?? data['subtotal'] ?? 0).toDouble();
                      DateTime createdAt;
final rawDate = data['createdAt'];
if (rawDate is Timestamp) {
  createdAt = rawDate.toDate();
} else if (rawDate is String) {
  createdAt = DateTime.tryParse(rawDate) ?? DateTime.now();
} else {
  createdAt = DateTime.now();
}

                      // Skip cancelled orders
                      if (status == 'cancelled') return const SizedBox();

                      return Card(
                        color: const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    customer,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Items
                              Text(
                                items
                                    .map((item) =>
                                        "${item['quantity']}× ${item['name']}")
                                    .join(', '),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 8),

                              // Footer
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "₱$total — $payment",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    DateFormat('MMM d, h:mm a')
                                        .format(createdAt),
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (status == 'received' ||
                                      status == 'processing')
                                    ElevatedButton(
                                      onPressed: () => updateOrderStatus(order.id, 'preparing', items: items),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange),
                                      child: const Text("ACCEPT"),
                                    ),
                                  if (status == 'preparing')
                                    ElevatedButton(
                                      onPressed: () =>
                                          updateOrderStatus(order.id, 'ready'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber),
                                      child: const Text("MARK READY"),
                                    ),
                                  if (status == 'ready')
                                    ElevatedButton(
                                      onPressed: () => updateOrderStatus(
                                          order.id, 'completed'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text("COMPLETE"),
                                    ),
                                  if (status != 'completed' &&
                                      status != 'cancelled')
                                    const SizedBox(width: 8),
                                  if (status != 'completed' &&
                                      status != 'cancelled')
                                    OutlinedButton(
                                      onPressed: () => cancelOrder(order.id),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      child: const Text("CANCEL",
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
