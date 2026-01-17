import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MovieDetailScreen extends StatefulWidget {
  final Map movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  int selectedSeason = 1;
  List episodes = [];
  Map<String, dynamic>? fullData; 
  bool isLoading = true;
  bool isLoadingEpisodes = false;
  
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? "";

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    // On récupère l'ID proprement
    final String id = widget.movie['id'].toString();
    
    // On détecte le type (Film ou Série)
    final bool isSeries = widget.movie.containsKey('first_air_date') || 
                          widget.movie['mediaType'] == "SÉRIES";
    final String type = isSeries ? 'tv' : 'movie';

    final url = Uri.parse(
        'https://api.themoviedb.org/3/$type/$id?api_key=$apiKey&language=fr-FR');

    try {
      print("Appel API : $url"); 
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          fullData = data;
          // On force l'arrêt du chargement ici
          isLoading = false;
        });
        if (isSeries) _fetchEpisodes(1);
      } else {
        print("Erreur API : ${response.statusCode} - ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception attrapée : $e");
      setState(() => isLoading = false);
    } finally {
      // Sécurité ultime : on arrête le chargement quoi qu'il arrive
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 2. Charger les épisodes d'une saison
  Future<void> _fetchEpisodes(int seasonNumber) async {
    setState(() {
      isLoadingEpisodes = true;
      selectedSeason = seasonNumber;
    });

    final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/${widget.movie['id']}/season/$seasonNumber?api_key=$apiKey&language=fr-FR');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          episodes = data['episodes'] ?? [];
          isLoadingEpisodes = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingEpisodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // On utilise fullData s'il est chargé, sinon les infos basiques de widget.movie
    final displayMovie = fullData ?? widget.movie;
    final bool isSeries = widget.movie.containsKey('first_air_date') || 
                          widget.movie['mediaType'] == "SÉRIES";

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE ET NOTE
            Stack(
              children: [
                Image.network(
                  'https://image.tmdb.org/t/p/w500${displayMovie['backdrop_path'] ?? displayMovie['poster_path']}',
                  width: double.infinity, height: 300, fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                    child: Text("IMDB ${(displayMovie['vote_average'] ?? 0.0).toStringAsFixed(1)}", 
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayMovie['title'] ?? displayMovie['name'] ?? 'Titre inconnu', 
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    "Sortie : ${displayMovie['release_date'] ?? displayMovie['first_air_date'] ?? 'Inconnue'}", 
                    style: const TextStyle(color: Colors.grey)
                  ),
                  const SizedBox(height: 20),
                  const Text("Synopsis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(displayMovie['overview'] ?? "Aucun synopsis disponible.", 
                    style: const TextStyle(fontSize: 16, height: 1.4)),
                  
                  // SECTION SÉRIES
                  if (isSeries && fullData != null) ...[
                    const SizedBox(height: 30),
                    const Text("Saisons", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    // Sélecteur de Saisons
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: fullData!['number_of_seasons'] ?? 0,
                        itemBuilder: (context, index) {
                          int sNum = index + 1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text("Saison $sNum"),
                              selected: selectedSeason == sNum,
                              selectedColor: Colors.deepPurpleAccent,
                              onSelected: (selected) => _fetchEpisodes(sNum),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text("Épisodes (${episodes.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    
                    if (isLoadingEpisodes)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: episodes.length,
                        itemBuilder: (context, index) {
                          final ep = episodes[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: ep['still_path'] != null 
                                ? Image.network("https://image.tmdb.org/t/p/w200${ep['still_path']}", width: 80, fit: BoxFit.cover)
                                : Container(width: 80, color: Colors.grey[800], child: const Icon(Icons.tv)),
                            ),
                            title: Text("E${ep['episode_number']} - ${ep['name']}"),
                            subtitle: Text(ep['overview'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis),
                            
                            trailing: IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                              onPressed: () {
                                // TODO : Logique Firestore pour passer en "En cours"
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Épisode ${ep['episode_number']} marqué comme vu")),
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}