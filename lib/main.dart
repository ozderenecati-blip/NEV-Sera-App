import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initializeDateFormatting('tr_TR', null);
  } catch (e) {
    print('Date formatting error: $e');
  }
  
  // Firebase'i başlat (hem web hem mobil için)
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        authDomain: FirebaseConfig.authDomain,
        projectId: FirebaseConfig.projectId,
        storageBucket: FirebaseConfig.storageBucket,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        appId: FirebaseConfig.appId,
        measurementId: FirebaseConfig.measurementId,
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  // Bildirim servisini başlat (sadece mobilde)
  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      print('Notification error: $e');
    }
  }
  
  // Login ve onboarding durumunu kontrol et
  bool isLoggedIn = false;
  bool onboardingCompleted = false;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  } catch (e) {
    print('SharedPreferences error: $e');
  }
  
  runApp(NevSeracilikApp(
    isLoggedIn: isLoggedIn,
    onboardingCompleted: onboardingCompleted,
  ));
}

class NevSeracilikApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool onboardingCompleted;
  
  const NevSeracilikApp({
    super.key, 
    required this.isLoggedIn,
    required this.onboardingCompleted,
  });

  Widget _getInitialScreen() {
    if (!onboardingCompleted) {
      return const OnboardingScreen();
    } else if (!isLoggedIn) {
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..loadAllData()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'NEV Seracılık',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            home: _getInitialScreen(),
          );
        },
      ),
    );
  }
}
