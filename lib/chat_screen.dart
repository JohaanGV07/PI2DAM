// lib/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId; // ID de la sala
  final String currentUsername; // Quién está usando la pantalla

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.currentUsername,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    _chatService.sendMessage(
      widget.roomId,
      widget.currentUsername,
      _messageController.text,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Soporte al Cliente"),
      ),
      body: Column(
        children: [
          // 1. Lista de Mensajes (en tiempo real)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Inicia la conversación"));
                }
                
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Para que el chat empiece desde abajo
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['sender_username'] == widget.currentUsername;

                    return _buildMessageBubble(
                      msg['text'] ?? '',
                      msg['sender_username'] ?? '?',
                      isMe,
                    );
                  },
                );
              },
            ),
          ),
          // 2. Campo de texto para enviar
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Widget para la burbuja de chat
  Widget _buildMessageBubble(String text, String sender, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[100] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                sender, // Mostramos quién lo envía
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para la barra de enviar mensaje
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Escribe tu mensaje...",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}