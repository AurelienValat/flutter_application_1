import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
  final PageController _mainPageController = PageController(initialPage: 0);
  final PageController _subPageController = PageController(initialPage: 0);

  // Fonction utilitaire pour transformer la date TMDB en texte lisible
  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null) return "Date inconnue";
    try {
      DateTime airDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime airDateOnly = DateTime(airDate.year, airDate.month, airDate.day);

      int difference = airDateOnly.difference(today).inDays;

      if (difference == 0) return "AUJOURD'HUI";
      if (difference == 1) return "DEMAIN";
      if (difference < 7 && difference > 0) return "DANS $difference JOURS";
      
      // Sinon on affiche la date formatée (ex: 12 Mai)
      return DateFormat('d MMM', 'fr_FR').format(airDate).toUpperCase();
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          // --- PREMIER NIVEAU : SÉRIES / FILMS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton("SÉRIES", isMain: true, index: 0),
              const SizedBox(width: 30),
              _buildFilterButton("FILMS", isMain: true, index: 1),
            ],
          ),
          const SizedBox(height: 15),
          // --- DEUXIÈME NIVEAU : À VOIR / À VENIR ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton("À VOIR", isMain: false, index: 0),
              const SizedBox(width: 25),
              _buildFilterButton("À VENIR", isMain: false, index: 1),
            ],
          ),
          const SizedBox(height: 20),

          // --- ZONE DE SWIPE ---
          Expanded(
            child: PageView(
              controller: _mainPageController,
              onPageChanged: (index) {
                setState(() => selectedType = index == 0 ? "SÉRIES" : "FILMS");
              },
              children: [
                // PAGE SÉRIES (qui contient son propre swipe À voir / À venir)
                _buildSubPageView("SÉRIES"),
                // PAGE FILMS (qui contient son propre swipe À voir / À venir)
                _buildSubPageView("FILMS"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour les nouveaux boutons stylés
  Widget _buildFilterButton(String label, {required bool isMain, required int index}) {
    bool isSelected = isMain ? (selectedType == label) : (selectedSubFilter == label);
    
    return GestureDetector(
      onTap: () {
        if (isMain) {
          _mainPageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else {
          _subPageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: isMain ? 24 : 18,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  // Le sous-swipe pour À VOIR / À VENIR
  Widget _buildSubPageView(String type) {
    return PageView(
      controller: _subPageController,
      onPageChanged: (index) {
        setState(() => selectedSubFilter = index == 0 ? "À VOIR" : "À VENIR");
      },
      children: [
        // Sous-page 0 : À VOIR (Grille)
        ListView(
          padding: EdgeInsets.zero,
          children: [
            if (type == "SÉRIES") ...[
              _buildMovieGrid(isInProgress: true, sectionTitle: "En cours", type: type),
              _buildMovieGrid(isInProgress: false, sectionTitle: "Pas commencé", type: type),
            ] else ...[
              _buildMovieGrid(isInProgress: false, sectionTitle: "Mes Films à voir", type: type),
            ],
          ],
        ),
        // Sous-page 1 : À VENIR (Timeline)
        _buildComingSoonTimeline(type),
      ],
    );
  }

  Widget _buildComingSoonTimeline(String type) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .where('mediaType', isEqualTo: type)
          .where('nextAirDate', isGreaterThanOrEqualTo: todayStr)
          .orderBy('nextAirDate')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erreur Firebase : Regarde la console VS Code !", style: TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Rien de prévu pour le moment", style: TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String displayDate = _formatDisplayDate(data['nextAirDate']);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne Date
                  SizedBox(
                    width: 80,
                    child: Text(
                      displayDate,
                      style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  // Carte du média
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: data))),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                "https://image.tmdb.org/t/p/w200${data['poster_path']}",
                                width: 50, height: 75, fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  Text(
                                    data['nextAirLabel'] ?? (type == "FILMS" ? "Sortie Cinéma" : "Nouvel épisode"),
                                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGETS DE FILTRES ---
  Widget _buildMainFilter(String label, int pageIndex) {
    bool isSelected = selectedType == label;
    return GestureDetector(
      onTap: () {
        _mainPageController.animateToPage(pageIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
          if (isSelected) Container(margin: const EdgeInsets.only(top: 4), height: 3, width: 20, color: Colors.deepPurpleAccent),
        ],
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
      labelStyle: TextStyle(color: isSelected ? Colors.deepPurpleAccent : Colors.grey, fontWeight: FontWeight.bold),
      backgroundColor: Colors.transparent,
      side: BorderSide(color: isSelected ? Colors.deepPurpleAccent : Colors.grey[800]!),
    );
  }

  Widget _buildMovieGrid({required bool isInProgress, required String sectionTitle, required String type}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(userId).collection('watchlist')
          .where('mediaType', isEqualTo: type)
          .where('isInProgress', isEqualTo: isInProgress)
          .where('isFinished', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(15), child: Text(sectionTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var movieData = docs[index].data() as Map<String, dynamic>;
                return MovieCard(movie: movieData, showAddButton: false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movieData))));
              },
            ),
          ],
        );
      },
    );
  }
}