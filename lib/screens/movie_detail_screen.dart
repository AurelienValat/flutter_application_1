import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database_service.dart';
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
  int _selectedTab = 0; // 0 = Infos, 1 = Épisodes
  List episodes = [];
  List cast = [];
  Map<String, dynamic>? fullData;
  List<String> seenEpisodesIds = [];
  List<String> seenKeys = [];
  bool isLoading = true;
  bool isLoadingEpisodes = false;
  bool isMovieSeen = false;
  bool isInWatchlist = false;
  bool isClosing = false;
  bool isSynopsisExpanded = false;

  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? "";

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
    _fetchCredits();
  }

  Future<void> _fetchFullDetails() async {
    final String id = widget.movie['id'].toString();
    final bool isSeries = widget.movie.containsKey('first_air_date') || 
                          widget.movie.containsKey('name') || 
                          widget.movie['mediaType'] == "SÉRIES";
    final String type = isSeries ? 'tv' : 'movie';
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final url = Uri.parse(
        'https://api.themoviedb.org/3/$type/$id?api_key=$apiKey&language=fr-FR&append_to_response=watch/providers,next_episode_to_air');

    try {
      final response = await http.get(url);

      // 1. Récupérer les infos Firestore
      if (userId != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).collection('watchlist').doc(id).get();
        if (doc.exists) {
          final firestoreData = doc.data() as Map<String, dynamic>;
          setState(() {
            isInWatchlist = true;
            seenEpisodesIds = List<String>.from(firestoreData['seenEpisodes'] ?? []);
            seenKeys = List<String>.from(firestoreData['seenKeys'] ?? []);
            if (!isSeries) isMovieSeen = firestoreData['isFinished'] ?? false;
          });
        }
      }

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        
        // --- NOUVEAUTÉ : On charge les épisodes AVANT de couper le chargement ---
        if (isSeries) {
          // On attend que les épisodes de la saison 1 arrivent
          await _fetchEpisodes(1); 
        }

        setState(() {
          fullData = decodedData;
          isLoading = false; // Maintenant on peut afficher la page, tout est prêt !
        });

        // Mise à jour de la date "À venir" (Calendrier)
        if (userId != null && isInWatchlist) {
        _updateReleaseDates(decodedData, isSeries, id, userId);
      }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Petite fonction pour ranger proprement la mise à jour des dates
  Future<void> _updateReleaseDates(Map decodedData, bool isSeries, String id, String userId) async {
    String? nextDate;
    String? nextLabel;

    if (isSeries) {
      final nextEp = decodedData['next_episode_to_air'];
      if (nextEp != null) {
        nextDate = nextEp['air_date'];
        nextLabel = "S${nextEp['season_number']}E${nextEp['episode_number']} - ${nextEp['name']}";
      }
    } else {
      nextDate = decodedData['release_date'];
    }

    if (nextDate != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('watchlist').doc(id).update({
        'nextAirDate': nextDate,
        'nextAirLabel': nextLabel,
        if (isSeries) 'totalEpisodes': decodedData['number_of_episodes'],
      });
    }
  }

  Future<void> _fetchEpisodes(int seasonNumber) async {
    setState(() { isLoadingEpisodes = true; selectedSeason = seasonNumber; });
    final url = Uri.parse('https://api.themoviedb.org/3/tv/${widget.movie['id']}/season/$seasonNumber?api_key=$apiKey&language=fr-FR');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          episodes = json.decode(response.body)['episodes'] ?? [];
          isLoadingEpisodes = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingEpisodes = false);
    }
  }

  Future<void> _fetchCredits() async {
    final String id = widget.movie['id'].toString();
    final bool isSeries = widget.movie['mediaType'] == "SÉRIES" || widget.movie['media_type'] == 'tv' || widget.movie.containsKey('first_air_date') || widget.movie.containsKey('name');
    final String type = isSeries ? 'tv' : 'movie';
    final url = Uri.parse('https://api.themoviedb.org/3/$type/$id/credits?api_key=$apiKey&language=fr-FR');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => cast = json.decode(response.body)['cast'] ?? []);
      }
    } catch (e) { print("Erreur casting: $e"); }
  }

  Future<void> _toggleWatchlist() async {
    final movieId = widget.movie['id'].toString();
    if (isInWatchlist) {
      await DatabaseService().removeMovie(movieId);
      setState(() { isInWatchlist = false; seenEpisodesIds.clear(); seenKeys.clear(); isMovieSeen = false; });
    } else {
      await DatabaseService().addToWatchlist(
        Map<String, dynamic>.from(widget.movie),
      );

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final bool isSeries = widget.movie.containsKey('first_air_date') || widget.movie['mediaType'] == "SÉRIES";
      
      if (fullData != null && userId != null) {
         await _updateReleaseDates(fullData!, isSeries, movieId, userId);
      }

      setState(() => isInWatchlist = true);
    }
  }

  void _showOptionsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.star_outline, color: Colors.white), title: const Text("Noter", style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.favorite_border, color: Colors.white), title: const Text("Ajouter aux favoris", style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.photo_library, color: Colors.white), title: const Text("Voir les affiches", style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.share, color: Colors.white), title: const Text("Partager", style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- NOUVEAUX WIDGETS MIS À JOUR ---

  Widget _buildProviders() {
    final providers = fullData?['watch/providers']?['results']?['FR']?['flatrate'];
    if (providers == null || (providers as List).isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Disponible sur :", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network("https://image.tmdb.org/t/p/w200${providers[index]['logo_path']}", width: 45, height: 45),
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildMovieButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isMovieSeen ? Colors.green : Colors.deepPurpleAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        icon: Icon(isMovieSeen ? Icons.check_circle : Icons.visibility, color: Colors.white),
        label: Text(isMovieSeen ? "Film vu" : "Marquer comme vu", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () async {
          if (!isInWatchlist) await _toggleWatchlist();
          setState(() => isMovieSeen = !isMovieSeen);
          await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('watchlist').doc(widget.movie['id'].toString()).update({
            'isFinished': isMovieSeen, 'isInProgress': false,
          });
        },
      ),
    );
  }

  Widget _buildCasting() {
    if (cast.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        const Text("Casting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final actor = cast[index];
              return Container(
                width: 100, margin: const EdgeInsets.only(right: 15),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                        child: actor['profile_path'] != null
                          ? Image.network(
                              "https://image.tmdb.org/t/p/w200${actor['profile_path']}",
                              width: 80, // <-- Dimensions fixes
                              height: 80, // <-- Dimensions fixes
                              fit: BoxFit.cover)
                          : Container(
                              width: 80, // <-- Dimensions fixes
                              height: 80, // <-- Dimensions fixes
                              color: Colors.grey[800],
                              child: const Icon(Icons.person)),
                    ),
                    const SizedBox(height: 8),
                    Text(actor['name'], textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(actor['character'], textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSynopsisAndCast() {
    final displayMovie = fullData ?? widget.movie;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildProviders(), 
        const Text("Synopsis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => isSynopsisExpanded = !isSynopsisExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayMovie['overview'] ?? "Aucun synopsis disponible.",
                style: const TextStyle(fontSize: 16, height: 1.4),
                maxLines: isSynopsisExpanded ? null : 2,
                overflow: isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (displayMovie['overview'] != null && displayMovie['overview'].length > 100)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(isSynopsisExpanded ? "Réduire" : "Lire la suite", style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
            ],
          ),
        ),
        _buildCasting(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMovie = fullData ?? widget.movie;
    final bool isSeries = widget.movie['mediaType'] == "SÉRIES" || widget.movie['media_type'] == 'tv' || widget.movie.containsKey('first_air_date') || widget.movie.containsKey('name');

    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          Row(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: IconButton(icon: Icon(isInWatchlist ? Icons.bookmark : Icons.bookmark_add_outlined, color: isInWatchlist ? Colors.deepPurpleAccent : Colors.white), onPressed: _toggleWatchlist)),
              const SizedBox(width: 10),
              Container(margin: const EdgeInsets.only(right: 15, top: 8, bottom: 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () => _showOptionsPanel(context))),
            ],
          ),
        ],
      ),
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels < -100 && !isClosing) {
            setState(() => isClosing = true); Navigator.pop(context); return true;
          }
          return false;
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network('https://image.tmdb.org/t/p/w500${displayMovie['backdrop_path'] ?? displayMovie['poster_path']}', width: double.infinity, height: 300, fit: BoxFit.cover),
                  Positioned(bottom: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)), child: Text("TMDB ${(displayMovie['vote_average'] ?? 0.0).toStringAsFixed(1)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayMovie['title'] ?? displayMovie['name'] ?? 'Titre inconnu', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Sortie : ${displayMovie['release_date'] ?? displayMovie['first_air_date'] ?? 'Inconnue'}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text("Durée : ${isSeries ? (fullData != null ? "${fullData!['number_of_seasons']} saisons (${(fullData!['episode_run_time'] != null && fullData!['episode_run_time'].isNotEmpty) ? fullData!['episode_run_time'][0] : 'N/A'} min/ép)" : "Chargement...") : (displayMovie['runtime'] != null ? "${displayMovie['runtime']} min" : "N/A")}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 15),

                    if (displayMovie['genres'] != null)
                      Wrap(spacing: 8, runSpacing: 4, children: (displayMovie['genres'] as List).map((genre) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5))), child: Text(genre['name'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)))).toList()),

                    // CAS D'UN FILM
                    if (!isSeries) ...[
                      const SizedBox(height: 25),
                      _buildMovieButton(),
                      _buildSynopsisAndCast(),
                    ],

                    // CAS D'UNE SÉRIE
                    if (isSeries && fullData != null) ...[
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = 0), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedTab == 0 ? Colors.deepPurpleAccent : Colors.transparent, width: 3))), child: Center(child: Text("INFOS", style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTab == 0 ? Colors.white : Colors.grey)))))),
                          Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = 1), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedTab == 1 ? Colors.deepPurpleAccent : Colors.transparent, width: 3))), child: Center(child: Text("ÉPISODES", style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTab == 1 ? Colors.white : Colors.grey)))))),
                        ],
                      ),
                      
                      if (_selectedTab == 0) _buildSynopsisAndCast(),
                      
                      if (_selectedTab == 1) ...[
                        const SizedBox(height: 20),
                        SizedBox(height: 40, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: fullData!['number_of_seasons'] ?? 0, itemBuilder: (context, index) { int sNum = index + 1; return Padding(padding: const EdgeInsets.only(right: 10), child: ChoiceChip(label: Text("Saison $sNum"), selected: selectedSeason == sNum, selectedColor: Colors.deepPurpleAccent, onSelected: (selected) => _fetchEpisodes(sNum))); })),
                        const SizedBox(height: 20),
                        ListView.builder(padding: EdgeInsets.zero, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: episodes.length, itemBuilder: (context, index) {
                          final ep = episodes[index];
                          final String epId = ep['id'].toString();
                          final String epKey = "S${selectedSeason}E${ep['episode_number']}";
                          bool isSeen = seenKeys.contains(epKey);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(borderRadius: BorderRadius.circular(5), child: ep['still_path'] != null ? Image.network("https://image.tmdb.org/t/p/w200${ep['still_path']}", width: 80, fit: BoxFit.cover) : Container(width: 80, color: Colors.grey[800], child: const Icon(Icons.tv))),
                            title: Text("E${ep['episode_number']} - ${ep['name']}"), subtitle: Text(ep['overview'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: Icon(isSeen ? Icons.check_circle : Icons.check_circle_outline, color: isSeen ? Colors.green : Colors.grey),
                              onPressed: () async {
                                if (!isInWatchlist) await _toggleWatchlist();
                                bool newStatus = !isSeen;
                                setState(() { 
                                  if (newStatus) { 
                                    seenEpisodesIds.add(epId); 
                                    seenKeys.add(epKey); 
                                  } else { 
                                    seenEpisodesIds.remove(epId); 
                                    seenKeys.remove(epKey); 
                                  } 
                                });

                                int maxS = 0; int maxE = 0;
                                for (String key in seenKeys) { 
                                  RegExp regExp = RegExp(r'S(\d+)E(\d+)'); 
                                  Match? match = regExp.firstMatch(key); 
                                  if (match != null) { 
                                    int s = int.parse(match.group(1)!); 
                                    int e = int.parse(match.group(2)!); 
                                    if (s > maxS || (s == maxS && e > maxE)) { maxS = s; maxE = e; } 
                                  } 
                                }
                                
                                int nextS = 1; int nextE = 1; bool isFinished = false;
                                if (seenKeys.isNotEmpty && fullData != null && fullData!['seasons'] != null) {
                                  List seasonsList = List.from(fullData!['seasons']); 
                                  seasonsList.sort((a, b) => a['season_number'].compareTo(b['season_number']));
                                  nextS = maxS; nextE = maxE + 1; bool found = false;
                                  while (!found) {
                                    var currentSData = seasonsList.firstWhere((s) => s['season_number'] == nextS, orElse: () => null);
                                    if (currentSData != null) {
                                      int totalInSeason = currentSData['episode_count'] ?? 0;
                                      if (nextE <= totalInSeason && totalInSeason > 0) { 
                                        found = true; 
                                      } else { 
                                        nextS++; nextE = 1; 
                                        if (!seasonsList.any((s) => s['season_number'] == nextS)) { isFinished = true; found = true; } 
                                      }
                                    } else { isFinished = true; found = true; }
                                  }
                                }

                                bool isInProgress = seenKeys.isNotEmpty && !isFinished;

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('watchlist')
                                    .doc(widget.movie['id'].toString())
                                    .update({
                                  'isInProgress': isInProgress,   
                                  'isFinished': isFinished,       
                                  'nextSeasonToSee': isFinished ? 0 : nextS,
                                  'nextEpisodeToSee': isFinished ? 0 : nextE,
                                  'seenEpisodes': newStatus ? FieldValue.arrayUnion([epId]) : FieldValue.arrayRemove([epId]),
                                  'seenKeys': newStatus ? FieldValue.arrayUnion([epKey]) : FieldValue.arrayRemove([epKey])
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}