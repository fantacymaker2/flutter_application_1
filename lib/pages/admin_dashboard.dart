import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'orders_page.dart';
import 'inventory_page.dart';
import 'analytics_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final _pages = [
    OrdersPage(),
    InventoryPage(),
    AnalyticsPage(),
  ];

  final _pageTitles = [
    'Orders',
    'Inventory',
    'Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            "🍔 GRACE BURGER",
            style: TextStyle(
              color: Color(0xFFD4A027),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          for (int i = 0; i < _pageTitles.length; i++)
            _buildNavItem(_pageTitles[i], i),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              await FirebaseFirestore.instance.terminate();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, int index) {
    final bool selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        index == 0
            ? Icons.receipt_long
            : index == 1
                ? Icons.inventory
                : Icons.bar_chart,
        color: selected ? Colors.black : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      tileColor: selected ? const Color(0xFFD4A027) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}

