import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isVerticalLocked = true; 
  int _defaultPageIndex = 0; // Stocke l'onglet de démarrage (0: Accueil, 1: Liste, 2: Profil)

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Charger la préférence de page de démarrage au lancement de l'écran
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultPageIndex = prefs.getInt('default_page') ?? 0;
    });
  }

  // --- FENÊTRE PARAMÈTRES (ORIENTATION, THÈME, PAGE DÉFAUT) ---
  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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

                      // Toggle Vertical
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
                            setModalState(() {}); 
                          },
                        ),
                      ),

                      // Toggle Mode Sombre
                      ListTile(
                        leading: Icon(
                          isDarkInner ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.deepPurpleAccent,
                        ),
                        title: Text("Mode Sombre",
                            style: TextStyle(color: isDarkInner ? Colors.white : Colors.black)),
                        trailing: Switch(
                          value: isDarkInner,
                          activeColor: Colors.deepPurpleAccent,
                          onChanged: (bool value) {
                            themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                      ),

                      const Divider(),

                      // Choix de l'onglet par défaut
                      ListTile(
                        leading: const Icon(Icons.start, color: Colors.deepPurpleAccent),
                        title: Text("Page d'accueil par défaut", 
                            style: TextStyle(color: isDarkInner ? Colors.white : Colors.black)),
                        trailing: DropdownButton<int>(
                          value: _defaultPageIndex,
                          dropdownColor: isDarkInner ? const Color(0xFF2C2C2C) : Colors.white,
                          underline: const SizedBox(),
                          style: TextStyle(color: isDarkInner ? Colors.white : Colors.black),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text("Accueil")),
                            DropdownMenuItem(value: 1, child: Text("Ma Liste")),
                            DropdownMenuItem(value: 2, child: Text("Profil")),
                          ],
                          onChanged: (int? newValue) async {
                            if (newValue != null) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setInt('default_page', newValue);
                              
                              setModalState(() => _defaultPageIndex = newValue);
                              setState(() => _defaultPageIndex = newValue);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Préférence enregistrée !"), duration: Duration(seconds: 1)),
                                );
                              }
                            }
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
      },
    );
  }

  // --- FENÊTRE MON COMPTE (INFOS + DÉCONNEXION) ---
  void _showCompte(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurpleAccent,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
              ),
              const SizedBox(height: 20),
              Text(
                user?.displayName ?? "Utilisateur",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              Text(
                user?.email ?? "Non renseigné",
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await GoogleSignIn().signOut();
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Se déconnecter", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _showDeleteConfirmation(context),
                child: const Text("Supprimer mon compte définitivement", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer le compte ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(onPressed: () { Navigator.pop(context); _deleteAccount(context); }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              user?.displayName ?? "VIBE.",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildOption(context, icon: Icons.account_circle, title: "Mon Compte", subtitle: "Infos et déconnexion", onTap: () => _showCompte(context)),
                  _buildOption(context, icon: Icons.settings, title: "Paramètres", subtitle: "Affichage et démarrage", onTap: () => _showSettings(context)),
                  _buildOption(context, icon: Icons.bar_chart, title: "Statistiques", subtitle: "Mon temps de visionnage", onTap: () {}),
                  _buildOption(context, icon: Icons.emoji_events, title: "Mes badges", subtitle: "Récompenses débloquées", onTap: () {}),
                  _buildOption(context, icon: Icons.favorite, title: "Favoris", subtitle: "Mes films préférés", onTap: () {}),
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