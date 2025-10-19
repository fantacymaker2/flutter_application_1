import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'about_us_page.dart';
import 'cart_manager.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> categories = ['Burger', 'Sandwiches', 'Hotdogs', 'Ricemeals', 'Drinks', 'Others'];

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> categorizedItems = {};
  bool _loading = true;

  // Cart manager instance
  final cart = CartManager();
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _fetchAllMenuItems();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _fetchAllMenuItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('menu')
        .orderBy('createdAt', descending: true)
        .get();

    Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> temp = {};
    for (var cat in categories) {
      temp[cat] = [];
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final cat = (data['category'] ?? '').toString().toLowerCase();
      final match = categories.firstWhere(
        (c) => c.toLowerCase() == cat,
        orElse: () => 'others',
      );
      temp[match]!.add(doc);
    }

    setState(() {
      categorizedItems = temp;
      _loading = false;
    });
  }

  Widget _buildGrid(List<QueryDocumentSnapshot<Map<String, dynamic>>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final data = items[index].data();
        final name = (data['name'] ?? 'No name').toString();
        final price = (data['price'] ?? 0).toString();
        final imageUrl = (data['imageUrl'] ?? '').toString();

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.broken_image, size: 50)),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image, size: 50)),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱$price',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        print('Cart before add: ${cart.items.length}');
                        cart.addToCart(items[index]);
                         print('Cart after add: ${cart.items.length}');
                        setState(() {
                          _cartCount = cart.items.length; // ✅ update count
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$name added to cart!')),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.email ?? 'User'}'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () async {
                  print('Cart instance: $cart');
  print('Cart items length: ${cart.items.length}');
                  // ✅ Navigate to CartPage and update count when returning
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(cart: cart),
                    ),
                  );
                  setState(() {
                    _cartCount = cart.items.length; // refresh cart count
                  });
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: categories.map((cat) => Tab(text: cat)).toList(),
        ),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.email?.split('@').first ?? 'User'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: categories.map((cat) {
          final items = categorizedItems[cat] ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No items found'));
          }
          return _buildGrid(items);
        }).toList(),
      ),
    );
  }
}
