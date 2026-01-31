import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/review_card.dart';
import '../widgets/nav_bar.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String query =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    final searchStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('title_lowercase', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('title_lowercase',
            isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
        .orderBy('title_lowercase')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resultados da busca: "$query"',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: searchStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text('Nenhuma resenha encontrada para "$query".'),
            );
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
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/myreviewsList');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/reviewsList');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/createReview');
          } else if (index == 3) {
            // Já está aqui
          }
        },
      ),
    );
  }
}
