import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'receipt_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final int totalPrice;
  final VoidCallback onBack;
  final Function(String paymentMethod, String? reference) onPlaceOrder;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.totalPrice,
    required this.onBack,
    required this.onPlaceOrder,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPayment = 'cash';
  String gcashNumber = '09918428234';
  bool copied = false;
  bool isLoading = false;
  final TextEditingController referenceController = TextEditingController();

  void handleCopyNumber() {
    Clipboard.setData(ClipboardData(text: gcashNumber));
    setState(() => copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => copied = false);
    });
  }

  /// 🔥 Save order to Firestore
  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    setState(() => isLoading = true);
   
    try {

      if (selectedPayment == 'gcash') {
  final ref = referenceController.text.trim();
  if (ref.length != 13) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid 13-digit reference number.')),
    );
    setState(() => isLoading = false);
    return;
  }
}
      final now = DateTime.now();
      final orderNumber = 'ORD-${now.millisecondsSinceEpoch}';
      final paymentMethod = selectedPayment;
      final reference = paymentMethod == 'gcash' ? referenceController.text : null;

      // ✅ Build order data (just like React version)
      final orderData = {
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? user.email,
        'orderNumber': orderNumber,
        'date': '${now.year}-${now.month}-${now.day}',
        'time': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        'timestamp': now.toIso8601String(),
        'items': widget.cart.map((item) => {
              'id': item['id'],
              'name': item['name'],
              'price': item['price'],
              'quantity': item['quantity'],
              'total': item['price'] * item['quantity'],
              'image': item['image'],
              'ingredients': item['ingredients']
            }).toList(),
        'subtotal': widget.totalPrice,
        'totalAmount': widget.totalPrice,
        'paymentMethod':
            paymentMethod == 'cash' ? 'Cash on Delivery' : 'GCash',
        'paymentReference': paymentMethod == 'gcash' ? reference : null,
        'status': 'received',
        'paymentConfirmed': paymentMethod == 'cash' ? false : true,
        'pickupLocation': {
          'name': 'Grace Burger CDO',
          'street': '123 Main Street',
          'barangay': 'Barangay Carmen',
          'city': 'Cagayan de Oro City',
        },
        'estimatedTime': '20-30 mins',
        'contactNumber': '+63 912 345 6789',
      };
      
      
      // ✅ Save to Firestore
      final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);
final savedOrder = await docRef.get();

if (mounted) {
  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => ReceiptPage(orderId: docRef.id),
  ),
).then((_) {
    widget.cart.clear();
    Navigator.pop(context, true);
  });
}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      print('Error saving order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.amber),
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 8),
            const Row(
              children: [
                Text('⬡', style: TextStyle(color: Colors.amber, fontSize: 20)),
                SizedBox(width: 4),
                Text(
                  'GRACE BURGER',
                  style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 800;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: orderReviewSection()),
                      const SizedBox(width: 16),
                      Expanded(child: paymentSection()),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        orderReviewSection(),
                        const SizedBox(height: 16),
                        paymentSection(),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget orderReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'YOUR ORDER',
        style: TextStyle(
          color: Colors.amber,
          fontSize: 24,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      const Text('Review your items', style: TextStyle(color: Colors.grey)),
      const Divider(color: Colors.grey),
      ...widget.cart.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Image.network(
                  item['image'] ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[900],
                      child: const Icon(Icons.fastfood,
                          color: Colors.amber, size: 40),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('₱${item['price']} × ${item['quantity']}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '₱${item['price'] * item['quantity']}',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                )
              ],
            ),
          )),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontSize: 16)),
            Text('₱${widget.totalPrice}',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ],
  ),
),

    );
  }

  Widget paymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PAYMENT METHOD',
              style:
                  TextStyle(color: Colors.amber, fontSize: 24, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Choose your payment option',
              style: TextStyle(color: Colors.grey)),
          const Divider(color: Colors.grey),
          paymentOption(
            label: 'CASH ON DELIVERY',
            description: 'Pay when you receive your order',
            icon: '💵💰',
            value: 'cash',
          ),
          paymentOption(
            label: 'GCASH',
            description: 'Instant payment via GCash',
            icon: '💰📱',
            value: 'gcash',
          ),
          if (selectedPayment == 'gcash') gcashDetails(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'PLACE ORDER',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget paymentOption({
    required String label,
    required String description,
    required String icon,
    required String value,
  }) {
    bool selected = selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1a1a1a) : Colors.transparent,
          border: Border.all(color: selected ? Colors.amber : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? Colors.amber : Colors.transparent,
                shape: BoxShape.circle,
                border:
                    Border.all(color: selected ? Colors.amber : Colors.grey),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.black,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: selected ? Colors.amber : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gcashDetails() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset('assets/qr-code.jpg', width: 200, height: 200),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(gcashNumber,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: handleCopyNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: copied ? Colors.green : Colors.amber,
                ),
                child: Text(copied ? 'Copied!' : 'Copy',
                    style: const TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
  controller: referenceController,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly, // ✅ only allow numbers
    LengthLimitingTextInputFormatter(13), // ✅ limit to 9 digits
  ],
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
    labelText: 'Enter 13-digit reference number',
    labelStyle: const TextStyle(color: Colors.amber),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.amber),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),
        ],
      ),
    );
  }
}
