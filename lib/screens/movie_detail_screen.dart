import 'package:flutter/material.dart';

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