import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
 Future<void> addToWatchlist(Map<String, dynamic> movie) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // 1. On prépare les infos de base
    String movieId = movie['id'].toString();
    bool isSeries = movie.containsKey('first_air_date') || movie['mediaType'] == "SÉRIES";
    
    // On crée le document de base
    Map<String, dynamic> movieData = {
      ...movie,
      'userId': userId,
      'addedAt': FieldValue.serverTimestamp(),
      'isInProgress': false,
      'isFinished': false,
    };

    // 2. MAGIE : On va chercher les infos "À venir" direct chez TMDB
    final apiKey = dotenv.env['TMDB_API_KEY'] ?? "";
    final type = isSeries ? 'tv' : 'movie';
    final url = Uri.parse('https://api.themoviedb.org/3/$type/$movieId?api_key=$apiKey&language=fr-FR&append_to_response=next_episode_to_air');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final fullData = json.decode(response.body);
        
        if (isSeries) {
          final nextEp = fullData['next_episode_to_air'];
          if (nextEp != null) {
            movieData['nextAirDate'] = nextEp['air_date'];
            movieData['nextAirLabel'] = "S${nextEp['season_number']}E${nextEp['episode_number']} - ${nextEp['name']}";
          }
          movieData['totalEpisodes'] = fullData['number_of_episodes'];
        } else {
          movieData['nextAirDate'] = fullData['release_date'];
        }
      }
    } catch (e) {
      print("Erreur fetch auto: $e");
    }

    // 3. On enregistre le tout complet dans Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(movieId)
        .set(movieData);
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