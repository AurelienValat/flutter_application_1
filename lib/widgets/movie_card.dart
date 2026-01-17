import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class MovieCard extends StatelessWidget {
  final Map<String, dynamic> movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            movie['poster_path'] != null
                ? Image.network(
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                    fit: BoxFit.cover,
                  )
                : Container(color: const Color(0xFF1F1F1F)),

            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "IMDB ${(movie['vote_average'] ?? 0.0).toStringAsFixed(1)}",
                  style: const TextStyle(
                      color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: StreamBuilder<DocumentSnapshot>(
                // On vérifie en temps réel si ce film existe dans la liste de l'utilisateur
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('watchlist')
                    .doc(movie['id'].toString())
                    .snapshots(),
                builder: (context, snapshot) {
                  final bool isAdded = snapshot.hasData && snapshot.data!.exists;

                  return GestureDetector(
                    onTap: () {
                      if (isAdded) {
                        DatabaseService().removeMovie(movie['id'].toString());
                      } else {
                        DatabaseService().addToWatchlist(movie);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isAdded 
                            ? Colors.deepPurpleAccent 
                            : Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdded ? Icons.bookmark : Icons.bookmark_add_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}