// lib/shared/widgets/add_review_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_firestore_login/core/services/review_service.dart';

class AddReviewDialog extends StatefulWidget {
  final String productId;
  final String username;

  const AddReviewDialog({
    super.key,
    required this.productId,
    required this.username,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 3.0; // Valoración inicial
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _reviewService.addReview(
        productId: widget.productId,
        username: widget.username,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reseña enviada ¡Gracias!"))
        );
        Navigator.pop(context); // Cierra el diálogo
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Valora este producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selector de Estrellas
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 15),
            // Campo de Comentario
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: "Escribe tu reseña (opcional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitReview,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Enviar'),
        ),
      ],
    );
  }
}