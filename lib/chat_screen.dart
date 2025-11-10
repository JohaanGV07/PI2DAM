// lib/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firestore_login/core/services/chat_service.dart';
// (Ya no se importa 'emoji_picker_flutter' ni 'dart:io')

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String currentUsername;

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

  bool _isLoadingUserData = true; // Para la carga de fotos
  Map<String, String> _userImageUrls = {}; // Mapa para guardar las URLs

  @override
  void initState() {
    super.initState();
    _loadParticipantData(); // Cargamos las fotos de perfil al iniciar
  }

  // --- Función: Cargar Fotos de Perfil ---
  Future<void> _loadParticipantData() async {
    try {
      // 1. Obtenemos los nombres de la sala
      final roomDoc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .get();
      final roomData = roomDoc.data();
      if (roomData == null) return;

      final clientUsername = roomData['client_username'];
      final adminUsername = roomData['admin_username'];

      // 2. Buscamos las URLs de ambos usuarios en la colección 'users'
      final clientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: clientUsername)
          .limit(1)
          .get();

      final adminQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: adminUsername)
          .limit(1)
          .get();

      // 3. Guardamos las URLs en el estado
      if (clientQuery.docs.isNotEmpty) {
        _userImageUrls[clientUsername] =
            clientQuery.docs.first.data()['imageURL'];
      }
      if (adminQuery.docs.isNotEmpty) {
        _userImageUrls[adminUsername] =
            adminQuery.docs.first.data()['imageURL'];
      }

      setState(() {
        _isLoadingUserData = false;
      });
    } catch (e) {
      print("Error cargando datos de participantes: $e");
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
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
          // 1. Lista de Mensajes
          Expanded(
            child: _isLoadingUserData
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
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
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index].data() as Map<String, dynamic>;
                          final senderUsername = msg['sender_username'] ?? '?';
                          final isMe = senderUsername == widget.currentUsername;
                          
                          // Buscamos la URL de la foto de perfil
                          final imageUrl = _userImageUrls[senderUsername] ?? 
                                           'https://www.shutterstock.com/image-vector/default-avatar-profile-icon-vector-600nw-1725655669.jpg';

                          return _buildMessageBubble(
                            msg['text'] ?? '',
                            senderUsername,
                            imageUrl, // <-- Pasamos la URL
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

  // --- Widget _buildMessageBubble (Modificado con Foto) ---
  Widget _buildMessageBubble(String text, String sender, String imageUrl, bool isMe) {
    final bubble = Container(
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
            sender,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) // Si no soy yo, foto a la izquierda
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              radius: 12,
            ),
          ),
        
        Flexible(child: bubble), // Flexible para que la burbuja se ajuste
        
        if (isMe) // Si soy yo, foto a la derecha
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              radius: 12,
            ),
          ),
      ],
    );
  }

  // --- Widget _buildMessageInput (Versión simple SIN emojis) ---
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