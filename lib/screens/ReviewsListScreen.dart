import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/review_card.dart';
import '../widgets/nav_bar.dart';

class ReviewsListScreen extends StatefulWidget {
  const ReviewsListScreen({super.key});

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: !_isSearching
            ? const Text(
                'Últimas Resenhas',
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma resenha encontrada.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final userId = data['userId'] as String? ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  String userName = 'Usuário desconhecido';

                  if (userSnapshot.connectionState == ConnectionState.done &&
                      userSnapshot.hasData) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null && userData['name'] != null) {
                      userName = userData['name'];
                    }
                  }

                  return ReviewCard(
                    review: data,
                    docId: doc.id,
                    userName: userName,
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/myreviewsList');
          } else if (index == 1) {
            // já está aqui
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
