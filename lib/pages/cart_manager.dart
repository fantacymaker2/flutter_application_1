import 'package:cloud_firestore/cloud_firestore.dart';

/// A wrapper class to hold a product and its quantity
class CartItem {
  final QueryDocumentSnapshot<Map<String, dynamic>> product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> get data => product.data();
}

class CartManager {
  // --- Singleton instance ---
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  // --- Cart items list ---
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  /// Adds an item to cart; if it exists, increase quantity
  void addToCart(QueryDocumentSnapshot<Map<String, dynamic>> item) {
    final existingIndex = _items.indexWhere(
      (cartItem) => cartItem.product.id == item.id,
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: item));
    }
  }

  /// Decrease quantity, remove if 0
  void decreaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity--;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
    }
  }

  /// Increase quantity
  void increaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
    }
  }

  /// Remove a specific item
  void removeFromCart(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  /// Clear all items
  void clearCart() {
    _items.clear();
  }

  /// Compute total price
  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      final data = item.data;
      final price = double.tryParse(data['price'].toString()) ?? 0;
      total += price * item.quantity;
    }
    return total;
  }
}
