import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'movie_detail_screen.dart';
import '../widgets/filter_buttons.dart'; 
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => MovieListScreenState();
}

class MovieListScreenState extends State<MovieListScreen> {
  List movies = [];
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final String apiKey = "0f279ff62ffdfe1c65473f2ff7f1d739";
  String selectedType = 'all'; 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    final url = 'https://api.themoviedb.org/3/trending/$selectedType/day?api_key=$apiKey&language=fr-FR';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          movies = json.decode(response.body)['results'];
          isSearching = false;
        });
      }
    } catch (e) {
      print("Erreur : $e");
    }
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      fetchMovies();
      return;
    }
    String searchUrl = selectedType == 'all' 
        ? 'https://api.themoviedb.org/3/search/multi?api_key=$apiKey&language=fr-FR&query=$query'
        : 'https://api.themoviedb.org/3/search/$selectedType?api_key=$apiKey&language=fr-FR&query=$query';

    try {
      final response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        setState(() {
          movies = json.decode(response.body)['results'];
          isSearching = true;
        });
      }
    } catch (e) {
      print("Erreur recherche : $e");
    }
  }

  void resetToHome() {
    setState(() {
      selectedType = 'all';
      isSearching = false;
      _searchController.clear();
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
    fetchMovies();
  }

  String _getDynamicTitle() {
    if (isSearching) return "RÉSULTATS";
    if (selectedType == 'tv') return 'SÉRIES DU MOMENT';
    if (selectedType == 'movie') return 'FILMS DU MOMENT';
    return 'TENDANCES';
  }

  @override
  Widget build(BuildContext context) {
    // On récupère les couleurs du thème actuel (Clair ou Sombre)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 10),
        
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              // Si mode sombre : gris foncé, si mode clair : gris très léger
              color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200], 
              borderRadius: BorderRadius.circular(25)
            ),
            child: TextField(
              controller: _searchController,
              onChanged: searchMovies,
              // On force la couleur du texte tapé selon le thème
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.black38),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.clear, color: isDark ? Colors.white38 : Colors.black38), 
                      onPressed: () { _searchController.clear(); fetchMovies(); }
                    ) 
                  : null,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // Filtres
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilterButton(label: "Tendances", type: "all", isSelected: selectedType == "all", onTap: () { setState(() => selectedType = "all"); fetchMovies(); }),
            const SizedBox(width: 10),
            FilterButton(label: "Séries", type: "tv", isSelected: selectedType == "tv", onTap: () { setState(() => selectedType = "tv"); fetchMovies(); }),
            const SizedBox(width: 10),
            FilterButton(label: "Films", type: "movie", isSelected: selectedType == "movie", onTap: () { setState(() => selectedType = "movie"); fetchMovies(); }),
          ],
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
          child: Text(
            _getDynamicTitle(), 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color, // Couleur dynamique du texte
            )
          ),
        ),

        Expanded(
          child: movies.isEmpty 
          ? Center(child: Text("Aucun résultat", style: TextStyle(color: theme.textTheme.bodyMedium?.color))) 
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 150), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return MovieCard(
                  movie: movies[index],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movies[index]))),
                );
              },
            ),
        ),
      ],
    );
  }
}