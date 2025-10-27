import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'receipt_placeholder_page.dart';

class OrderHistoryPage extends StatefulWidget {
  final String userId;
  const OrderHistoryPage({super.key, required this.userId});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _filterStatus = 'all';

  Future<void> _handleReturnRequest(
      String orderId, Map<String, dynamic> data) async {
    final TextEditingController reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          "Return Request",
          style: TextStyle(color: Colors.orangeAccent),
        ),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Enter reason for return",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white38)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            child: const Text("Submit", style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'returnRequested': true,
        'returnReason': reason,
        'returnRequestedAt': FieldValue.serverTimestamp(),
        'returnStatus': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Return request submitted!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting request: $e")),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      case 'preparing':
      case 'received':
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }

  String _getReturnLabel(Map<String, dynamic> data) {
    if (data['returned'] == true) return "RETURNED";
    if (data['returnStatus'] == 'approved') return "RETURNED";
    if (data['returnStatus'] == 'pending' || data['returnRequested'] == true) {
      return "RETURN PENDING";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Your Orders",
          style: TextStyle(color: Colors.orangeAccent),
        ),
        iconTheme: const IconThemeData(color: Colors.orangeAccent),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.orangeAccent),
            onSelected: (value) {
              setState(() => _filterStatus = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text("All")),
              PopupMenuItem(value: 'received', child: Text("Received")),
              PopupMenuItem(value: 'preparing', child: Text("Preparing")),
              PopupMenuItem(value: 'completed', child: Text("Completed")),
              PopupMenuItem(value: 'cancelled', child: Text("Cancelled")),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No orders yet 🛒",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final allOrders = snapshot.data!.docs;
          final userOrders = allOrders
              .where((doc) => doc['userId'] == widget.userId)
              .where((doc) =>
                  _filterStatus == 'all' || doc['status'] == _filterStatus)
              .toList();

          if (userOrders.isEmpty) {
            return const Center(
              child: Text(
                "No matching orders 🛍️",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: userOrders.length,
            itemBuilder: (context, index) {
              final doc = userOrders[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final total = data['totalAmount'] ?? 0;
              final date = data['date'] ?? '';
              final time = data['time'] ?? '';
              final orderNumber = data['orderNumber'] ?? '';
              final items = data['items'] as List<dynamic>? ?? [];
              final returnRequested = data['returnRequested'] == true;
              final returnStatus = data['returnStatus'] ?? '';
              final returned = data['returned'] == true;

              final returnLabel = _getReturnLabel(data);
              final isReturnDisabled = returnRequested ||
                  returned ||
                  returnStatus == 'pending' ||
                  returnStatus == 'approved';

              // --- 💅 Improved Card UI ---
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟧 Header
                      // 🟧 Header (wrapped)
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      "Order #$orderNumber",
      style: const TextStyle(
        color: Colors.orangeAccent,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      "$date • $time",
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
      ),
    ),
  ],
),
                      const SizedBox(height: 10),

                      // 🟧 Status & Return Labels
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toString().toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (returnLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (returnLabel == "RETURNED"
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                returnLabel,
                                style: TextStyle(
                                  color: returnLabel == "RETURNED"
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 🟧 Item Thumbnails
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i] as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['image'] ?? '',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[900],
                                    width: 70,
                                    height: 70,
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.orangeAccent),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🟧 Total
                      Text(
                        "Total: ₱$total",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🟧 Buttons (now using Wrap)
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.receipt_long,
                                color: Colors.orangeAccent),
                            label: const Text("Receipt",
                                style: TextStyle(color: Colors.orangeAccent)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orangeAccent),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReceiptPlaceholderPage(orderId: doc.id),
                                ),
                              );
                            },
                          ),
                          if (status == 'completed')
                            OutlinedButton.icon(
                              icon: Icon(
                                Icons.assignment_return,
                                color: isReturnDisabled
                                    ? Colors.grey
                                    : Colors.redAccent,
                              ),
                              label: Text(
                                returnStatus == 'approved'
                                    ? "Returned"
                                    : returnStatus == 'pending' ||
                                            returnRequested
                                        ? "Pending"
                                        : "Return",
                                style: TextStyle(
                                  color: isReturnDisabled
                                      ? Colors.grey
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isReturnDisabled
                                      ? Colors.grey
                                      : Colors.redAccent,
                                ),
                              ),
                              onPressed: isReturnDisabled
                                  ? null
                                  : () =>
                                      _handleReturnRequest(doc.id, data),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
