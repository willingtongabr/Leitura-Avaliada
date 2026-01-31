import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserReviewScreen extends StatefulWidget {
  final Map dados;
  final String docId;

  const UserReviewScreen({super.key, required this.dados, required this.docId});

  @override
  State<UserReviewScreen> createState() => _UserReviewScreenState();
}

class _UserReviewScreenState extends State<UserReviewScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  bool _isLiking = false;
  bool _hasLiked = false;
  late int _likes;
  late final String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _likes = widget.dados['likes'] ?? 0;
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    if (_currentUserId == null) return;

    final likeDoc = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.docId)
        .collection('likes')
        .doc(_currentUserId)
        .get();

    setState(() {
      _hasLiked = likeDoc.exists;
    });
  }

  Future<void> _likeReview() async {
    if (_isLiking || _currentUserId == null) return;

    final reviewRef =
        FirebaseFirestore.instance.collection('reviews').doc(widget.docId);
    final likeDocRef =
        reviewRef.collection('likes').doc(_currentUserId);

    setState(() {
      _isLiking = true;
    });

    final likeDoc = await likeDocRef.get();

    if (!likeDoc.exists) {
      // Curtir
      await likeDocRef.set({'likedAt': FieldValue.serverTimestamp()});
      await reviewRef.update({'likes': FieldValue.increment(1)});
      setState(() {
        _likes++;
        _hasLiked = true;
      });
    } else {
      // Descurtir (opcional — remova este bloco para impedir toggle)
      await likeDocRef.delete();
      await reviewRef.update({'likes': FieldValue.increment(-1)});
      setState(() {
        _likes--;
        _hasLiked = false;
      });
    }

    setState(() {
      _isLiking = false;
    });
  }

  Future<Map<String, dynamic>> _fetchUser(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }

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
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: !_isSearching
            ? const Text('Resenha do usuário')
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
        actions: !_isSearching
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
              ]
            : null,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUser(widget.dados['userId']),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? 'Usuário',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                timeago.format(
                                  (widget.dados['timestamp'] as Timestamp).toDate(),
                                  locale: 'pt_BR',
                                ),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.dados['review'] != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.dados['review'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      if (widget.dados['coverUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 400,
                              maxWidth: MediaQuery.of(context).size.width,
                            ),
                            child: Image.network(
                              widget.dados['coverUrl'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        widget.dados['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < (widget.dados['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _hasLiked ? Icons.favorite : Icons.favorite_border,
                              color: Colors.pink,
                            ),
                            onPressed: _likeReview,
                          ),
                          Text('$_likes curtidas'),
                        ],
                      ),
                      if (_currentUserId == widget.dados['userId'])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/editReview',
                                  arguments: {
                                    'docId': widget.docId,
                                    'currentReview':
                                        widget.dados.cast<String, dynamic>(),
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text(''),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/myreviewsList');
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
