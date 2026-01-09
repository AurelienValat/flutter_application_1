import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

// Une clé globale pour accéder à l'état de la liste de films
final GlobalKey<_MovieListScreenState> movieListKey = GlobalKey<_MovieListScreenState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const MainScreen(),
    );
  }
}

// --- 1. GESTIONNAIRE DE NAVIGATION ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    MovieListScreen(key: movieListKey), 
    const Center(child: Text("Ma Liste")),
    const Center(child: Text("Profil")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(50, 0, 50, 30),
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F).withOpacity(0.9), // Opacité pour l'effet vitre
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: Colors.deepPurpleAccent,
            unselectedItemColor: Colors.white54,
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index == 0 && _selectedIndex == 0) {
                movieListKey.currentState?.resetToHome();
              }
              setState(() {
                _selectedIndex = index;
              });
            },            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 28), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline, size: 28), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 28), label: ""),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. PAGE DE GRILLE ---
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List movies = [];
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final String apiKey = "0f279ff62ffdfe1c65473f2ff7f1d739";
  String selectedType = 'all'; // Peut être 'all', 'movie' ou 'tv'

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
  // On adapte l'URL selon le type : 'all', 'movie' ou 'tv'
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

  // Fonction pour RECHERCHER un film
  Future<void> searchMovies(String query) async {
  if (query.isEmpty) {
    fetchMovies();
    return;
  }

  // On choisit l'URL de recherche en fonction du filtre actuel
  String searchUrl;
  
  if (selectedType == 'all') {
    // Recherche globale (Films + Séries)
    searchUrl = 'https://api.themoviedb.org/3/search/multi?api_key=$apiKey&language=fr-FR&query=$query';
  } else {
    // Recherche spécifique (seulement 'movie' ou seulement 'tv')
    searchUrl = 'https://api.themoviedb.org/3/search/$selectedType?api_key=$apiKey&language=fr-FR&query=$query';
  }

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

  // Fonction qui crée le design d'un bouton de filtre
  Widget _buildFilterButton(String label, String type) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
          isSearching = false;
          _searchController.clear(); 
        });
        fetchMovies();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  //Fonction qui genere le titre
  String _getDynamicTitle() {
    if (isSearching) {
      if (selectedType == 'tv') return "RÉSULTATS SÉRIES";
      if (selectedType == 'movie') return "RÉSULTATS FILMS";
      return "RÉSULTATS";
    }
    
    switch (selectedType) {
      case 'tv':
        return 'SÉRIES DU MOMENT';
      case 'movie':
        return 'FILMS DU MOMENT';
      default:
        return 'TENDANCES';
    }
  }

  // Fonction qui genere le placeholder de la zone de recherche
  String _getSearchPlaceholder() {
    switch (selectedType) {
      case 'tv':
        return 'Rechercher une série...';
      case 'movie':
        return 'Rechercher un film...';
      default:
        return 'Rechercher un film ou une série...';
    }
  }

  //Fonction qui nettoie
  void resetToHome() {
    setState(() {
      selectedType = 'all';        // Revient sur "Tous"
      isSearching = false;         // Coupe le mode recherche
      _searchController.clear();   // Vide la barre de texte
    });
    fetchMovies();                 // Recharge les tendances "Top Movies"
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 10),
        
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => searchMovies(value), // Cherche à chaque lettre tapée
                    decoration: InputDecoration(
                      hintText: _getSearchPlaceholder(),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: Colors.white38),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              fetchMovies();
                            },
                          )
                        : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.tune, color: Colors.black),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildFilterButton("Tendances", "all"),
              const SizedBox(width: 10),
              _buildFilterButton("Séries", "tv"),
              const SizedBox(width: 10),
              _buildFilterButton("Films", "movie"),
            ],
          ),
        ),

        
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _getDynamicTitle(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2,)
            ),
          ),
        ),
        
        

        Expanded(
          child: GridView.builder(
            // Le padding du bas (150) permet de scroller assez loin pour voir le dernier film
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 150), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movie)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      movie['poster_path'] != null 
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w500${movie['poster_path']}', 
                            fit: BoxFit.cover,
                            // Petit indicateur pendant que l'image se télécharge
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amber.withOpacity(0.5),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF1F1F1F), // Gris foncé
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 40),
                                SizedBox(height: 8),
                                Text("No Image", style: TextStyle(color: Colors.white24, fontSize: 10)),
                              ],
                            ),
                          ),
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber, 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            "IMDB ${(movie['vote_average'] ?? 0.0).toStringAsFixed(1)}",
                            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- 3. PAGE DE DETAILS ---
class MovieDetailScreen extends StatelessWidget {
  final Map movie;
  const MovieDetailScreen({super.key, required this.movie});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  'https://image.tmdb.org/t/p/w500${movie['backdrop_path'] ?? movie['poster_path']}',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                    child: Text("IMDB ${(movie['vote_average'] ?? 0.0).toStringAsFixed(1)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['title'] ?? movie['name'] ?? 'Titre inconnu', 
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                  ),                  const SizedBox(height: 10),
                  Text(
                    "Sortie : ${movie['release_date'] ?? movie['first_air_date'] ?? 'Inconnue'}", 
                    style: const TextStyle(color: Colors.grey)
                  ),                  const SizedBox(height: 20),
                  const Text("Synopsis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(movie['overview'], style: const TextStyle(fontSize: 16, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}