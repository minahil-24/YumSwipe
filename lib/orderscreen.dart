import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderScreen extends StatefulWidget {
  final Map<String, dynamic> dishData;

  const OrderScreen({super.key, required this.dishData});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int quantity = 1;
  String address = '';

  @override
  Widget build(BuildContext context) {
    final dish = widget.dishData;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // ✅ Safely parse price as double
    final double price = double.tryParse(dish['price'].toString()) ?? 0;
    final double total = price * quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text('Confirm Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Chef Info
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: NetworkImage(dish['profileImageUrl'] ?? ''),
              ),
              title: Text(
                dish['rname'] ?? 'Chef',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(dish['city'] ?? ''),
            ),

            const SizedBox(height: 10),

            // ✅ Dish Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                dish['url'] ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Dish Name & Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dish['name'] ?? 'Dish',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFF8B0000),
                      ),
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() => quantity--);
                        }
                      },
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF8B0000),
                      ),
                      onPressed: () {
                        setState(() => quantity++);
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ Address Field
            const Text(
              "Delivery Address:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              onChanged: (val) => address = val,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your delivery address',
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Payment Method (Static)
            const Text(
              "Payment Method: Cash on Delivery",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // ✅ Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Price:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rs. ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ✅ Place Order Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (address.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a delivery address."),
                      ),
                    );
                    return;
                  }

                  try {
                    // ✅ Get user name
                    final userDoc =
                        await FirebaseFirestore.instance
                            .collection('user')
                            .doc(userId)
                            .get();

                    final userName = userDoc['username'] ?? 'User';

                    // ✅ Add to chef's 'orders' subcollection
                    await FirebaseFirestore.instance
                        .collection('users') // assuming chefs are in 'users'
                        .doc(dish['chefId'])
                        .collection('orders')
                        .add({
                          'dishName': dish['name'],
                          'dishImage': dish['url'],
                          'price': price,
                          'quantity': quantity,
                          'total': total,
                          'paymentMethod': 'Cash on Delivery',
                          'address': address,
                          'chefId': dish['chefId'],
                          'orderedAt': Timestamp.now(),
                          'userId': userId,
                          'userName': userName,
                        });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Order placed successfully!"),
                        backgroundColor: Color(0xFF8B0000),
                      ),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    // ✅ Print error in terminal
                    print("❌ Error placing order: $e");

                    // ✅ Show user a friendly message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Something went wrong while placing the order.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  "Place Order",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
