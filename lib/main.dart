import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Import your screens
import 'screens/intro_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/document_screen.dart';
import 'screens/settings_screen.dart';

import 'utils/theme_notifier.dart'; // Import the ThemeNotifier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved theme mode from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(isDarkMode ? ThemeMode.dark : ThemeMode.light),
      child: const ShadowDocsApp(),
    ),
  );
}

class ShadowDocsApp extends StatelessWidget {
  const ShadowDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    var themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'ShadowDocs',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const InitializerWidget(),
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/document': (context) => const DocumentScreen(
          shadowId: '',
          template: '',
        ),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class InitializerWidget extends StatefulWidget {
  const InitializerWidget({super.key});

  @override
  State<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  Future<void> _initializeApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;
    if (isFirstRun) {
      prefs.setBool('isFirstRun', false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IntroScreen(
            onFinish: () => Navigator.pushReplacementNamed(context, '/setup'),
          ),
        ),
      );
    } else {
      // Check if userId exists to determine if setup is complete
      String? userId = prefs.getString('userId');
      if (userId == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/setup');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show a splash screen or loading indicator
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo.png', // Use your splash image here
          width: 200,
        ),
      ),
    );
  }
}
