import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';
import 'order_history_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final List<Map<String, dynamic>> _cart = [];
  final TextEditingController _searchController = TextEditingController();

  TabController? _tabController;
  String _searchText = "";
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _inventory = []; // ✅ store inventory data
  List<Map<String, dynamic>> _topItems = [];
  bool _isLoadingTopItems = true;


  late AnimationController _cartController;
  bool _isCartVisible = false;

  final List<String> categories = [
    "All",
    "Burgers",
    "Sandwiches",
    "Hot Dogs",
    "Rice Meals",
    "Sides",
    "Beverages"
  ];

  @override
  @override
void initState() {
  super.initState();
  _tabController = TabController(length: categories.length, vsync: this);
  _cartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  _fetchMenu();
  _fetchInventory();
  _fetchTopOrderedItems(); // ✅ Fetch Top 5 once

  _searchController.addListener(() {
    setState(() {
      _searchText = _searchController.text;
    });
  });
}


  @override
  void dispose() {
    _tabController?.dispose();
    _cartController.dispose();
    super.dispose();
  }

  // ✅ fetch inventory collection
  Future<void> _fetchInventory() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('inventory').get();

      final List<Map<String, dynamic>> inventoryData = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? '',
          'stock': data['stock'] ?? 0,
        };
      }).toList();

      setState(() {
        _inventory = inventoryData;
      });
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    }
  }

  Future<void> _fetchMenu() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final menuSnapshot = await firestore.collection('menu').get();

      List<Map<String, dynamic>> allItems = [];

      for (final categoryDoc in menuSnapshot.docs) {
        final itemsSnapshot =
            await categoryDoc.reference.collection('items').get();

        for (final itemDoc in itemsSnapshot.docs) {
          final data = itemDoc.data();
          allItems.add({
            'id': data['id'] ?? '',
            'name': data['name'] ?? '',
            'price': data['price'] ?? 0,
            'category': data['category'] ?? categoryDoc.id,
            'image': data['image'] ?? 'https://via.placeholder.com/150',
            'description': data['description'] ?? '',
            'ingredients': (data['ingredients'] != null &&
                    data['ingredients'] is List)
                ? List<String>.from(data['ingredients'])
                : [],
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _menuItems = allItems;
      });
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      if (!mounted) return;
      setState(() {
        _menuItems = [];
      });
    }
  }

  // ✅ React-style sold out check
  bool _isItemSoldOut(Map<String, dynamic> item) {
    final ingredients = item['ingredients'] ?? [];

    if (ingredients.isEmpty) return false;

    // If inventory not loaded or empty, mark as sold out
    if (_inventory.isEmpty) return true;

    for (final ingredientName in ingredients) {
      final match = _inventory.firstWhere(
        (inv) =>
            inv['name'].toString().toLowerCase().trim() ==
            ingredientName.toString().toLowerCase().trim(),
        orElse: () => {},
      );

      if (match.isEmpty || (match['stock'] ?? 0) <= 0) {
        return true;
      }
    }

    return false;
  }

  // 🔥 Top 5 Most Ordered logic unchanged
  Future<void> _fetchTopOrderedItems() async {
  setState(() => _isLoadingTopItems = true);
  final ordersSnapshot =
      await FirebaseFirestore.instance.collection('orders').get();

  Map<String, Map<String, dynamic>> itemCounts = {};

  for (var orderDoc in ordersSnapshot.docs) {
    final data = orderDoc.data();
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    for (var item in items) {
      final name = item['name'];
      if (itemCounts.containsKey(name)) {
        itemCounts[name]!['count'] += (item['quantity'] ?? 1);
      } else {
        itemCounts[name] = {
          'name': name,
          'image': item['image'],
          'price': item['price'],
          'count': item['quantity'] ?? 1,
        };
      }
    }
  }

  List<Map<String, dynamic>> sortedItems = itemCounts.values.toList();
  sortedItems.sort((a, b) => b['count'].compareTo(a['count']));

  if (!mounted) return;
  setState(() {
    _topItems = sortedItems.take(5).toList();
    _isLoadingTopItems = false;
  });
}

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existing = _cart.indexWhere((i) => i['id'] == item['id']);
      if (existing >= 0) {
        _cart[existing]['quantity'] += 1;
      } else {
        _cart.add({...item, 'quantity': 1});
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to cart')),
    );
  }

  void _toggleCart() {
    setState(() {
      _isCartVisible = !_isCartVisible;
      _isCartVisible ? _cartController.forward() : _cartController.reverse();
    });
  }

  List<Map<String, dynamic>> _getFilteredItems(String category) {
    List<Map<String, dynamic>> filtered = category == "All"
        ? _menuItems
        : _menuItems.where((item) => item['category'] == category).toList();

    if (_searchText.isNotEmpty) {
      filtered = filtered
          .where((item) => item['name']
              .toString()
              .toLowerCase()
              .contains(_searchText.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: categories.map((cat) => Tab(text: cat)).toList(),
        ),
        actions: [
  IconButton(
    icon: const Icon(Icons.history),
    tooltip: 'Order History',
    onPressed: () {
      final user = FirebaseAuth.instance.currentUser;
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => OrderHistoryPage(userId: user!.uid),
  ),
);
    },
  ),
  Stack(
    alignment: Alignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.shopping_cart),
        onPressed: _toggleCart,
      ),
      if (_cart.isNotEmpty)
        Positioned(
          right: 6,
          top: 6,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: Colors.red,
            child: Text(
              _cart.length.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
    ],
  ),
  IconButton(
    icon: const Icon(Icons.logout),
    tooltip: 'Logout',
    onPressed: () async {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    },
  ),
],

      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 🔥 Top 5 Section stays the same
              _isLoadingTopItems
  ? const Center(child: CircularProgressIndicator())
  : _topItems.isEmpty
      ? const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("🔥 No top orders yet"),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🔥 Top 5 Most Ordered",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topItems.length,
                  itemBuilder: (context, index) {
                    final item = _topItems[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 10),
                      child: Card(
                        color: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(
                                  item['image'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.fastfood, size: 50),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text('₱${item['price']}',
                                      style: const TextStyle(color: Colors.white70)),
                                  Text('Ordered ${item['count']}x',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.orangeAccent)),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    onPressed: () {
                                      final matched = _menuItems.firstWhere(
                                        (m) => m['name']
                                            .toString()
                                            .toLowerCase() ==
                                        item['name'].toString().toLowerCase(),
                                        orElse: () => {},
                                      );
                                      final fullItem = matched.isNotEmpty
                                          ? matched
                                          : {
                                              'id': item['name'],
                                              'name': item['name'],
                                              'price': item['price'],
                                              'image': item['image'],
                                              'description': '',
                                              'ingredients': const [],
                                            };
                                      _addToCart(fullItem);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                    child: const Text('Add to Cart'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 1),
            ],
          ),
        ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search in this category",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: categories.map((category) {
                    final items = _getFilteredItems(category);
                    if (items.isEmpty) {
                      return const Center(child: Text('No items found.'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSoldOut = _isItemSoldOut(item); // ✅ check here
                        return Stack(
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(15)),
                                      child: ColorFiltered(
                                        colorFilter: isSoldOut
                                            ? const ColorFilter.mode(
                                                Colors.black45,
                                                BlendMode.darken)
                                            : const ColorFilter.mode(
                                                Colors.transparent,
                                                BlendMode.multiply),
                                        child: Image.network(
                                          item['image'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'],
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold)),
                                        Text('₱${item['price']}'),
                                        const SizedBox(height: 4),
                                        Text(item['description'],
                                            style:
                                                const TextStyle(fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: isSoldOut
                                              ? null
                                              : () => _addToCart(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSoldOut
                                                ? Colors.grey
                                                : Colors.orangeAccent,
                                          ),
                                          child: Text(isSoldOut
                                              ? 'Sold Out'
                                              : 'Add to Cart'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          // ✅ unchanged cart drawer below
          AnimatedBuilder(
            animation: _cartController,
            builder: (context, child) {
              return FractionalTranslation(
                translation: Offset(1 - _cartController.value, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 300,
                    color: Colors.white,
                    child: Column(
                      children: [
                        AppBar(
                          title: const Text("Your Cart"),
                          automaticallyImplyLeading: false,
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _toggleCart,
                            ),
                            
                          ],
                          
                        ),
                        Expanded(
                          child: _cart.isEmpty
                              ? const Center(child: Text('Cart is empty'))
                              : ListView.builder(
                                  itemCount: _cart.length,
                                  itemBuilder: (context, index) {
                                    final item = _cart[index];
                                    return ListTile(
                                      title: Text(item['name']),
                                      subtitle: Text(
                                          '₱${item['price']} x ${item['quantity']}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              setState(() {
                                                if (item['quantity'] > 1) {
                                                  item['quantity'] -= 1;
                                                } else {
                                                  _cart.removeAt(index);
                                                }
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              setState(() {
                                                item['quantity'] += 1;
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              setState(() {
                                                _cart.removeAt(index);
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
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                'Total: ₱${_cart.fold(0, (sum, item) => sum + ((item['price'] as num) * (item['quantity'] ?? 1)).toInt())}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (_cart.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutPage(
                                          cart: _cart,
                                          totalPrice: _cart.fold(0, (sum, item) {
                                            final price =
                                                (item['price'] as num).toDouble();
                                            final quantity =
                                                (item['quantity'] ?? 1) as int;
                                            return sum + (price * quantity).toInt();
                                          }),
                                          onBack: () => Navigator.pop(context),
                                          onPlaceOrder: (orderId, extra) async {
                                            print('Order placed: $orderId');
                                          },
                                        ),
                                      ),
                                    ).then((shouldClear) {
                                      if (shouldClear == true) {
                                        setState(() => _cart.clear());
                                      }
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Checkout'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
