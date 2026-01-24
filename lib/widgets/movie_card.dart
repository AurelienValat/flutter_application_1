import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class MovieCard extends StatelessWidget {
  final Map<String, dynamic> movie;
  final VoidCallback onTap;
  final bool showAddButton;

  const MovieCard({
    super.key, 
    required this.movie, 
    required this.onTap,
    this.showAddButton = true, // Par défaut, on affiche le bouton (ex: Recherche)
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // --- LOGIQUE DU BADGE ---
    // On vérifie si on doit afficher le badge "Prochain"
    // On ne l'affiche que si la série est en cours ET qu'il reste un épisode à voir
    final bool hasNextEpisode = movie['isInProgress'] == true && 
                                movie['nextEpisodeToSee'] != null && 
                                movie['nextSeasonToSee'] != 0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // IMAGE DE FOND
            movie['poster_path'] != null
                ? Image.network(
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                    fit: BoxFit.cover,
                  )
                : Container(color: const Color(0xFF1F1F1F)),

            // NOTE IMDB (En haut à gauche)
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
                  "TMDB ${(movie['vote_average'] ?? 0.0).toStringAsFixed(1)}",
                  style: const TextStyle(
                      color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // BADGE PROCHAIN ÉPISODE (En bas à gauche)
            if (hasNextEpisode)
              Positioned(
                bottom: 10,
                left: 10,
                right: 10, // On ajoute right pour que le texte puisse s'adapter
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Prochain : S${movie['nextSeasonToSee']} E${movie['nextEpisodeToSee']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),

            // --- BARRE DE PROGRESSION ---
            if (movie['mediaType'] == "SÉRIES" && movie['totalEpisodes'] != null && movie['totalEpisodes'] > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Le petit trait de progression
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (movie['seenEpisodes']?.length ?? 0) / movie['totalEpisodes'],
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),  

            // BOUTON AJOUTER/SUPPRIMER DE LA WATCHLIST (En haut à droite)
            if (showAddButton)
              Positioned(
                top: 10,
                right: 10,
                child: StreamBuilder<DocumentSnapshot>(
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