import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false; // Pour afficher un chargement

  // Fonction pour connexion Google
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur Google : $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Fonction pour Email/Password
  Future<void> _authenticate() async {
    final input = _emailController.text.trim(); // Ce que l'utilisateur a tapé (mail ou pseudo)
    final password = _passwordController.text.trim();
    final pseudo = _nameController.text.trim();

    if (!isLogin && pseudo.isEmpty) {
      _showSnackBar("Veuillez choisir un pseudo", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      String emailToUse = input;

      if (isLogin) {
        // SI C'EST UNE CONNEXION : On vérifie si l'input est un email ou un pseudo
        if (!input.contains('@')) {
          // Ce n'est pas un email, on cherche le pseudo dans Firestore
          final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('pseudo', isEqualTo: input)
              .limit(1)
              .get();

          if (userQuery.docs.isEmpty) {
            throw FirebaseAuthException(code: 'user-not-found', message: "Pseudo introuvable.");
          }
          
          // On récupère le vrai email associé à ce pseudo
          emailToUse = userQuery.docs.first.get('email');
        }

        // Connexion finale avec l'email trouvé
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailToUse,
          password: password,
        );
      } else {
        // SI C'EST UNE INSCRIPTION : On vérifie d'abord si le pseudo existe déjà
        final existingPseudo = await FirebaseFirestore.instance
            .collection('users')
            .where('pseudo', isEqualTo: pseudo)
            .get();

        if (existingPseudo.docs.isNotEmpty) {
          throw FirebaseAuthException(code: 'pseudo-already-used', message: "Ce pseudo est déjà pris.");
        }

        // Création classique
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailToUse,
          password: password,
        );

        await userCredential.user?.updateDisplayName(pseudo);

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'pseudo': pseudo,
          'email': emailToUse,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _handleAuthError(e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, [Color color = Colors.redAccent]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  void _handleAuthError(Object e) {
    String errorMessage = "Une erreur est survenue. Veuillez réessayer.";

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "Aucun utilisateur trouvé avec cet identifiant.";
          break;
        case 'wrong-password':
          errorMessage = "Mot de passe incorrect.";
          break;
        case 'email-already-in-use':
          errorMessage = "Cet email est déjà utilisé.";
          break;
        case 'pseudo-already-used':
          errorMessage = "Ce pseudo est déjà pris.";
          break;
        case 'invalid-email':
          errorMessage = "L'adresse email n'est pas valide.";
          break;
        case 'weak-password':
          errorMessage = "Le mot de passe est trop faible.";
          break;
      }
    }

    _showSnackBar(errorMessage);
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie_filter, size: 80, color: Colors.deepPurpleAccent),
              Text(
                "Vibe.",
                style: GoogleFonts.permanentMarker(
                  fontSize: 40,
                  color: Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                isLogin ? "Bon retour !" : "Créez votre compte",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
              ),
              const SizedBox(height: 30),
              
              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Pseudo",
                    hintText: "Comment devons-nous vous appeler ?",
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.face),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: isLogin ? "Email ou Pseudo" : "Email",
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 25),

              if (isLoading)
                const CircularProgressIndicator(color: Colors.deepPurpleAccent)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(isLogin ? "Se connecter" : "S'inscrire", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 15),
               SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F1F1F),
                      side: const BorderSide(color: Color(0xFF747775)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lien direct vers un PNG officiel pour éviter les erreurs de format
                        Image.network(
                          'https://pngimg.com/uploads/google/google_PNG19635.png',
                          height: 40,
                          width: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.account_circle, color: Colors.blue);
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Continuer avec Google",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Pas de compte ? Inscrivez-vous" : "Déjà un compte ? Connectez-vous"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}