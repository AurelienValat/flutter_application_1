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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // StatefulBuilder permet de mettre à jour le Switch à l'intérieur de la fenêtre surgissante
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Paramètres d'affichage", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.screen_lock_portrait, color: Colors.deepPurpleAccent),
                    title: const Text("Forcer le mode Vertical"),
                    trailing: Switch(
                      value: _isVerticalLocked,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (bool value) {
                        // 1. On met à jour l'orientation réelle du téléphone
                        if (value) {
                          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                        } else {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                        }
                        
                        // 2. On met à jour l'interface (le bouton change de position)
                        setModalState(() {
                          _isVerticalLocked = value;
                        });
                        setState(() {
                          _isVerticalLocked = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    leading: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode, 
                      color: Colors.deepPurpleAccent
                    ),
                    title: const Text("Mode Sombre"),
                    trailing: Switch(
                      value: _isDarkMode,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (bool value) {
                        setModalState(() {
                          _isDarkMode = value;
                        });
                        // On change le thème global
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.deepPurpleAccent,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              "Utilisateur",
              style: TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color, // Dynamique
              )
            ),
            Text(
              "premium@cinema.com",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54), // Dynamique
            ),           
            const SizedBox(height: 40),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildProfileOption(
                    context,
                    icon: Icons.settings,
                    title: "Paramètres",
                    subtitle: "Affichage et orientation",
                    onTap: () => _showSettings(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],      
      margin: const EdgeInsets.only(bottom: 15),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}