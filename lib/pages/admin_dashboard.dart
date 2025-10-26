import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orders_page.dart';
import 'inventory_page.dart';
import 'returns_page.dart';
import 'analytics_page.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  final List<Widget> _pages = const [
    OrdersPage(),
    InventoryPage(),
    ReturnsPage(),
    AnalyticsPage(),
  ];

  final List<String> _pageTitles = [
    'Orders',
    'Inventory',
    'Return Request',
    'Analytics',
  ];

  final List<IconData> _pageIcons = [
    Icons.receipt_long,
    Icons.inventory,
    Icons.assignment_return,
    Icons.bar_chart,
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ prevent invalid index access (main cause of Symbol(dartx._get) error)
    final safeIndex =
        (_selectedIndex >= 0 && _selectedIndex < _pages.length) ? _selectedIndex : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
  children: [
    // ====== MAIN CONTENT ======
    Column(
      children: [
        // Top bar with hamburger menu
        Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  setState(() => _isSidebarOpen = true);
                },
              ),
              const SizedBox(width: 8),
              Text(
                _pageTitles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _pages[_selectedIndex],
          ),
        ),
      ],
    ),

    // ====== BACKDROP (tap to close) BELOW SIDEBAR ======
    if (_isSidebarOpen)
      GestureDetector(
        onTap: () => setState(() => _isSidebarOpen = false),
        child: AnimatedOpacity(
          opacity: _isSidebarOpen ? 0.4 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(color: Colors.black),
        ),
      ),

    // ====== COLLAPSIBLE SIDEBAR (always on top) ======
    AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: 0,
      bottom: 0,
      left: _isSidebarOpen ? 0 : -250,
      child: Container(
        width: 250,
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    "🍔 GRACE BURGER",
                    style: TextStyle(
                      color: Color(0xFFD4A027),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() => _isSidebarOpen = false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Navigation
            for (int i = 0; i < _pageTitles.length; i++)
              _buildNavItem(_pageTitles[i], _pageIcons[i], i),

            const Spacer(),

            // Logout button
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: InkWell(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    final bool selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.black : Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      tileColor: selected ? const Color(0xFFD4A027) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        if (index < _pages.length) {
          setState(() {
            _selectedIndex = index;
            _isSidebarOpen = false; // close after select
          });
        }
      },
    );
  }
}
