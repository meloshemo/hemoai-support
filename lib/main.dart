import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/personal_info_screen.dart';
import 'screens/hemogram_entry_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/diet_program_screen.dart';
import 'screens/family_panel_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/alternative_medicine_screen.dart';
import 'screens/test_login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(HemoAIApp());
}

class HemoAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEMOAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/guest': (context) => GuestScreen(),
        '/personal_info': (context) => PersonalInfoScreen(),
        '/hemogram_entry': (context) => HemogramEntryScreen(),
        '/analysis': (context) => AnalysisScreen(),
        '/diet_program': (context) => DietProgramScreen(),
        '/family_panel': (context) => FamilyPanelScreen(),
        '/notifications': (context) => NotificationScreen(),
        '/alternative_medicine': (context) => AlternativeMedicineScreen(),
        '/test_login': (context) => TestLoginScreen(),
      },
      supportedLocales: [
        Locale('tr', ''), // Türkçe
        Locale('en', ''), // İngilizce
        Locale('es', ''), // İspanyolca
        Locale('fr', ''), // Fransızca
        Locale('de', ''), // Almanca
        Locale('ru', ''), // Rusça
        Locale('ar', ''), // Arapça
        Locale('zh', ''), // Çince
      ],
      locale: Locale('tr', ''), // Varsayılan Türkçe
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
