import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Thème sombre, plus cinéma !
      home: const MovieListScreen(),
    );
  }
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List movies = [];
  final String apiKey = "0f279ff62ffdfe1c65473f2ff7f1d739";

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    final response = await http.get(
      Uri.parse('https://api.themoviedb.org/3/trending/movie/day?api_key=$apiKey&language=fr-FR')
    );

    if (response.statusCode == 200) {
      setState(() {
        movies = json.decode(response.body)['results'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Films Tendances')),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        // Gère la disposition des éléments (colonnes, espacement)
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,          // Nombre de colonnes
          childAspectRatio: 0.68,     // Ratio hauteur/largeur pour des affiches de film
          crossAxisSpacing: 10,       // Espace horizontal entre les cartes
          mainAxisSpacing: 10,        // Espace vertical entre les cartes
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final posterPath = movie['poster_path'];

          return GestureDetector(
            // Action au clic : Navigation vers les détails
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(movie: movie),
                ),
              );
            },
            child: ClipRRect(
              // Arrondit les coins de la carte
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. L'image de l'affiche (chargée depuis TMDB)
                  Image.network(
                    'https://image.tmdb.org/t/p/w500$posterPath',
                    fit: BoxFit.cover,
                    // Widget affiché pendant le chargement
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    // Widget affiché si l'image ne charge pas
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[850],
                      child: const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                  // 2. Le dégradé noir pour la lisibilité du texte
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 3. Le titre du film
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      movie['title'] ?? 'Sans titre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Coupe le texte avec "..." si trop long
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),   
    );
  }
}

class MovieDetailScreen extends StatelessWidget {
  final Map movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(movie['title'])),
      body: SingleChildScrollView( // Pour pouvoir scroller si le texte est long
        child: Column(
          children: [
            // Image en grand format
            Image.network(
              'https://image.tmdb.org/t/p/w500${movie['backdrop_path'] ?? movie['poster_path']}',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['title'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(" ${movie['vote_average']}/10"),
                      const SizedBox(width: 20),
                      Text("Sortie : ${movie['release_date']}"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Synopsis",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie['overview'],
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}