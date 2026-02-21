import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatScreen.dart';

class UChatListScreen extends StatelessWidget {
  final String currentUserId;

  const UChatListScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B0000),
        elevation: 3,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('users', arrayContains: currentUserId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet. Start a conversation!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final users = List<String>.from(chat['users'] ?? []);
              final otherId = users.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (otherId.isEmpty) return const SizedBox();

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherId)
                        .get(),
                builder: (context, chefSnap) {
                  if (chefSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text("Loading..."),
                    );
                  }

                  if (chefSnap.hasData && chefSnap.data!.exists) {
                    final chef = chefSnap.data!;
                    return _buildChatTile(context, chef, chat, otherId);
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('user')
                            .doc(otherId)
                            .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData || !userSnap.data!.exists) {
                        return const SizedBox();
                      }
                      final user = userSnap.data!;
                      return _buildChatTile(context, user, chat, otherId);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    DocumentSnapshot user,
    QueryDocumentSnapshot chat,
    String otherId,
  ) {
    final profileUrl = user['profileImageUrl'] ?? '';
    final name = user['rname'] ?? user['name'] ?? 'User';
    final lastMessage = chat['lastMessage'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ChatScreen(
                  currentUserId: currentUserId,
                  receiverId: otherId,
                  receiverName: name,
                  receiverImage: profileUrl,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(profileUrl),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
