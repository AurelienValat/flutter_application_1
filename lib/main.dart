import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/movie_list_screen.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

final GlobalKey<MovieListScreenState> movieListKey =
    GlobalKey<MovieListScreenState>();

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          // THÈME CLAIR
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: Colors.white,
          ),

          // THÈME SOMBRE
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          ),

          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return const MainScreen(); // L'utilisateur est connecté
              }
              return const AuthScreen(); // L'utilisateur n'est pas connecté
            },
          ),
        );
      },
    );
  }
}
