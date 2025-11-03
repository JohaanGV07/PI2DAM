// lib/core/models/user_model.dart

class UserModel {
  // Campos del usuario en Firestore
  final String uid;
  final String username;
  final String email;
  final String rol; // 'admin' o 'user'
  final String imageURL;

  // Constructor
  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.rol,
    required this.imageURL,
  });

  // Método de fábrica para crear un UserModel a partir de un mapa de Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'user', // Por defecto, si no existe el campo, es 'user'
      imageURL: data['imageURL'] ?? 'https://picsum.photos/200/200',
    );
  }

  // Método para convertir el modelo a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'rol': rol,
      'imageURL': imageURL,
    };
  }

  // Método de copia para facilitar la actualización de campos
  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? rol,
    String? imageURL,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      imageURL: imageURL ?? this.imageURL,
    );
  }
}