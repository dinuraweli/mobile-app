// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telephony/telephony.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_navigation.dart';
import 'screens/auth_screen.dart';
import 'utils/sms_validator.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/financial_config_service.dart';
import 'models/user.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  debugPrint("Background SMS received from: ${message.address}");

  if (SmsValidator.isBankTransaction(message.address, message.body)) {
    debugPrint("Valid Bank SMS caught in background. Saving to Hive...");
    
    await Hive.initFlutter();
    var box = await Hive.openBox<String>('pending_sms');
    await box.add(message.body ?? '');
    
    debugPrint("Saved successfully!");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox<String>('pending_sms');
  await DatabaseService().initialize();
  await FinancialConfigService().initialize();
  
  runApp(const SalliMateApp());
}

class SalliMateApp extends StatefulWidget {
  const SalliMateApp({super.key});

  @override
  State<SalliMateApp> createState() => _SalliMateAppState();
}

class _SalliMateAppState extends State<SalliMateApp> {
  AppUser? _currentUser;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _testFinancialConfig(); // TEMPORARY - remove after testing
  }

  Future<void> _checkAuthStatus() async {
    final authService = AuthService();
    final loggedInUser = await authService.checkLoggedInUser();
    
    if (mounted) {
      setState(() {
        _currentUser = loggedInUser;
        _isCheckingAuth = false;
      });
    }
  }

  // TEMPORARY - Remove after testing
  Future<void> _testFinancialConfig() async {
    await Future.delayed(const Duration(seconds: 3));
    
    try {
      final configService = FinancialConfigService();
      final config = await configService.getConfig();
      
      debugPrint('═══════════════════════════════════');
      debugPrint('📊 FINANCIAL CONFIG TEST');
      debugPrint('═══════════════════════════════════');
      debugPrint('Version: ${config.version}');
      debugPrint('Source: ${config.sourceLabel}');
      debugPrint('Tax-Free Allowance: ${config.taxFreeAllowance}');
      debugPrint('Tax Brackets: ${config.taxBrackets.length} brackets');
      debugPrint('EPF Employee Rate: ${config.epfEmployeeRate}');
      debugPrint('Banks: ${config.bankLeasingRates.keys.toList()}');
      debugPrint('═══════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Config test failed: $e');
    }
  }

  void _onLoginSuccess(AppUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _onLogout() async {
    if (_currentUser != null) {
      await AuthService().logout(_currentUser!);
    }
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0B0C10),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66FCF1), Color(0xFF45A29E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('SM', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0B0C10))),
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Color(0xFF66FCF1)),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'SalliMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0C10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF66FCF1),
          secondary: Color(0xFF45A29E),
          surface: Color(0xFF1F2833),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: const Color(0xFFC5C6C7),
          displayColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F2833),
          elevation: 8,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: _currentUser != null
          ? MainNavigation(currentUser: _currentUser!, onLogout: _onLogout)
          : AuthScreen(onLoginSuccess: _onLoginSuccess),
    );
  }
}