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
  
  // UN SEUL contrôleur pour tout l'écran (évite les bugs de désynchro)
  final PageController _subPageController = PageController(initialPage: 0);

  // Formate la date pour la timeline
  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "null") return "Bientôt";
    try {
      DateTime airDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime airDateOnly = DateTime(airDate.year, airDate.month, airDate.day);
      int difference = airDateOnly.difference(today).inDays;

      if (difference == 0) return "AUJOURD'HUI";
      if (difference == 1) return "DEMAIN";
      if (difference < 7 && difference > 0) return "DANS $difference JOURS";
      return DateFormat('d MMM', 'fr_FR').format(airDate).toUpperCase();
    } catch (e) {
      return "À VENIR";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          // --- NIVEAU 1 : SÉRIES / FILMS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMainTypeButton("SÉRIES"),
              const SizedBox(width: 30),
              _buildMainTypeButton("FILMS"),
            ],
          ),
          const SizedBox(height: 15),
          // --- NIVEAU 2 : À VOIR / À VENIR ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSubFilterButton("À VOIR", 0),
              const SizedBox(width: 25),
              _buildSubFilterButton("À VENIR", 1),
            ],
          ),
          const SizedBox(height: 20),

          // --- ZONE DE CONTENU (SWIPE UNIQUE) ---
          Expanded(
            child: PageView(
              controller: _subPageController,
              onPageChanged: (index) {
                setState(() => selectedSubFilter = index == 0 ? "À VOIR" : "À VENIR");
              },
              children: [
                // PAGE 1 : Les listes (En cours / Pas commencé)
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (selectedType == "SÉRIES") ...[
                      _buildMovieGrid(isInProgress: true, sectionTitle: "En cours"),
                      _buildMovieGrid(isInProgress: false, sectionTitle: "Pas commencé"),
                    ] else ...[
                      _buildMovieGrid(isInProgress: false, sectionTitle: "Mes Films à voir"),
                    ],
                  ],
                ),
                // PAGE 2 : Le Calendrier
                _buildComingSoonTimeline(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bouton principal (Séries / Films)
  Widget _buildMainTypeButton(String label) {
    bool isSelected = selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => selectedType = label),
      child: _buildButtonText(label, isSelected, true),
    );
  }

  // Bouton secondaire (À voir / À venir)
  Widget _buildSubFilterButton(String label, int index) {
    bool isSelected = selectedSubFilter == label;
    return GestureDetector(
      onTap: () => _subPageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      child: _buildButtonText(label, isSelected, false),
    );
  }

  // Style des boutons
  Widget _buildButtonText(String label, bool isSelected, bool isMain) {
    return Column(
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
            height: 3, width: isMain ? 24 : 18,
            decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(2)),
          ),
      ],
    );
  }

  // --- LOGIQUE DE GRILLE CORRIGÉE (Anti-Catch) ---
  Widget _buildMovieGrid({required bool isInProgress, required String sectionTitle}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('watchlist').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          
          // 1. Filtrage Type
          bool isSeries = data.containsKey('first_air_date') || data.containsKey('name') || data['mediaType'] == 'SÉRIES';
          if ((isSeries ? "SÉRIES" : "FILMS") != selectedType) return false;
          
          // 2. Filtrage Statut
          if (data['isFinished'] == true) return false;
          bool docInProgress = data['isInProgress'] == true;
          if (docInProgress != isInProgress) return false;
          
          // 3. Filtrage Date (On évite le catch en étant très prudent)
          String? dateStr = data['first_air_date'] ?? data['release_date'];
          if (dateStr != null && dateStr.isNotEmpty && dateStr != "null") {
             String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
             if (dateStr.compareTo(today) > 0) return false; // Pas encore sorti
          }
          return true;
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

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

  // --- LOGIQUE CALENDRIER CORRIGÉE ---
  Widget _buildComingSoonTimeline() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('watchlist').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          bool isSeries = data.containsKey('first_air_date') || data.containsKey('name') || data['mediaType'] == 'SÉRIES';
          if ((isSeries ? "SÉRIES" : "FILMS") != selectedType) return false;

          String? nextDate = data['nextAirDate'];
          return nextDate != null && nextDate.isNotEmpty && nextDate.compareTo(today) >= 0;
        }).toList();

        docs.sort((a, b) => (a.data() as Map)['nextAirDate'].compareTo((b.data() as Map)['nextAirDate']));

        if (docs.isEmpty) return const Center(child: Text("Rien de prévu", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(_formatDisplayDate(data['nextAirDate']), style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: data))),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network("https://image.tmdb.org/t/p/w200${data['poster_path']}", width: 50, height: 75, fit: BoxFit.cover)),
                            const SizedBox(width: 15),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(data['title'] ?? data['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                              Text(data['nextAirLabel'] ?? "Sortie Prochaine", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ])),
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
}