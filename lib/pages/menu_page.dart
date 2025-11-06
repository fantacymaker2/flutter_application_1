import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';
import 'order_history_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}
const kBackground = Color(0xFF000000); // main background
const kPanel = Color(0xFF111111); // card/panel background
const kAccent = Color(0xFFD4A027); // gold accent
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
  bool _showTopItems = true;
  bool _showTop5 = true; // controls collapse / expand
  
late AnimationController _top5Controller;
late Animation<double> _top5Animation;


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
void initState() {
  super.initState();
  _tabController = TabController(length: categories.length, vsync: this);
  _cartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

   // ADD THIS FOR TOP 5 SLIDE
  _top5Controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  _top5Animation = CurvedAnimation(
    parent: _top5Controller,
    curve: Curves.easeInOut,
  );
  _top5Controller.forward(); // start expanded

   _initData();

  _searchController.addListener(() {
    setState(() {
      _searchText = _searchController.text;
    });
  });
}

Future<void> _initData() async {
  await _fetchMenu();       // make sure _menuItems is ready
  await _fetchInventory();  // load inventory after
  await _fetchTopOrderedItems(); // ✅ now images will map correctly
}

  @override
  void dispose() {
    _tabController?.dispose();
    _cartController.dispose();
    _top5Controller.dispose();
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
            'image': data['imageUrl'] ?? 'https://via.placeholder.com/150',
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
      final name = item['name']?.toString()?.trim() ?? '';
      final price = item['price'] ?? 0;

      if (name.isEmpty) continue;

      if (itemCounts.containsKey(name)) {
        itemCounts[name]!['count'] += (item['quantity'] ?? 1);
      } else {
        itemCounts[name] = {
          'name': name,
          'price': price,
          'count': item['quantity'] ?? 1,
        };
      }
    }
  }

  List<Map<String, dynamic>> sortedItems = itemCounts.values.toList();
  sortedItems.sort((a, b) => b['count'].compareTo(a['count']));

  // 🧠 Always replace image with one from the menu if available
  for (var item in sortedItems) {
    final match = _menuItems.firstWhere(
      (m) =>
          m['name'].toString().toLowerCase().trim() ==
          item['name'].toString().toLowerCase().trim(),
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      item['image'] = match['image'] ?? 'https://via.placeholder.com/150';
    } else {
      print("⚠️ No match in menu for: ${item['name']}");
      item['image'] = 'https://via.placeholder.com/150';
    }
  }

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
    // ✅ Snackbar notification (this is what you removed before)
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("${item['name']} added to cart"),
      duration: const Duration(seconds: 1),
    ),
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

  void _showLogoutDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Log Out"),
      content: const Text("Are you sure you want to log out?"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(context); // close popup
            await FirebaseAuth.instance.signOut();
            await GoogleSignIn().signOut(); // also clear Google session
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          child: const Text("Log Out"),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPanel,
        title: const Text('Menu',style: TextStyle(color: Colors.white),),
        bottom: TabBar(
  controller: _tabController,
  isScrollable: true,
  indicatorColor: kAccent,
  labelColor: kAccent,
  unselectedLabelColor: Colors.white70,
  tabs: categories.map((cat) => Tab(text: cat)).toList(),
),
        actions: [
  IconButton(
    icon: const Icon(Icons.history, color: Colors.white),
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
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
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
  icon: const Icon(Icons.logout, color: Colors.white),
  tooltip: 'Logout',
  onPressed: _showLogoutDialog,
),
],

      ),
      body: Stack(
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🧭 Search bar on top
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
  hintText: "Search in this category",
  hintStyle: const TextStyle(color: Colors.white54),
  prefixIcon: const Icon(Icons.search, color: Colors.white70),
  filled: true,
  fillColor: kPanel,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
),
style: const TextStyle(color: Colors.white),
          ),
        ),

        // 🔥 Top 5 collapsible section
if (_isLoadingTopItems)
  const Center(child: CircularProgressIndicator())
else if (_topItems.isEmpty)
  const SizedBox.shrink()
else
 Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () {
          setState(() {
            _showTopItems = !_showTopItems;
            
          });
          if (_showTopItems) {
    _top5Controller.forward();
  } else {
    _top5Controller.reverse();
  }
        },
        child: Row(
          children: [
            const Text(
              "🔥 Top 5 Most Ordered",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kAccent,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _showTopItems ? 0 : 0.5, // flips arrow
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.keyboard_arrow_down, color: kAccent),
            ),
          ],
        ),
      ),

      SizeTransition(
        sizeFactor: _top5Animation,
        axisAlignment: 1.0,
        child: Column(
          children: [
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
                      color: kPanel,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: Image.network(
                                item['image'] ?? '',
                                fit: BoxFit.cover,
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
                                        fontSize: 12,
                                        color: Colors.orangeAccent)),
                                const SizedBox(height: 6),
                                ElevatedButton(
                                  onPressed: () {
                                    final matched = _menuItems.firstWhere(
                                      (m) =>
                                          m['name'].toString().toLowerCase() ==
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
    ],
  ),
),



        // 🧱 Expand the tabbed menu grid below
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSoldOut = _isItemSoldOut(item);
                  return Stack(
                    children: [
                      Card(
                        color: kPanel,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: ColorFiltered(
                                  colorFilter: isSoldOut
                                      ? const ColorFilter.mode(
                                          Colors.black45, BlendMode.darken)
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text('₱${item['price']}', style: const TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 4),
                                  Text(item['description'],
                                      style:
                                          const TextStyle(fontSize: 12, color: Colors.white54),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: isSoldOut
                                        ? null
                                        : () => _addToCart(item),
                                    style: ElevatedButton.styleFrom(
  backgroundColor: isSoldOut ? Colors.grey : kAccent,
),
child: Text(
  isSoldOut ? 'Sold Out' : 'Add to Cart',
  style: TextStyle(color: isSoldOut ? Colors.white : Colors.black),
),
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
          // ✅ themed cart drawer (matches app theme)
AnimatedBuilder(
  animation: _cartController,
  builder: (context, child) {
    return FractionalTranslation(
      translation: Offset(1 - _cartController.value, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 300,
          color: kPanel, // <- match your dark panel background
          child: Column(
            children: [
              AppBar(
                backgroundColor: kAccent, // <- your accent color (e.g., gold)
                title: const Text(
                  "Your Cart",
                  style: TextStyle(color: Colors.black),
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: _toggleCart,
                  ),
                ],
              ),
              Expanded(
                child: _cart.isEmpty
                    ? const Center(
                        child: Text(
                          'Cart is empty',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return ListTile(
                            title: Text(
                              item['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '₱${item['price']} x ${item['quantity']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove,
                                      color: Colors.white),
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
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      item['quantity'] += 1;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.redAccent),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                        foregroundColor: Colors.white,
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
