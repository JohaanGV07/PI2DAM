// lib/core/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _roomsRef;

  ChatService() {
    _roomsRef = _firestore.collection('chat_rooms');
  }

  // --- Funciones del Cliente ---

  // Busca una sala para el cliente. Si no existe, la crea.
  Future<String> getOrCreateChatRoom(String clientUsername) async {
    final query = await _roomsRef
        .where('client_username', isEqualTo: clientUsername)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Si la sala ya existe, devuelve su ID
      return query.docs.first.id;
    } else {
      // Si no existe, crea una nueva sala
      final newRoom = await _roomsRef.add({
        'client_username': clientUsername,
        'admin_username': 'johan', // Admin por defecto
        'last_message': 'Chat iniciado',
        'last_message_at': FieldValue.serverTimestamp(),
      });
      return newRoom.id;
    }
  }

  // --- Funciones del Admin ---

  // Obtener todas las salas de chat (para el panel de admin)
  Stream<QuerySnapshot> getChatRoomsStream() {
    return _roomsRef
        .orderBy('last_message_at', descending: true)
        .snapshots();
  }

  // --- Funciones Comunes ---

  // Enviar un mensaje
  Future<void> sendMessage(String roomId, String senderUsername, String text) async {
    if (text.trim().isEmpty) return;

    final messagesRef = _roomsRef.doc(roomId).collection('messages');
    final timestamp = FieldValue.serverTimestamp();

    await messagesRef.add({
      'sender_username': senderUsername,
      'text': text,
      'timestamp': timestamp,
    });

    // Actualizar el último mensaje en la sala principal (para la vista previa)
    await _roomsRef.doc(roomId).update({
      'last_message': text,
      'last_message_at': timestamp,
    });
  }

  // Obtener el stream de mensajes de una sala específica
  Stream<QuerySnapshot> getMessagesStream(String roomId) {
    return _roomsRef
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Mensajes más nuevos abajo
        .snapshots();
  }
}