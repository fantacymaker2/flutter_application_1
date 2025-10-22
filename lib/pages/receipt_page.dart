import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPage extends StatelessWidget {
  final String orderId;

  const ReceiptPage({super.key, required this.orderId});

  double _getProgressValue(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return 0.25;
      case 'preparing':
        return 0.5;
      case 'ready':
        return 0.75;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _getReadableStatus(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return '📦 ORDER RECEIVED';
      case 'preparing':
        return '🍳 PREPARING ORDER';
      case 'ready':
        return '🍔 READY FOR PICKUP';
      case 'completed':
        return '✅ ORDER COMPLETED';
      default:
        return '⏳ WAITING FOR UPDATE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(), // 🔥 Real-time updates
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A027)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text('Order not found',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final order = snapshot.data!.data() as Map<String, dynamic>;
        final progress = _getProgressValue(order['status'] ?? 'received');
        final readableStatus = _getReadableStatus(order['status'] ?? 'received');

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
            title: const Row(
              children: [
                Text('🍔', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text(
                  'GRACE BURGER',
                  style: TextStyle(
                    color: Color(0xFFD4A027),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFFD4A027)),
                tooltip: 'Back to Menu',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/menu',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✅ Order Confirmation Section
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF222222)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A027),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.check, size: 40, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ORDER CONFIRMED!',
                        style: TextStyle(
                          color: Color(0xFFD4A027),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Thank you for your order',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      Text(
                        '#${order['orderNumber'] ?? orderId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                          width: 60, height: 2, color: const Color(0xFFD4A027)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ✅ Order Info + Items
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF222222)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('ORDER DATE & TIME',
                          '${order['date']} • ${order['time']}'),
                      _buildInfoRow('PAYMENT METHOD',
                          '${order['paymentMethod'] ?? ''}'),
                      _buildInfoRow(
                          'CONTACT NUMBER', order['contactNumber'] ?? ''),

                      const SizedBox(height: 20),
                      const Text(
                        'ITEMS ORDERED',
                        style: TextStyle(
                          color: Color(0xFFD4A027),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate((order['items'] ?? []).length, (i) {
                        final item = order['items'][i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'],
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  Text(
                                    '${item['quantity']} × ₱${item['price']}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                '₱${item['total']}',
                                style: const TextStyle(
                                  color: Color(0xFFD4A027),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: Color(0xFF333333), thickness: 1),
                      const SizedBox(height: 8),
                      _buildTotalRow('Subtotal', '${order['subtotal']}'),
                      _buildTotalRow('TOTAL', '${order['totalAmount']}',
                          highlight: true),

                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD4A027)),
                          foregroundColor: const Color(0xFFD4A027),
                        ),
                        icon: const Icon(Icons.download),
                        label: const Text('DOWNLOAD RECEIPT'),
                        onPressed: () async {
                          await _downloadReceipt(context, order);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ✅ Real-time Status
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF222222)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER STATUS',
                        style: TextStyle(
                          color: Color(0xFFD4A027),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(readableStatus,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: progress,
                        color: const Color(0xFFD4A027),
                        backgroundColor: const Color(0xFF1A1A1A),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFFD4A027), fontSize: 12, letterSpacing: 1)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String amount,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          '₱$amount',
          style: TextStyle(
            color: highlight ? const Color(0xFFD4A027) : Colors.white,
            fontSize: highlight ? 24 : 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadReceipt(
      BuildContext context, Map<String, dynamic> order) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('GRACE BURGER RECEIPT',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Text('Order No: ${order['orderNumber']}'),
                pw.Text('Date: ${order['date']} • ${order['time']}'),
                pw.Text('Payment: ${order['paymentMethod']}'),
                pw.SizedBox(height: 20),
                pw.Text('Items Ordered:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...List<pw.Widget>.from((order['items'] ?? []).map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item['quantity']}x ${item['name']}'),
                      pw.Text('₱${item['total']}'),
                    ],
                  );
                })),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('₱${order['totalAmount']}'),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                    child: pw.Text('Thank you for ordering from Grace Burger!',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
          ),
        ),
      );
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'GraceBurger_Receipt_${order['orderNumber']}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating receipt: $e')),
      );
    }
  }
}
