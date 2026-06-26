import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telephony/telephony.dart';
import 'screens/main_navigation.dart';
import 'utils/sms_validator.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 1. Add this import

// 2. Update the background handler
@pragma('vm:entry-point')
backgroundMessageHandler(SmsMessage message) async {
  debugPrint("Background SMS received from: ${message.address}");

  if (SmsValidator.isBankTransaction(message.address, message.body)) {
    debugPrint("Valid Bank SMS caught in background. Saving to Hive...");
    
    // Initialize Hive for this specific background memory space
    await Hive.initFlutter(); 
    
    // Open the box and save the raw SMS text
    var box = await Hive.openBox<String>('pending_sms');
    await box.add(message.body ?? ''); 
    
    debugPrint("Saved successfully!");
  }
}

void main() async { // 3. Make main async
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 4. Initialize Hive for the main app
  await Hive.initFlutter();
  
  // 5. Open the box so the app can read it right away when it starts
  await Hive.openBox<String>('pending_sms'); 

  runApp(const SalliMateApp());
}

class SalliMateApp extends StatelessWidget {
  const SalliMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SalliMate Prototype',
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
      home: const MainNavigation(),
    );
  }
}
