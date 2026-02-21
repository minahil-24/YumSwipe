import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChefOrdersScreen extends StatefulWidget {
  final String chefId;
  const ChefOrdersScreen({super.key, required this.chefId});

  @override
  State<ChefOrdersScreen> createState() => _ChefOrdersScreenState();
}

class _ChefOrdersScreenState extends State<ChefOrdersScreen> {
  List<DocumentSnapshot> chefOrders = [];
  bool loading = true;

  final Color deepRed = const Color(0xFF8B0000);
  final Color green = Colors.green.shade600;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(
                'users',
              ) // collection name (not 'users' in your structure)
              .doc(widget.chefId)
              .collection('orders')
              .orderBy('orderedAt', descending: true)
              .get();

      setState(() {
        chefOrders = snapshot.docs;
        loading = false;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() => loading = false);
    }
  }

  Future<void> markOrderComplete(String orderId) async {
    await FirebaseFirestore.instance
        .collection('users') // your Firestore collection
        .doc(widget.chefId)
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Completed'});

    fetchOrders(); // Refresh the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chef Orders'),
        backgroundColor: deepRed,
        foregroundColor: Colors.white,
      ),
      body:
          loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
              : chefOrders.isEmpty
              ? const Center(child: Text("No orders found."))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: chefOrders.length,
                itemBuilder: (context, index) {
                  final data = chefOrders[index].data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Pending';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dish Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              data['dishImage'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['dishName'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("User: ${data['userName']}"),
                          Text("Address: ${data['address']}"),
                          Text("Payment: ${data['paymentMethod']}"),
                          Text("Quantity: ${data['quantity']}"),
                          Text("Total: Rs. ${data['total']}"),
                          const SizedBox(height: 8),

                          // Status & Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      status == 'Pending'
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color:
                                        status == 'Pending'
                                            ? Colors.orange
                                            : green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (status == 'Pending')
                                ElevatedButton(
                                  onPressed:
                                      () => markOrderComplete(
                                        chefOrders[index].id,
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: green,
                                  ),
                                  child: const Text("Mark Complete"),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
