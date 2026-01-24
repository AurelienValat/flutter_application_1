import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

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
  List<String> seenEpisodesIds = []; // Liste locale des épisodes vus
  bool isLoading = true;
  bool isLoadingEpisodes = false;

  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? "";

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    final String id = widget.movie['id'].toString();
    final bool isSeries = widget.movie.containsKey('first_air_date') ||
        widget.movie['mediaType'] == "SÉRIES";
    final String type = isSeries ? 'tv' : 'movie';
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final url = Uri.parse(
      'https://api.themoviedb.org/3/$type/$id?api_key=$apiKey&language=fr-FR&append_to_response=watch/providers');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          fullData = json.decode(response.body);
          isLoading = false;
        });

        if (userId != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('watchlist')
              .doc(id)
              .get();

          if (doc.exists) {
            final firestoreData = doc.data() as Map<String, dynamic>;
            setState(() {
              seenEpisodesIds =
                  List<String>.from(firestoreData['seenEpisodes'] ?? []);
            });
          }
        }

        if (response.statusCode == 200) {
          setState(() {
            fullData = json.decode(response.body);
            isLoading = false;
          });
          if (isSeries) _fetchEpisodes(1);
        }

        // Mise à jour du total d'épisodes pour la barre de progression
        if (fullData != null && isSeries && userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('watchlist')
              .doc(id)
              .update({
            'totalEpisodes': fullData!['number_of_episodes'],
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

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
    final displayMovie = fullData ?? widget.movie;
    final bool isSeries = widget.movie.containsKey('first_air_date') ||
        widget.movie['mediaType'] == "SÉRIES";

    if (isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent)));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  'https://image.tmdb.org/t/p/w500${displayMovie['backdrop_path'] ?? displayMovie['poster_path']}',
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                        "TMDB ${(displayMovie['vote_average'] ?? 0.0).toStringAsFixed(1)}",
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
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
                      displayMovie['title'] ??
                          displayMovie['name'] ??
                          'Titre inconnu',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // TODO pour series: afficher temps moyen par épisode à la place du nombre de saisons
                  Text(
                      "Durée : ${isSeries ? (fullData != null ? fullData!['number_of_seasons'].toString() + ' saisons' : 'N/A') : (displayMovie['runtime'] != null ? displayMovie['runtime'].toString() + ' min' : 'N/A')}",
                      style: const TextStyle(color: Colors.grey)),
                      
                  const SizedBox(height: 10),

                  Text(
                      "Sortie : ${displayMovie['release_date'] ?? displayMovie['first_air_date'] ?? 'Inconnue'}",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  if (displayMovie['genres'] != null)
                    Wrap(
                      spacing: 8, // Espace horizontal entre les badges
                      runSpacing: 4, // Espace vertical si ça passe à la ligne
                      children: (displayMovie['genres'] as List).map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                          ),
                          child: Text(
                            genre['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 10),

                  _buildProviders(displayMovie),

                  const SizedBox(height: 20),
                  const Text("Synopsis",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(displayMovie['overview'] ?? "Aucun synopsis disponible.",
                      style: const TextStyle(fontSize: 16, height: 1.4)),
                  if (isSeries && fullData != null) ...[
                    const SizedBox(height: 30),
                    const Text("Saisons",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
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
                    Text("Épisodes (${episodes.length})",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (isLoadingEpisodes)
                      const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator()))
                    else
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: episodes.length,
                        itemBuilder: (context, index) {
                          final ep = episodes[index];
                          final String epId = ep['id'].toString();
                          bool isSeen = seenEpisodesIds.contains(epId);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: ep['still_path'] != null
                                  ? Image.network(
                                      "https://image.tmdb.org/t/p/w200${ep['still_path']}",
                                      width: 80,
                                      fit: BoxFit.cover)
                                  : Container(
                                      width: 80,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.tv)),
                            ),
                            title: Text("E${ep['episode_number']} - ${ep['name']}"),
                            subtitle: Text(ep['overview'] ?? "",
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: Icon(
                                isSeen
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: isSeen ? Colors.green : Colors.grey,
                              ),
                              onPressed: () async {
                                bool newStatus = !isSeen;
                                String movieId = widget.movie['id'].toString();
                                String userId = FirebaseAuth.instance.currentUser!.uid;

                                // 1. Mise à jour via DatabaseService
                                await DatabaseService().toggleEpisodeSeen(
                                  movieId,
                                  epId,
                                  newStatus,
                                );

                                // 2. Mise à jour de la liste locale pour le calcul de isInProgress
                                setState(() {
                                  if (newStatus) {
                                    seenEpisodesIds.add(epId);
                                  } else {
                                    seenEpisodesIds.remove(epId);
                                  }
                                });

                                // 3. Déterminer si la série est toujours "En cours"
                                bool remainsInProgress = seenEpisodesIds.isNotEmpty;

                                // 4. Mise à jour des badges et du statut
                                if (remainsInProgress) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .collection('watchlist')
                                      .doc(movieId)
                                      .update({
                                    'isInProgress': true,
                                    'lastSeasonSeen': selectedSeason,
                                    'lastEpisodeSeen': ep['episode_number'],
                                    'nextSeasonToSee': newStatus
                                        ? (ep['episode_number'] < episodes.length
                                            ? selectedSeason
                                            : selectedSeason + 1)
                                        : selectedSeason,
                                    'nextEpisodeToSee': newStatus
                                        ? (ep['episode_number'] < episodes.length
                                            ? ep['episode_number'] + 1
                                            : 1)
                                        : ep['episode_number'],
                                  });
                                } else {
                                  // Si on a tout décoché : retour à "Pas commencé"
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .collection('watchlist')
                                      .doc(movieId)
                                      .update({
                                    'isInProgress': false,
                                    'lastSeasonSeen': null,
                                    'lastEpisodeSeen': null,
                                    'nextSeasonToSee': 1,
                                    'nextEpisodeToSee': 1,
                                  });
                                }
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

    Widget _buildProviders(Map? data) {
    // On va chercher dans watch/providers -> results -> FR -> flatrate
    var providers = data?['watch/providers']?['results']?['FR']?['flatrate'];

    if (providers == null || (providers as List).isEmpty) {
      return const SizedBox.shrink(); // Ne renvoie rien si pas de plateforme
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text("Disponible sur :", 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (providers as List).length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: provider['provider_name'], // Affiche le nom au clic long
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://image.tmdb.org/t/p/w200${provider['logo_path']}",
                    ),
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