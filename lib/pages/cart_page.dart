import 'package:flutter/material.dart';
import 'cart_manager.dart';

class CartPage extends StatefulWidget {
  final CartManager cart;

  const CartPage({super.key, required this.cart}); // ✅ must receive cart

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: cartItems.isEmpty
    ? const Center(child: Text('Your cart is empty'))
    : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                final data = cartItem.data;
                final quantity = cartItem.quantity;

                return ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(data['imageUrl'], width: 50, height: 50)
                      : const Icon(Icons.fastfood),
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Text('₱${data['price']} x $quantity'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            widget.cart.decreaseQuantity(index);
                          });
                        },
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            widget.cart.increaseQuantity(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total: ₱${widget.cart.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

    );
  }
}
