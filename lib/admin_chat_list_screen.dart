// lib/admin_chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/chat_service.dart';
import 'package:flutter_firestore_login/chat_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  final String adminUsername;
  const AdminChatListScreen({super.key, required this.adminUsername});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats de Clientes"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getChatRoomsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay chats activos."));
          }

          final rooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final roomData = rooms[index].data() as Map<String, dynamic>;
              final roomId = rooms[index].id;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text("Chat con: ${roomData['client_username']}"),
                  subtitle: Text(roomData['last_message'] ?? '', maxLines: 1),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          roomId: roomId,
                          currentUsername: adminUsername,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}