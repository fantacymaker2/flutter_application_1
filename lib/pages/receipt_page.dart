import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic>? orderData;

  const ReceiptPage({super.key, this.orderData});

  @override
  Widget build(BuildContext context) {
    final order = orderData ?? {
      'orderNumber': '#GB-2024-0123',
      'date': 'October 18, 2025',
      'time': '7:29 PM',
      'paymentMethod': 'GCash',
      'reference': 'Ref: 1234567890',
      'contactNumber': '+63 912 345 6789',
      'items': [
        {'name': 'Cheese Burger', 'quantity': 2, 'price': 35, 'total': 70},
        {'name': 'Footlong', 'quantity': 1, 'price': 47, 'total': 47},
        {'name': 'Mountain Dew', 'quantity': 2, 'price': 25, 'total': 50},
      ],
      'subtotal': 167,
      'total': 167,
      'pickupLocation': {
        'name': 'Grace Burger CDO',
        'street': '123 Main Street',
        'barangay': 'Barangay Carmen',
        'city': 'Cagayan de Oro City',
      },
      'estimatedTime': '20-30 mins',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
  backgroundColor: Colors.black,
  automaticallyImplyLeading: false, // removes the default back button
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
  Future.microtask(() {
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false);
    }
  });
},
    ),
  ],
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ ORDER CONFIRMATION CARD
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
                    child: const Icon(Icons.check, size: 40, color: Colors.black),
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
                  const Text(
                    'Thank you for your order',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    order['orderNumber'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Confirmation sent to your email',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 60,
                    height: 2,
                    color: const Color(0xFFD4A027),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ✅ ORDER DETAILS
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
                      '${order['paymentMethod']} (${order['reference']})'),
                  _buildInfoRow('CONTACT NUMBER', order['contactNumber']),
                  const SizedBox(height: 20),

                  // 🧾 ITEMS ORDERED
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
                  ...List.generate(order['items'].length, (i) {
                    final item = order['items'][i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
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

                  // 💰 TOTAL
                  _buildTotalRow('Subtotal', order['subtotal'].toString()),
                  const SizedBox(height: 8),
                  _buildTotalRow('TOTAL', order['total'].toString(), highlight: true),
                  const SizedBox(height: 8),
                  _buildPaidStatus(),

                  const SizedBox(height: 20),

                  // 📥 ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ✅ ORDER STATUS SECTION
            _buildOrderStatus(order),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFD4A027),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String amount, {bool highlight = false}) {
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

  Widget _buildPaidStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A5A2A)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Text(
            'PAYMENT RECEIVED',
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(Map<String, dynamic> order) {
    return Container(
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
          const SizedBox(height: 8),
          Text(
            'Estimated pickup time: ${order['estimatedTime']}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 0.25,
            color: const Color(0xFFD4A027),
            backgroundColor: const Color(0xFF1A1A1A),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          const Text(
            '📦 ORDER RECEIVED → 🍳 PREPARING → 🍔 READY → ✓ COMPLETED',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
  Future<void> _downloadReceipt(
  BuildContext context,
  Map<String, dynamic> order,
) async {
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
                child: pw.Text(
                  'GRACE BURGER RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text('Order No: ${order['orderNumber']}'),
              pw.Text('Date: ${order['date']} • ${order['time']}'),
              pw.Text('Payment: ${order['paymentMethod']}'),
              pw.Text('Reference: ${order['reference']}'),
              pw.SizedBox(height: 20),
              pw.Text('Items Ordered:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...order['items'].map<pw.Widget>((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${item['quantity']}x ${item['name']}'),
                    pw.Text('₱${item['total']}'),
                  ],
                );
              }).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('₱${order['total']}'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Pickup Location:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(order['pickupLocation']['name']),
              pw.Text(
                  '${order['pickupLocation']['street']}, ${order['pickupLocation']['barangay']}, ${order['pickupLocation']['city']}'),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Thank you for ordering from Grace Burger!',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'GraceBurger_Receipt_${order['orderNumber']}.pdf',
    );

    if (!context.mounted) return; // ✅ Ensure context still valid
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt downloaded successfully!')),
    );
  } catch (e) {
    if (!context.mounted) return; // ✅ Prevent using disposed context
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error generating receipt: $e')),
    );
  }
}


}
