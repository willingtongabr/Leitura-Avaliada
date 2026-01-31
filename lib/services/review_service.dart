import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static Future<List<dynamic>?> searchBooks(BuildContext context, String query) async {
    final url = Uri.parse('https://openlibrary.org/search.json?q=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['docs'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao buscar livros')),
      );
      return null;
    }
  }

  static Future<bool> saveReview({
    required BuildContext context,
    required User user,
    required dynamic book,
    required String summary,
    required String review,
    required int rating,
  }) async {
    if (book == null || review.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro ou resenha inválidos')),
      );
      return false;
    }

    final title = book['title'] ?? 'Título desconhecido';
    final author = (book['author_name'] as List?)?.join(', ') ?? 'Autor desconhecido';
    final coverId = book['cover_i'];
    final coverUrl = coverId != null ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg' : '';
    final openLibraryId = book['key'];

    await FirebaseFirestore.instance.collection('reviews').add({
      'userId': user.uid,
      'bookId': openLibraryId,
      'title': title,
      'title_lowercase': title.toLowerCase(),
      'author': author,
      'coverUrl': coverUrl,
      'summary': summary.trim(),
      'review': review.trim(),
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0, 
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resenha salva com sucesso!')),
    );
    return true;
  }
}
