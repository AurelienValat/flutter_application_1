import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  String selectedType = 'SÉRIES'; 
  String selectedSubFilter = 'À VOIR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMainFilter("SÉRIES"),
              const SizedBox(width: 20),
              _buildMainFilter("FILMS"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSubFilter("À VOIR"),
              const SizedBox(width: 15),
              _buildSubFilter("À VENIR"),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildMainFilter(String label) {
    bool isSelected = selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => selectedType = label),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSubFilter(String label) {
    bool isSelected = selectedSubFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => selectedSubFilter = label),
      selectedColor: Colors.deepPurpleAccent.withOpacity(0.3),
      labelStyle: TextStyle(color: isSelected ? Colors.deepPurpleAccent : Colors.grey),
    );
  }

  Widget _buildContent() {
    //TODO: Gérer le filtre "À VENIR"
    if (selectedSubFilter == "À VENIR") {
      return const Center(child: Text("Bientôt disponible...", style: TextStyle(color: Colors.grey)));
    }

    if (selectedType == "SÉRIES") {
      return ListView(
        children: [
          // On passe le titre à la grille pour qu'elle gère l'affichage
          _buildMovieGrid(isInProgress: true, sectionTitle: "En cours"),
          _buildMovieGrid(isInProgress: false, sectionTitle: "Pas commencé"),
        ],
      );
    } else {
      return ListView(
        children: [
          _buildMovieGrid(isInProgress: false, sectionTitle: "Mes Films à voir"),
        ],
      );
    }
  }

  Widget _buildMovieGrid({required bool isInProgress, required String sectionTitle}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .where('mediaType', isEqualTo: selectedType)
          .where('isInProgress', isEqualTo: isInProgress)
          .where('isFinished', isEqualTo: false) 
          .snapshots(),
      builder: (context, snapshot) {
        // Si pas de données ou vide : On retourne un espace vide (titre caché)
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); 
        }

        final docs = snapshot.data!.docs;

        // Si il y a des films, on affiche le Titre + la Grille
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(sectionTitle),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var movieData = docs[index].data() as Map<String, dynamic>;
                return MovieCard(movie: movieData, showAddButton: false, onTap: () {Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => MovieDetailScreen(movie: movieData),
                                                                ),
                                                              );});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}