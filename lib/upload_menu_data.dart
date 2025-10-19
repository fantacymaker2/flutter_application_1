import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDvG7XOkScfjB-vaY8Zz9nnBl2qhBVcrxQ",
      authDomain: "grace-burger-47413.firebaseapp.com",
      projectId: "grace-burger-47413",
      storageBucket: "grace-burger-47413.firebasestorage.app",
      messagingSenderId: "954033012645",
      appId: "1:954033012645:web:a367649f22fc86da45724c",
      measurementId: "G-FRESJT7TDM"
    ),
  );
  final firestore = FirebaseFirestore.instance;

  final menuData = {
    'Burgers': [
      { 'id': 1, 'name': 'CDO Burger', 'price': 27, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Classic burger with our signature patty', 'ingredients': ['Patty', 'Bun'] },
      { 'id': 2, 'name': 'Burger with Ham', 'price': 36, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Juicy burger topped with savory ham', 'ingredients': ['Patty', 'Ham', 'Bun'] },
      { 'id': 3, 'name': 'Burger with Egg', 'price': 37, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Burger with a perfectly fried egg', 'ingredients': ['Patty', 'Egg', 'Bun'] },
      { 'id': 4, 'name': 'Burger with Bacon', 'price': 42, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Crispy bacon makes this burger special', 'ingredients': ['Patty', 'Bacon', 'Bun'] },
      { 'id': 5, 'name': 'Cheese Burger', 'price': 35, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Melted cheese perfection', 'ingredients': ['Patty', 'Cheese', 'Bun'] },
      { 'id': 6, 'name': 'Cheese Burger with Ham', 'price': 41, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Cheese and ham combo', 'ingredients': ['Patty', 'Cheese', 'Ham', 'Bun'] },
      { 'id': 7, 'name': 'Cheese Burger with Egg', 'price': 43, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Cheese and egg delight', 'ingredients': ['Patty', 'Cheese', 'Egg', 'Bun'] },
      { 'id': 8, 'name': 'Cheese Burger with Bacon', 'price': 47, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Triple threat: cheese, bacon, and patty', 'ingredients': ['Patty', 'Cheese', 'Bacon', 'Bun'] },
      { 'id': 9, 'name': 'Ham Burger', 'price': 29, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Simple and delicious ham burger', 'ingredients': ['Ham', 'Bun'] },
      { 'id': 10, 'name': 'Ham Burger with Cheese', 'price': 36, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Ham and cheese classic', 'ingredients': ['Ham', 'Cheese', 'Bun'] },
      { 'id': 11, 'name': 'Ham Burger with Egg', 'price': 34, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Ham and egg breakfast style', 'ingredients': ['Ham', 'Egg', 'Bun'] },
      { 'id': 12, 'name': 'Hamburger With Cheese and Egg', 'price': 48, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Loaded with ham, cheese, and egg', 'ingredients': ['Ham', 'Cheese', 'Egg', 'Bun'] },
      { 'id': 13, 'name': 'Burger Bacon Ham', 'price': 52, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Bacon and ham power combo', 'ingredients': ['Patty', 'Bacon', 'Ham', 'Bun'] },
      { 'id': 24, 'name': 'Complete', 'price': 64, 'category': 'Burgers', 'emoji': '🍔', 'tag': 'SIGNATURE', 'description': 'Our signature burger with everything!', 'ingredients': ['Patty', 'Cheese', 'Ham', 'Egg', 'Bun'] },
      { 'id': 25, 'name': 'Complete change Bacon', 'price': 62, 'category': 'Burgers', 'emoji': '🍔', 'description': 'Complete burger, bacon style', 'ingredients': ['Patty', 'Cheese', 'Bacon', 'Egg', 'Bun'] },
      { 'id': 26, 'name': 'Complete with Bacon', 'price': 67, 'category': 'Burgers', 'emoji': '🍔', 'description': 'The ultimate burger experience', 'ingredients': ['Patty', 'Cheese', 'Ham', 'Bacon', 'Egg', 'Bun'] },
    ],
    'Sandwiches': [
      { 'id': 14, 'name': 'Egg Cheese', 'price': 38, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Egg and cheese sandwich', 'ingredients': ['Egg', 'Cheese', 'Bun'] },
      { 'id': 15, 'name': 'Egg Sandwich', 'price': 30, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Simple egg sandwich', 'ingredients': ['Egg', 'Bun'] },
      { 'id': 16, 'name': 'Bacon Sandwich', 'price': 40, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Crispy bacon sandwich', 'ingredients': ['Bacon', 'Bun'] },
      { 'id': 19, 'name': 'Bacon with Ham', 'price': 48, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Bacon and ham combo', 'ingredients': ['Bacon', 'Ham', 'Bun'] },
      { 'id': 20, 'name': 'Bacon with Egg', 'price': 49, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Bacon and egg classic', 'ingredients': ['Bacon', 'Egg', 'Bun'] },
      { 'id': 21, 'name': 'Bacon with Cheese', 'price': 51, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Bacon and cheese delight', 'ingredients': ['Bacon', 'Cheese', 'Bun'] },
      { 'id': 22, 'name': 'Bacon Cheese with Ham', 'price': 52, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Loaded bacon sandwich', 'ingredients': ['Bacon', 'Cheese', 'Ham', 'Bun'] },
      { 'id': 23, 'name': 'Bacon Cheese With Egg', 'price': 54, 'category': 'Sandwiches', 'emoji': '🥪', 'description': 'Bacon, cheese, and egg combo', 'ingredients': ['Bacon', 'Cheese', 'Egg', 'Bun'] },
    ],
    'Hot Dogs': [
      { 'id': 27, 'name': '1/2 Long', 'price': 30, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Half-size hot dog', 'ingredients': ['Hotdog', 'Bun'] },
      { 'id': 28, 'name': '1/2 Long Cheese', 'price': 37, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Half-size with cheese', 'ingredients': ['Hotdog', 'Cheese', 'Bun'] },
      { 'id': 29, 'name': '1/2 Long Bacon', 'price': 43, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Half-size with bacon', 'ingredients': ['Hotdog', 'Bacon', 'Bun'] },
      { 'id': 30, 'name': '1/2 Long Ham', 'price': 42, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Half-size with ham', 'ingredients': ['Hotdog', 'Ham', 'Bun'] },
      { 'id': 31, 'name': '1/2 Long Egg', 'price': 44, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Half-size with egg', 'ingredients': ['Hotdog', 'Egg', 'Bun'] },
      { 'id': 32, 'name': '1/2 Long Bacon Cheese', 'price': 53, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Half-size loaded', 'ingredients': ['Hotdog', 'Bacon', 'Cheese', 'Bun'] },
      { 'id': 33, 'name': 'Footlong', 'price': 47, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Full-size hot dog', 'ingredients': ['Footlong', 'Bun'] },
      { 'id': 34, 'name': 'Footlong Ham', 'price': 53, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Footlong with ham', 'ingredients': ['Footlong', 'Ham', 'Bun'] },
      { 'id': 35, 'name': 'Footlong Egg Cheese', 'price': 58, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Footlong with egg and cheese', 'ingredients': ['Footlong', 'Egg', 'Cheese', 'Bun'] },
      { 'id': 36, 'name': 'Footlong Cheese', 'price': 56, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Footlong with cheese', 'ingredients': ['Footlong', 'Cheese', 'Bun'] },
      { 'id': 37, 'name': 'Footlong Bacon', 'price': 64, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Footlong with bacon', 'ingredients': ['Footlong', 'Bacon', 'Bun'] },
      { 'id': 38, 'name': 'Footlong Cheese with Bacon', 'price': 77, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Ultimate footlong', 'ingredients': ['Footlong', 'Cheese', 'Bacon', 'Bun'] },
      { 'id': 39, 'name': 'Footlong Ham with Bacon', 'price': 77, 'category': 'Hot Dogs', 'emoji': '🌭', 'description': 'Footlong ham and bacon', 'ingredients': ['Footlong', 'Ham', 'Bacon', 'Bun'] },
    ],
    'Rice Meals': [
      { 'id': 40, 'name': 'Siomai Rice', 'price': 40, 'category': 'Rice Meals', 'emoji': '🍚', 'description': 'Siomai with steamed rice', 'ingredients': ['Siomai', 'Rice'] },
      { 'id': 41, 'name': 'Ham Rice', 'price': 25, 'category': 'Rice Meals', 'emoji': '🍚', 'description': 'Ham with steamed rice', 'ingredients': ['Ham', 'Rice'] },
      { 'id': 42, 'name': 'Egg Rice', 'price': 30, 'category': 'Rice Meals', 'emoji': '🍚', 'description': 'Egg with steamed rice', 'ingredients': ['Egg', 'Rice'] },
      { 'id': 43, 'name': 'Hotdog Rice', 'price': 35, 'category': 'Rice Meals', 'emoji': '🍚', 'description': 'Hotdog with steamed rice', 'ingredients': ['Hotdog', 'Rice'] },
    ],
    'Sides': [
      { 'id': 17, 'name': '4-pcs Grace Pork Siomai', 'price': 25, 'category': 'Sides', 'emoji': '🥟', 'description': 'Four pieces of pork siomai', 'ingredients': ['Siomai'] },
      { 'id': 18, 'name': 'Patty', 'price': 15, 'category': 'Sides', 'emoji': '🥩', 'description': 'Single burger patty', 'ingredients': ['Patty'] },
      { 'id': 44, 'name': 'Ham', 'price': 12, 'category': 'Sides', 'emoji': '🥓', 'description': 'Sliced ham', 'ingredients': ['Ham'] },
    ],
    'Beverages': [
      { 'id': 45, 'name': 'Mountain Dew', 'price': 25, 'category': 'Beverages', 'emoji': '🥤', 'description': 'Refreshing citrus soda', 'ingredients': ['Softdrinks'] },
      { 'id': 46, 'name': 'Pepsi', 'price': 15, 'category': 'Beverages', 'emoji': '🥤', 'description': 'Classic cola', 'ingredients': ['Softdrinks'] },
      { 'id': 47, 'name': 'Rootbeer', 'price': 15, 'category': 'Beverages', 'emoji': '🥤', 'description': 'Smooth rootbeer', 'ingredients': ['Softdrinks'] },
    ],
  };

  for (final category in menuData.keys) {
    final items = menuData[category] as List;
    for (final item in items) {
      await firestore.collection('menu').doc(category).collection('items').add(item);
      print('✅ Added ${item['name']} under $category');
    }
  }

  print('🎉 All menu data uploaded successfully!');
}
