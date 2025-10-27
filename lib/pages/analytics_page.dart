import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  List<Map<String, dynamic>> monthlyRevenue = [];

  StreamSubscription? _analyticsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToAnalyticsData();
  }

  @override
  void dispose() {
    _analyticsSubscription?.cancel();
    super.dispose();
  }

  void _listenToAnalyticsData() {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final monthStart = now.subtract(const Duration(days: 29));

    // Cancel previous listener if any
    _analyticsSubscription?.cancel();

    _analyticsSubscription =
        firestore.collection('orders').snapshots().listen((snapshot) {
      double totalRevenue = 0;
      int totalOrders = 0;
      int completedCount = 0;
      final Map<String, Map<String, dynamic>> productStats = {};
      final Map<String, double> revenueByDate = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
DateTime? date;

if (createdAt is Timestamp) {
  date = createdAt.toDate();
} else if (createdAt is String) {
  date = DateTime.tryParse(createdAt);
}

if (date == null) continue;


        final total = (data['totalAmount'] ?? data['subtotal'] ?? 0).toDouble();
        final status = data['status'];
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        // === Today's stats ===
if (!date.isBefore(startOfDay) && !date.isAfter(endOfDay)) {
  totalOrders++;
  if (status == 'completed' || status == 'ready') {
    completedCount++;
    totalRevenue += total;
  }
}

// === Top products (all time / last 30 days) ===
for (var item in items) {
  final name = item['name'];
  final qty = (item['quantity'] ?? 0).toInt();
  final price = (item['price'] ?? 0).toDouble();

  if (!productStats.containsKey(name)) {
    productStats[name] = {'name': name, 'quantity': 0, 'revenue': 0.0};
  }

  productStats[name]!['quantity'] += qty;
  productStats[name]!['revenue'] += qty * price;
}

        // === Monthly stats ===
        if (date.isAfter(monthStart)) {
          if (status == 'completed' || status == 'ready') {
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + total;
          }
        }
      }

      // Fill missing days with 0 revenue
      final List<Map<String, dynamic>> monthData = [];
      for (int i = 29; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(day);
        monthData.add({
          'day': DateFormat('d').format(day),
          'revenue': revenueByDate[key] ?? 0.0,
        });
      }

      final sortedProducts = productStats.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
      final top5 = sortedProducts.take(5).toList();

      if (mounted) {
        setState(() {
          todayRevenue = totalRevenue;
          ordersToday = totalOrders;
          completedToday = completedCount;
          topProducts = top5;
          monthlyRevenue = monthData;
        });
      }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== STATS CARDS ======
            Wrap(
  spacing: 12, // horizontal spacing between cards
  runSpacing: 12, // vertical spacing when wrapping
  children: [
    _buildStatCard("Revenue Today", "₱${todayRevenue.toStringAsFixed(2)}", Colors.amber),
    _buildStatCard("Orders Today", "$ordersToday", Colors.blue),
    _buildStatCard("Completed", "$completedToday", Colors.green),
  ],
),
            const SizedBox(height: 24),

            // ====== MONTHLY REVENUE CHART ======
            const Text(
              "📆 Monthly Revenue (Last 30 Days)",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: monthlyRevenue.isEmpty
                  ? const Center(
                      child: Text("Loading chart...",
                          style: TextStyle(color: Colors.white54)))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: true, reservedSize: 40)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index % 5 != 0 ||
                                    index < 0 ||
                                    index >= monthlyRevenue.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  monthlyRevenue[index]['day'],
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: Colors.amber,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.amber.withOpacity(0.15),
                            ),
                            spots: List.generate(
                              monthlyRevenue.length,
                              (i) => FlSpot(i.toDouble(),
                                  monthlyRevenue[i]['revenue'].toDouble()),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // ====== TOP 5 PRODUCTS LIST ======
            const Text(
              "🏆 Top 5 Selling products",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: topProducts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No products sold today",
                            style: TextStyle(color: Colors.white54)),
                      ),
                    )
                  : Column(
                      children: List.generate(topProducts.length, (index) {
                        final product = topProducts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown.shade700,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            product['name'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            "${product['quantity']} sold",
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
  return Container(
    width: 130, // set a fixed width or let it size naturally
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
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    ),
  );
}
}
