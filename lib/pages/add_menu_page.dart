import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _loading = false;

  Uint8List? _imageBytes;
  String? _uploadedImageUrl;

  // ✅ Dropdown category list
  final List<String> _categories = [
    'Burger',
    'Sandwiches',
    'Hotdogs',
    'Ricemeals',
    'Drinks',
    'Others',
  ];

  String? _selectedCategory;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImage(Uint8List bytes) async {
    const cloudName = 'dlw9ywu22';
    const uploadPreset = 'o0ppripn';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'menu_image.jpg',
        ),
      );

    final response = await request.send();
    final resStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resStr);
      return data['secure_url'];
    } else {
      print('Upload failed: $resStr');
      return null;
    }
  }

  Future<void> _addMenu() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty || price == null || _selectedCategory == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and select an image')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await _uploadImage(_imageBytes!);
      if (imageUrl == null) throw Exception('Image upload failed');

      await FirebaseFirestore.instance.collection('menu').add({
        'name': name,
        'price': price,
        'category': _selectedCategory!.toLowerCase(), // ✅ stored as lowercase for consistency
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _uploadedImageUrl = null;
        _imageBytes = null;
        _nameController.clear();
        _priceController.clear();
        _selectedCategory = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu item added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Menu Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // ✅ Dropdown for category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) => value == null ? 'Please select a category' : null,
            ),

            const SizedBox(height: 12),
            _uploadedImageUrl != null
                ? Image.network(_uploadedImageUrl!, height: 150)
                : _imageBytes != null
                    ? Image.memory(_imageBytes!, height: 150)
                    : const SizedBox(
                        height: 150,
                        child: Center(child: Text('No image selected')),
                      ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _addMenu,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Menu Item'),
            ),
          ],
        ),
      ),
    );
  }
}
