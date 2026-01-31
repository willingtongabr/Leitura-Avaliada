import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/review_card.dart';
import '../widgets/nav_bar.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.pushNamed(context, '/searchResults', arguments: query.trim());
    _cancelSearch();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    final userReviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: !_isSearching
            ? const Text(
                'Minhas Resenhas',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              )
            : TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[300],
                  hintText: 'Pesquisar resenhas',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.grey[800]),
                        onPressed: () {
                          _submitSearch(_searchController.text);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[800]),
                        onPressed: _cancelSearch,
                      ),
                    ],
                  ),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 18),
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
              ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        actions: !_isSearching
            ? [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: _startSearch,
                ),
              ]
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userReviewsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
                child: Text('Você ainda não criou nenhuma resenha.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final review = doc.data() as Map<String, dynamic>;

              return ReviewCard(
                review: review,
                docId: doc.id,
                userName: currentUser.displayName ?? 'Você',
              );
            },
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            // Já está aqui
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/reviewsList');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/createReview');
          } else if (index == 3) {
            _startSearch();
          }
        },
      ),
    );
  }
}
