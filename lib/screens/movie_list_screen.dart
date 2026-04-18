import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'movie_detail_screen.dart';
import '../widgets/movie_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => MovieListScreenState();
}

class MovieListScreenState extends State<MovieListScreen> {
  List searchResults = [];
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? "";
  
  final PageController _homeController = PageController();
  int _currentCategoryIndex = 0;
  final List<String> categories = ["TENDANCES", "SÉRIES", "FILMS"];
  
  Map<String, List> cachedMovies = {'all': [], 'tv': [], 'movie': []};

  @override
  void initState() {
    super.initState();
    _fetchCategory("all");
    _fetchCategory("tv");
    _fetchCategory("movie");
  }

  Future<void> _fetchCategory(String type) async {
    final url = 'https://api.themoviedb.org/3/trending/$type/day?api_key=$apiKey&language=fr-FR';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          cachedMovies[type] = json.decode(response.body)['results'];
        });
      }
    } catch (e) {
      print("Erreur chargement $type : $e");
    }
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() => isSearching = false);
      return;
    }
    String searchUrl = 'https://api.themoviedb.org/3/search/multi?api_key=$apiKey&language=fr-FR&query=$query';

    try {
      final response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        setState(() {
          searchResults = json.decode(response.body)['results'];
          isSearching = true;
        });
      }
    } catch (e) {
      print("Erreur recherche : $e");
    }
  }

  // --- TON AJOUT EST ICI : Fonction pour réinitialiser depuis le menu ---
  void resetToHome() {
    if (isSearching) {
      _searchController.clear();
      setState(() => isSearching = false);
    }
    if (_homeController.hasClients && _currentCategoryIndex != 0) {
      _homeController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 10),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200], 
              borderRadius: BorderRadius.circular(25)
            ),
            child: TextField(
              controller: _searchController,
              onChanged: searchMovies,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Rechercher un film, une série...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.black38),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.clear, color: isDark ? Colors.white38 : Colors.black38), 
                      onPressed: () { 
                        _searchController.clear(); 
                        setState(() => isSearching = false); 
                      }
                    ) 
                  : null,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        if (!isSearching)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(categories.length, (index) => _buildCategoryTab(index, isDark)),
          ),

        if (!isSearching) const SizedBox(height: 10),

        Expanded(
          child: isSearching
            ? _buildGrid(searchResults)
            : PageView(
                controller: _homeController,
                onPageChanged: (index) => setState(() => _currentCategoryIndex = index),
                children: [
                  _buildGrid(cachedMovies['all']!),
                  _buildGrid(cachedMovies['tv']!),
                  _buildGrid(cachedMovies['movie']!),
                ],
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(int index, bool isDark) {
    bool isSelected = _currentCategoryIndex == index;
    return GestureDetector(
      onTap: () => _homeController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      child: Column(
        children: [
          Text(
            categories[index], 
            style: TextStyle(
              fontSize: isSelected ? 18 : 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
            )
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4), 
              height: 3, width: 25, 
              decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(2))
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(List movieList) {
    if (movieList.isEmpty) return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 150), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15,
      ),
      itemCount: movieList.length,
      itemBuilder: (context, index) {
        return MovieCard(
          movie: movieList[index],
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movieList[index]))),
        );
      },
    );
  }
}