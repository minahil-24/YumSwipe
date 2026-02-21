// AdminPanel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String selectedUserType = 'All';
  final List<String> userTypes = ['All', 'Chef', 'User', 'Admin'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Dishes'),
              Tab(text: 'Orders'),
              Tab(text: 'Chats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildDishesTab(),
            _buildOrdersTab(),
            _buildChatsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        DropdownButton<String>(
          value: selectedUserType,
          items:
              userTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => selectedUserType = value!),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getUserStream(selectedUserType),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs =
                  snapshot.data!.docs.where((doc) {
                    if (selectedUserType == 'All') return true;
                    return (doc['type'] ?? '') == selectedUserType;
                  }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final user = docs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        user['profileImageUrl'] ?? '',
                      ),
                    ),
                    title: Text(user['email'] ?? 'No Email'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'Promote') {
                          await user.reference.update({'type': 'Admin'});
                        } else if (value == 'Delete') {
                          await user.reference.delete();
                        }
                      },
                      itemBuilder:
                          (_) => [
                            const PopupMenuItem(
                              value: 'Promote',
                              child: Text('Promote to Admin'),
                            ),
                            const PopupMenuItem(
                              value: 'Delete',
                              child: Text('Delete User'),
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
    );
  }

  Stream<QuerySnapshot> _getUserStream(String selectedType) {
    if (selectedType == 'User') {
      return FirebaseFirestore.instance.collection('user').snapshots();
    } else {
      return FirebaseFirestore.instance.collection('users').snapshots();
    }
  }

  Widget _buildDishesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('dishes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final dishes = snapshot.data!.docs;
        return ListView.builder(
          itemCount: dishes.length,
          itemBuilder: (context, index) {
            final dish = dishes[index];
            return ListTile(
              leading: Image.network(
                dish['url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              title: Text(dish['name'] ?? 'No Name'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => dish.reference.delete(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return ListTile(title: Text(order['dishName'] ?? 'No Dish'));
          },
        );
      },
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final chats = snapshot.data!.docs;
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final users = List<String>.from(chat['users']);
            return ListTile(
              title: Text('Chat: ${users.join(" & ")}'),
              subtitle: Text('Chat ID: ${chat.id}'),
            );
          },
        );
      },
    );
  }
}
