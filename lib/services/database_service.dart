import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Récupérer la liste des films et des series en temps réel
  Stream<QuerySnapshot> getWatchlist() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Supprimer un film ou une serie de la liste
  Future<void> removeMovie(String movieId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(movieId)
        .delete();
  }

  // Ajouter un film ou une serie à la liste
  Future<void> addToWatchlist(Map<String, dynamic> movie, {int totalEpisodes = 0}) async {
    final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

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
    'mediaType': isSeries ? "SÉRIES" : "FILMS",
    
    'isInProgress': false, 
    'isFinished': false,  
    
    'status': 'A VOIR',
    'addedAt': FieldValue.serverTimestamp(),
    'seenEpisodes': [],
    'seenKeys': [],
  });
}

  // Marquer un épisode comme vu
  // Dans DatabaseService
  Future<void> toggleEpisodeSeen(String movieId, String epId, bool isAdding) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users').doc(user.uid)
        .collection('watchlist').doc(movieId)
        .update({
      'isInProgress': true,
      'seenEpisodes': isAdding 
          ? FieldValue.arrayUnion([epId]) 
          : FieldValue.arrayRemove([epId]),
    });
  }
}