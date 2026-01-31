import 'package:flutter/material.dart';

class BookListTile extends StatelessWidget {
  final dynamic book;
  final VoidCallback onTap;

  const BookListTile({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = book['title'] ?? 'Sem título';
    final author = (book['author_name'] as List?)?.join(', ') ?? 'Autor desconhecido';
    final coverId = book['cover_i'];
    final coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-S.jpg'
        : null;

    return ListTile(
      leading: coverUrl != null
          ? Image.network(coverUrl, width: 50, height: 75, fit: BoxFit.cover)
          : const Icon(Icons.book),
      title: Text(title),
      subtitle: Text(author),
      onTap: onTap,
    );
  }
}
