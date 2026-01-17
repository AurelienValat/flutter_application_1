import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Récupérer la liste des films en temps réel
  Stream<QuerySnapshot> getWatchlist() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Supprimer un film de la liste
  Future<void> removeMovie(String movieId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(movieId)
        .delete();
  }

Future<void> addToWatchlist(Map<String, dynamic> movie) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // TMDB utilise 'name' pour les séries et 'title' pour les films
  bool isSeries = movie.containsKey('name') || movie['first_air_date'] != null;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watchlist')
      .doc(movie['id'].toString())
      .set({
    'id': movie['id'],
    'title': isSeries ? (movie['name'] ?? 'Sans titre') : (movie['title'] ?? 'Sans titre'),
    'poster_path': movie['poster_path'],
    'vote_average': movie['vote_average'],
    'mediaType': isSeries ? "SÉRIES" : "FILMS", // Très important pour ton filtre
    'isInProgress': false, // Par défaut "Pas commencé"
    'status': 'A VOIR',    // Par défaut "À voir"
    'addedAt': FieldValue.serverTimestamp(),
  });
}

}