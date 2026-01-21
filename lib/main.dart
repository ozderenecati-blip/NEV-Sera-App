import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  
  // Bildirim servisini başlat
  await NotificationService().initialize();
  
  // Login ve onboarding durumunu kontrol et
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  
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
