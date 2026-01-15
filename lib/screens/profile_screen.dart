import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
        // Le StatefulBuilder permet de rafraîchir le Switch instantanément
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

                      // Option Vertical Lock
                      ListTile(
                        leading: const Icon(Icons.screen_lock_portrait, color: Colors.deepPurpleAccent),
                        title: Text(
                          "Forcer le mode Vertical",
                          style: TextStyle(color: isDarkInner ? Colors.white : Colors.black),
                        ),
                        trailing: Switch(
                          value: _isVerticalLocked,
                          activeColor: Colors.deepPurpleAccent,
                          onChanged: (bool value) {
                            if (value) {
                              SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                            } else {
                              SystemChrome.setPreferredOrientations(DeviceOrientation.values);
                            }
                            
                            // On met à jour l'état de la page ET de la modale
                            setState(() => _isVerticalLocked = value);
                            setModalState(() {}); 
                          },
                        ),
                      ),

                      // Option Mode Sombre
                      ListTile(
                        leading: Icon(
                          isDarkInner ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.deepPurpleAccent,
                        ),
                        title: Text(
                          "Mode Sombre",
                          style: TextStyle(color: isDarkInner ? Colors.white : Colors.black),
                        ),
                        trailing: Switch(
                          value: isDarkInner,
                          activeColor: Colors.deepPurpleAccent,
                          onChanged: (bool value) {
                            // Le ValueListenableBuilder s'occupe de redessiner ici
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
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      isScrollControlled: true, // Pour éviter que le contenu soit coupé
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
              
              // BOUTON DÉCONNEXION
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

              // BOUTON SUPPRIMER LE COMPTE
              TextButton(
                onPressed: () => _showDeleteConfirmation(context),
                child: const Text(
                  "Supprimer mon compte définitivement",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

// Fenêtre de confirmation avant suppression
void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer le compte ?"),
        content: const Text("Cette action est irréversible. Toutes vos données seront perdues."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              _deleteAccount(context); // Lancer la suppression
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFavoris(BuildContext context) {
    // TODO Favoris
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        await user.delete();
        
        if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte supprimé avec succès."),
            backgroundColor: Colors.green,
          ),
        );
      }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Firebase demande une reconnexion si la session est trop ancienne pour supprimer le compte
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez vous reconnecter avant de supprimer votre compte.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
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

  

  Widget _buildOption(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
    bool isDestructive = false, // Nouvelle option
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Si c'est destructif, on met du rouge, sinon la couleur habituelle
    final Color mainColor = isDestructive ? Colors.redAccent : Colors.deepPurpleAccent;

    return Card(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],      
      margin: const EdgeInsets.only(bottom: 15),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: mainColor),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDestructive ? Colors.redAccent : null,
          )
        ),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDestructive ? Colors.redAccent : null),
        onTap: onTap,
      ),
    );
  }
}