import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // On crée une variable pour mémoriser l'état du bouton
  bool _isVerticalLocked = true; 
  bool _isDarkMode = true;

  
  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, child) {
            final isDarkInner = currentMode == ThemeMode.dark;
            
            return Container(
              decoration: BoxDecoration(
                color: isDarkInner ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Paramètres d'affichage",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDarkInner ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Option Vertical Lock
                  ListTile(
                    leading: const Icon(Icons.screen_lock_portrait, color: Colors.deepPurpleAccent),
                    title: Text("Forcer le mode Vertical", 
                      style: TextStyle(color: isDarkInner ? Colors.white : Colors.black)),
                    trailing: Switch(
                      value: _isVerticalLocked,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (bool value) {
                        if (value) {
                          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                        } else {
                          SystemChrome.setPreferredOrientations(DeviceOrientation.values);
                        }
                        setState(() => _isVerticalLocked = value);
                      },
                    ),
                  ),

                  // Option Mode Sombre
                  ListTile(
                    leading: Icon(
                      isDarkInner ? Icons.dark_mode : Icons.light_mode, 
                      color: Colors.deepPurpleAccent
                    ),
                    title: Text("Mode Sombre", 
                      style: TextStyle(color: isDarkInner ? Colors.white : Colors.black)),
                    trailing: Switch(
                      value: isDarkInner,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (bool value) {
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                        setState(() {
                          _isDarkMode = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStats(BuildContext context) {
    // TODO Stats
  }

  void _showBadges(BuildContext context) {
    // TODO Badges
  }

  void _showCompte(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Centrer les éléments horizontalement dans la colonne élargie
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurpleAccent,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "Utilisateur",
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color
                ),
              ),
              Text(
                "premium@cinema.com",
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200, 
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  child: const Text("Modifier mes infos", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showFavoris(BuildContext context) {
    // TODO Favoris
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              "Nom d'utilisateur",
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: theme.textTheme.titleLarge?.color
              )
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildOption(context, icon: Icons.account_circle, title: "Mon Compte", subtitle: "Gérer mes infos personnelles", onTap: () => _showCompte(context)),
                  _buildOption(context, icon: Icons.settings, title: "Paramètres", subtitle: "Affichage et orientation", onTap: () => _showSettings(context)),
                  _buildOption(context, icon: Icons.bar_chart, title: "Statistiques", subtitle: "Mon temps de visionnage", onTap: () {}),
                  _buildOption(context, icon: Icons.emoji_events, title: "Mes badges", subtitle: "Récompenses débloquées", onTap: () {}),
                  _buildOption(context, icon: Icons.favorite, title: "Favoris", subtitle: "Mes films et series favoris", onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],      
      margin: const EdgeInsets.only(bottom: 15),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}