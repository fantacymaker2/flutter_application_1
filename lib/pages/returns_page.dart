import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  double totalRevenue = 0;
  double returnedAmount = 0;
  double netRevenue = 0;
  double returnRate = 0;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: monthStart)
        .where('createdAt', isLessThan: nextMonth)
        .get();

    double total = 0;
    double returned = 0;

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final amount = (data['totalAmount'] ?? 0).toDouble();

      total += amount;
      if (data['returned'] == true) {
        returned += amount;
      }
    }

    setState(() {
      totalRevenue = total;
      returnedAmount = returned;
      netRevenue = total - returned;
      returnRate = total > 0 ? (returned / total) * 100 : 0;
    });
  }

  Future<void> _approveReturn(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'returned': true,
      'returnApprovedAt': FieldValue.serverTimestamp(),
      'returnRequested': false,
    });
    _calculateStats();
  }

  Future<void> _rejectReturn(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'returnRequested': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Text(
              "Return Requests",
              style: TextStyle(
                color: Color(0xFFD4A027),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildSummaryCards(),
          const SizedBox(height: 10),
          Expanded(child: _buildReturnRequests()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard("Total Revenue", "₱${totalRevenue.toStringAsFixed(2)}"),
          const SizedBox(width: 12),
          _buildStatCard("Returned Amount", "₱${returnedAmount.toStringAsFixed(2)}"),
          const SizedBox(width: 12),
          _buildStatCard("Net Revenue", "₱${netRevenue.toStringAsFixed(2)}"),
          const SizedBox(width: 12),
          _buildStatCard("Return Rate", "${returnRate.toStringAsFixed(1)}%"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFD4A027),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error loading returns",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4A027)),
          );
        }

        // ✅ Client-side filter
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['returnRequested'] == true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No return requests found.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final order = docs[index].data() as Map<String, dynamic>;
            final orderId = docs[index].id;
            final userEmail = order['userEmail'] ?? 'Unknown';
            final total = (order['totalAmount'] ?? 0).toDouble();
            final reason = order['returnReason'] ?? 'No reason provided';

            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  "Order ID: $orderId",
                  style: const TextStyle(
                    color: Color(0xFFD4A027),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("User: $userEmail",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Amount: ₱$total",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Reason: $reason",
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveReturn(orderId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectReturn(orderId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
