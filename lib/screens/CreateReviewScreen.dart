import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/review_service.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/star_rating.dart';
import 'ReviewsListScreen.dart';

class CreateReviewScreen extends StatefulWidget {
  const CreateReviewScreen({super.key});

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _searchController = TextEditingController();
  final _summaryController = TextEditingController();
  final _reviewController = TextEditingController();

  List<dynamic> _books = [];
  dynamic _selectedBook;
  int _rating = 0;

  Future<void> _handleSearch(String query) async {
    final results = await ReviewService.searchBooks(context, query);
    if (results != null) setState(() => _books = results);
  }

  Future<void> _handleSaveReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final success = await ReviewService.saveReview(
      context: context,
      user: user,
      book: _selectedBook,
      summary: _summaryController.text,
      review: _reviewController.text,
      rating: _rating,
    );

    if (success) {
      // Redireciona para a tela de ver resenhas (substituindo a tela atual)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReviewsListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/myreviewsList'),
        ),
        title: const Text('Nova Resenha'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de busca
            TextField(
              controller: _searchController,
              onSubmitted: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Digite o nome do livro',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.deepPurple.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Lista de livros
            if (_books.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _books.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) => BookListTile(
                    book: _books[index],
                    onTap: () {
                      setState(() {
                        _selectedBook = _books[index];
                        _books = [];
                        _searchController.text = _selectedBook['title'] ?? '';
                      });
                    },
                  ),
                ),
              ),

            if (_selectedBook != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.shade100.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBook['title'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (_selectedBook['author_name'] as List?)?.join(', ') ?? 'Autor desconhecido',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Campo resumo
            TextField(
              controller: _summaryController,
              decoration: InputDecoration(
                labelText: 'Resumo (opcional)',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // Campo resenha
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: 'Resenha',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              maxLines: 5,
            ),

            const SizedBox(height: 24),

            // Estrelas de avaliação
            Center(
              child: StarRating(
                rating: _rating,
                onRatingChanged: (newRating) => setState(() => _rating = newRating),
              ),
            ),

            const SizedBox(height: 32),

            // Botão Salvar
            ElevatedButton.icon(
              onPressed: _handleSaveReview,
              icon: const Icon(Icons.save, size: 24),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Salvar Resenha',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: Colors.deepPurpleAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
