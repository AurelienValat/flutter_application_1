import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  List<String> seenEpisodesIds = []; 
  List<String> seenKeys = []; // NOUVEAU : Stocke "S1E1", "S2E4" pour la chronologie
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
            seenEpisodesIds = List<String>.from(firestoreData['seenEpisodes'] ?? []);
            seenKeys = List<String>.from(firestoreData['seenKeys'] ?? []); // On récupère les clés
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

  Widget _buildProviders(Map? data) {
    final results = data?['watch/providers']?['results'];
    final frProviders = results?['FR']?['flatrate'];

    if (frProviders == null || (frProviders as List).isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text("Disponible sur :", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (frProviders as List).length,
            itemBuilder: (context, index) {
              final provider = frProviders[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    "https://image.tmdb.org/t/p/w200${provider['logo_path']}",
                    width: 40, height: 40,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  Text(
                      "Sortie : ${displayMovie['release_date'] ?? displayMovie['first_air_date'] ?? 'Inconnue'}",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(
                    "Durée : ${isSeries ? (fullData != null ? "${fullData!['number_of_seasons']} saisons (${(fullData!['episode_run_time'] != null && fullData!['episode_run_time'].isNotEmpty) ? fullData!['episode_run_time'][0] : 'N/A'} min/ép)" : "Chargement...") : (displayMovie['runtime'] != null ? "${displayMovie['runtime']} min" : "N/A")}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),

                  if (displayMovie['genres'] != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
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
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  
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
                          final String epKey = "S${selectedSeason}E${ep['episode_number']}"; // ex: "S1E5"
                          bool isSeen = seenKeys.contains(epKey);

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

                                // 1. Mise à jour Locale (immédiate)
                                setState(() {
                                  if (newStatus) {
                                    seenEpisodesIds.add(epId);
                                    seenKeys.add(epKey);
                                  } else {
                                    seenEpisodesIds.remove(epId);
                                    seenKeys.remove(epKey);
                                  }
                                });

                                // 2. RECHERCHE DU PROCHAIN ÉPISODE (LOGIQUE DE LA PROGRESSION MAXIMALE)
                                int maxS = 0;
                                int maxE = 0;

                                // On cherche l'épisode le plus avancé parmi tous ceux qui sont cochés
                                for (String key in seenKeys) {
                                  // On extrait les numéros de la clé (ex: "S1E5")
                                  RegExp regExp = RegExp(r'S(\d+)E(\d+)');
                                  Match? match = regExp.firstMatch(key);
                                  if (match != null) {
                                    int s = int.parse(match.group(1)!);
                                    int e = int.parse(match.group(2)!);
                                    // On garde la saison la plus haute, ou l'épisode le plus haut si même saison
                                    if (s > maxS || (s == maxS && e > maxE)) {
                                      maxS = s;
                                      maxE = e;
                                    }
                                  }
                                }

                                int nextS = 1;
                                int nextE = 1;
                                bool isFinished = false;

                                if (seenKeys.isNotEmpty) {
                                  nextS = maxS;
                                  nextE = maxE + 1; // On propose celui juste après le plus avancé

                                  if (fullData != null && fullData!['seasons'] != null) {
                                    var seasonsList = List.from(fullData!['seasons']);

                                    // On cherche combien d'épisodes contient cette saison maximale
                                    var currentSeasonData = seasonsList.firstWhere(
                                        (s) => s['season_number'] == maxS, 
                                        orElse: () => null
                                    );

                                    if (currentSeasonData != null) {
                                      int epCount = currentSeasonData['episode_count'] ?? 0;
                                      
                                      // Si on a dépassé la fin de la saison, on passe à la S+1 E1
                                      if (nextE > epCount) {
                                        nextS = maxS + 1;
                                        nextE = 1;

                                        // On vérifie si la saison suivante existe vraiment
                                        bool nextSeasonExists = seasonsList.any((s) => s['season_number'] == nextS);
                                        if (!nextSeasonExists) {
                                          isFinished = true; // S'il n'y a plus de saison, la série est finie !
                                        }
                                      }
                                    }
                                  }
                                }

                                bool isInProgress = seenKeys.isNotEmpty && !isFinished;


                                // 3. Mise à jour de Firestore
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('watchlist')
                                    .doc(movieId)
                                    .update({
                                  'isInProgress': isInProgress,
                                  'isFinished': isFinished,
                                  'nextSeasonToSee': isFinished ? 0 : nextS,
                                  'nextEpisodeToSee': isFinished ? 0 : nextE,
                                  'seenEpisodes': newStatus 
                                      ? FieldValue.arrayUnion([epId]) 
                                      : FieldValue.arrayRemove([epId]),
                                  'seenKeys': newStatus 
                                      ? FieldValue.arrayUnion([epKey]) 
                                      : FieldValue.arrayRemove([epKey]),
                                });
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