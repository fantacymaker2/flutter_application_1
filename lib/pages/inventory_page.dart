import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // For adding/editing items
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _lowStockController = TextEditingController();

  String? editingItemId;

  Stream<QuerySnapshot> getInventoryStream() {
    return FirebaseFirestore.instance
        .collection('inventory')
        .orderBy('name')
        .snapshots();
  }

  void _showAddOrEditModal({DocumentSnapshot? item}) {
    if (item != null) {
      editingItemId = item.id;
      _nameController.text = item['name'];
      _categoryController.text = item['category'];
      _stockController.text = item['stock'].toString();
      _unitController.text = item['unit'];
      _priceController.text = item['price'].toString();
      _lowStockController.text = item['lowStockThreshold'].toString();
    } else {
      editingItemId = null;
      _nameController.clear();
      _categoryController.clear();
      _stockController.clear();
      _unitController.clear();
      _priceController.clear();
      _lowStockController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          editingItemId == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(color: Color(0xFFD4A027)),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInputField(_nameController, 'Product Name'),
                _buildInputField(_categoryController, 'Category (e.g. INGREDIENTS)'),
                _buildInputField(_stockController, 'Stock', isNumber: true),
                _buildInputField(_unitController, 'Unit (e.g. pcs, strips)'),
                _buildInputField(_priceController, 'Price', isNumber: true),
                _buildInputField(_lowStockController, 'Low Stock Threshold', isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A027),
              foregroundColor: Colors.black,
            ),
            onPressed: _saveItem,
            child: Text(editingItemId == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFD4A027)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final itemData = {
      'name': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'stock': int.tryParse(_stockController.text) ?? 0,
      'unit': _unitController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'lowStockThreshold': int.tryParse(_lowStockController.text) ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance.collection('inventory');
    if (editingItemId == null) {
      await ref.add(itemData);
    } else {
      await ref.doc(editingItemId).update(itemData);
    }

    Navigator.pop(context);
  }

  Future<void> _deleteItem(String id) async {
    await FirebaseFirestore.instance.collection('inventory').doc(id).delete();
  }

  Color _getStockColor(int stock, int lowThreshold) {
    if (stock == 0) return Colors.redAccent;
    if (stock <= lowThreshold) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _getStockStatus(int stock, int lowThreshold) {
    if (stock == 0) return 'OUT OF STOCK';
    if (stock <= lowThreshold) return 'LOW STOCK';
    return 'IN STOCK';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('INVENTORY', style: TextStyle(color: Color(0xFFD4A027))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFD4A027)),
            onPressed: () => _showAddOrEditModal(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getInventoryStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4A027)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No inventory items found.',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final items = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    return name.contains(searchQuery);
                  }).toList();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final data = item.data() as Map<String, dynamic>;
                      final stockColor = _getStockColor(data['stock'], data['lowStockThreshold']);
                      final stockStatus = _getStockStatus(data['stock'], data['lowStockThreshold']);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(color: const Color(0xFF333333)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFFD4A027)),
                                      onPressed: () => _showAddOrEditModal(item: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteItem(item.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              data['category'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PRICE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text('₱${data['price']}',
                                        style: const TextStyle(
                                            color: Color(0xFFD4A027),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('STOCK', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text(
                                      '${data['stock']} ${data['unit']}',
                                      style: TextStyle(
                                          color: stockColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: stockColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  stockStatus,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
