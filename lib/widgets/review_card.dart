import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../screens/UserReviewScreen.dart';

class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final String docId;
  final String userName;

  const ReviewCard({
    super.key,
    required this.review,
    required this.docId,
    required this.userName,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isLiking = false;
  bool hasLiked = false;
  int likes = 0;

  @override
  void initState() {
    super.initState();
    likes = widget.review['likes'] ?? 0;
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _checkIfLiked();
  }

  void _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likeDoc = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.docId)
        .collection('likes')
        .doc(user.uid)
        .get();

    if (likeDoc.exists) {
      setState(() {
        hasLiked = true;
      });
    }
  }

  void _likeReview() async {
    if (_isLiking) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final reviewRef =
        FirebaseFirestore.instance.collection('reviews').doc(widget.docId);
    final likeDocRef = reviewRef.collection('likes').doc(userId);

    setState(() {
      _isLiking = true;
    });

    final likeDoc = await likeDocRef.get();

    if (!likeDoc.exists) {
      // Curtir
      await likeDocRef.set({'likedAt': FieldValue.serverTimestamp()});
      await reviewRef.update({'likes': FieldValue.increment(1)});
      setState(() {
        likes++;
        hasLiked = true;
      });
    } else {
      // Descurtir (opcional — remova este bloco se quiser impedir toggle)
      await likeDocRef.delete();
      await reviewRef.update({'likes': FieldValue.increment(-1)});
      setState(() {
        likes--;
        hasLiked = false;
      });
    }

    setState(() {
      _isLiking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final userName = widget.userName;

    final Timestamp? timestamp = review['timestamp'];
    final DateTime? dateTime = timestamp?.toDate();
    final String timeAgo = dateTime != null
        ? timeago.format(dateTime, locale: 'pt_BR')
        : 'Data desconhecida';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UserReviewScreen(dados: review, docId: widget.docId),
            ),
          );
        },
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (review['coverUrl'] != null && review['coverUrl'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 180,
                    child: AspectRatio(
                      aspectRatio: 4 / 4,
                      child: Image.network(
                        review['coverUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['title'] ?? 'Título desconhecido',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(Icons.star,
                            size: 16,
                            color: i < (review['rating'] ?? 0)
                                ? Colors.amber
                                : Colors.grey[300]);
                      }),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            hasLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.pink,
                            size: 20,
                          ),
                          onPressed: _likeReview,
                        ),
                        Text('$likes'),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
