import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  double todayRevenue = 0;
  int ordersToday = 0;
  int completedToday = 0;
  List<Map<String, dynamic>> topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Get today's orders
    final ordersSnapshot = await firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    double totalRevenue = 0;
    int totalOrders = ordersSnapshot.docs.length;
    int completedCount = 0;

    // Count products sold
    final Map<String, Map<String, dynamic>> productStats = {};

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final total = (data['totalAmount'] ?? data['subtotal'] ?? 0).toDouble();
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

      
      if (status == 'completed' || status == 'ready') {
        completedCount++;
        totalRevenue += total;
      }

      for (var item in items) {
        final name = item['name'];
        final qty = (item['quantity'] ?? 0).toInt();
        final price = (item['price'] ?? 0).toDouble();

        if (!productStats.containsKey(name)) {
          productStats[name] = {
            'name': name,
            'quantity': 0,
            'revenue': 0.0,
          };
        }

        productStats[name]!['quantity'] += qty;
        productStats[name]!['revenue'] += qty * price;
      }
    }

    final sortedProducts = productStats.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

    setState(() {
      todayRevenue = totalRevenue;
      ordersToday = totalOrders;
      completedToday = completedCount;
      topProducts = sortedProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("📈 Analytics Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.brown.shade800,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====== STATS CARDS ======
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard("Revenue Today", "₱${todayRevenue.toStringAsFixed(2)}", Colors.amber),
                  _buildStatCard("Orders Today", "$ordersToday", Colors.blue),
                  _buildStatCard("Completed", "$completedToday", Colors.green),
                ],
              ),
              const SizedBox(height: 24),

              // ====== TOP PRODUCTS ======
              const Text(
                "🏆 Top-Selling Products Today",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              if (topProducts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No products sold yet today.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topProducts.length,
                  itemBuilder: (context, index) {
                    final product = topProducts[index];
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown.shade700,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          product['name'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${product['quantity']} sold",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          "₱${product['revenue'].toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
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
