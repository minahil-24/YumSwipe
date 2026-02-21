import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String address = '';
  final userId = FirebaseAuth.instance.currentUser!.uid;
  String paymentMethod = 'COD';
  final Map<String, VideoPlayerController> _videoControllers = {};

  bool isVideo(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.webm') ||
        url.endsWith('.avi') ||
        url.endsWith('.mkv');
  }

  void updateQuantity(String dishId, int newQty) async {
    final cartDoc = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('cart')
        .doc(dishId);

    if (newQty > 0) {
      await cartDoc.update({'quantity': newQty});
    } else {
      await cartDoc.delete();
    }
  }

  double calculateTotal(List<QueryDocumentSnapshot> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      final data = item.data() as Map<String, dynamic>;
      final price = double.tryParse(data['price'].toString()) ?? 0;
      final qty = data['quantity'] ?? 1;
      total += price * qty;
    }
    return total;
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('user')
                .doc(userId)
                .collection('cart')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final cartItems = snapshot.data!.docs;

          if (cartItems.isEmpty) {
            return const Center(child: Text("No items in cart."));
          }

          final total = calculateTotal(cartItems);

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 150),
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final data =
                        cartItems[index].data() as Map<String, dynamic>;
                    final dishId = cartItems[index].id;
                    final mediaUrl = data['imageUrl'] ?? '';

                    if (isVideo(mediaUrl) &&
                        !_videoControllers.containsKey(dishId)) {
                      final controller = VideoPlayerController.network(mediaUrl)
                        ..initialize().then((_) => setState(() {}));
                      _videoControllers[dishId] = controller;
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    isVideo(mediaUrl)
                                        ? GestureDetector(
                                          onTap: () {
                                            final controller =
                                                _videoControllers[dishId]!;
                                            if (controller.value.isPlaying) {
                                              controller.pause();
                                            } else {
                                              controller.play();
                                            }
                                            setState(() {});
                                          },
                                          child:
                                              _videoControllers[dishId]!
                                                      .value
                                                      .isInitialized
                                                  ? SizedBox(
                                                    width: 80,
                                                    height: 80,
                                                    child: AspectRatio(
                                                      aspectRatio:
                                                          _videoControllers[dishId]!
                                                              .value
                                                              .aspectRatio,
                                                      child: VideoPlayer(
                                                        _videoControllers[dishId]!,
                                                      ),
                                                    ),
                                                  )
                                                  : const SizedBox(
                                                    width: 80,
                                                    height: 80,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                        )
                                        : Image.network(
                                          mediaUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['dishName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8B0000),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Rs. ${data['price']}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Color(0xFF8B0000),
                                          ),
                                          onPressed:
                                              () => updateQuantity(
                                                dishId,
                                                data['quantity'] - 1,
                                              ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder:
                                              (child, animation) =>
                                                  ScaleTransition(
                                                    scale: animation,
                                                    child: child,
                                                  ),
                                          child: Text(
                                            '${data['quantity']}',
                                            key: ValueKey(data['quantity']),
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Color(0xFF8B0000),
                                          ),
                                          onPressed:
                                              () => updateQuantity(
                                                dishId,
                                                data['quantity'] + 1,
                                              ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.grey,
                                          ),
                                          onPressed:
                                              () => updateQuantity(dishId, 0),
                                        ),
                                      ],
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
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 20,
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          maxLines: 2,
                          onChanged: (val) => address = val,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Delivery Address',
                            hintText: 'Enter delivery address',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              "Total:",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Rs. ${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF8B0000),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Icon(
                              Icons.payments_outlined,
                              color: Color(0xFF8B0000),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Payment Method: Cash on Delivery",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text("Place Order"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (address.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please enter delivery address.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              final cartItems =
                                  await FirebaseFirestore.instance
                                      .collection('user')
                                      .doc(userId)
                                      .collection('cart')
                                      .get();

                              final userDoc =
                                  await FirebaseFirestore.instance
                                      .collection('user')
                                      .doc(userId)
                                      .get();
                              final userName =
                                  userDoc.data()?['name'] ?? 'User';

                              for (var item in cartItems.docs) {
                                final data = item.data();
                                final price =
                                    double.tryParse(data['price'].toString()) ??
                                    0;
                                final qty = data['quantity'] ?? 1;
                                final total = price * qty;

                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .add({
                                      'dishName': data['dishName'],
                                      'dishImage': data['imageUrl'],
                                      'price': price,
                                      'quantity': qty,
                                      'total': total,
                                      'paymentMethod': 'Cash on Delivery',
                                      'address': address,
                                      'chefId': data['chefId'],
                                      'orderedAt': Timestamp.now(),
                                      'userId': userId,
                                      'userName': userName,
                                    });
                              }

                              for (var item in cartItems.docs) {
                                await item.reference.delete();
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Order placed successfully!"),
                                  backgroundColor: Color(0xFF8B0000),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to place order: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
