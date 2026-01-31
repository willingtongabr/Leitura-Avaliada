import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/star_rating.dart';

class EditReviewScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentReview;

  const EditReviewScreen({
    super.key,
    required this.docId,
    required this.currentReview,
  });

  @override
  State<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reviewController;
  late TextEditingController _titleController;
  int _rating = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController(text: widget.currentReview['review']);
    _titleController = TextEditingController(text: widget.currentReview['title']);
    _rating = widget.currentReview['rating'] ?? 0;
  }

  Future<void> _saveReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.docId)
          .update({
        'review': _reviewController.text.trim(),
        'rating': _rating,  
        'editedAt': Timestamp.now(),
      });

      Navigator.pop(context); // Go back after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar a resenha.')),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Resenha'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title: read-only
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                readOnly: true,
              ),
              const SizedBox(height: 12),

              // Review: editable
              TextFormField(
                controller: _reviewController,
                decoration: const InputDecoration(labelText: 'Resenha'),
                maxLines: 5,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Insira sua resenha' : null,
              ),
              const SizedBox(height: 12),

            StarRating(
              rating: _rating,
              onRatingChanged: (newRating) {
                setState(() {
                  _rating = newRating;
                });
              },
            ),


              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar Alterações'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
