import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/movie_list_screen.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}
// Une clé globale pour accéder à l'état de la liste de films
final GlobalKey<MovieListScreenState> movieListKey = GlobalKey<MovieListScreenState>();

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
          themeMode: currentMode, // Utilise le mode actuel
          
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
          
          home: const MainScreen(),
        );
      }
    );
  }
}