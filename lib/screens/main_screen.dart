import 'package:flutter/material.dart';
import '../main.dart';
import 'movie_list_screen.dart'; 
import 'profile_screen.dart';
import 'watchlist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

//GESTIONNAIRE DE NAVIGATION
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDefaultPage(); // Charger l'onglet par défaut au lancement
  }

  Future<void> _loadDefaultPage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 0 est la valeur par défaut si rien n'est enregistré
      _selectedIndex = prefs.getInt('default_page') ?? 0;
    });
  }
  
  final List<Widget> _pages = [
    MovieListScreen(key: movieListKey), 
    const WatchlistScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          // Couleur dynamique du fond de la barre
          color: isDark 
              ? const Color(0xFF1F1F1F).withOpacity(0.9) 
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
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
            unselectedItemColor: isDark ? Colors.white54 : Colors.black38,
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index == 0 && _selectedIndex == 0) {
                movieListKey.currentState?.resetToHome();
              }
              setState(() => _selectedIndex = index);
            },
            items: const [
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
