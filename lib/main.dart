import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/media_provider.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const CliniqTvApp());
}

class CliniqTvApp extends StatelessWidget {
  const CliniqTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MediaProvider(),
      child: MaterialApp(
        title: 'CliniqTV',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(AppConstants.primaryColor),
          scaffoldBackgroundColor: const Color(AppConstants.backgroundColor),
          colorScheme: const ColorScheme.dark(
            primary: Color(AppConstants.primaryColor),
            secondary: Color(AppConstants.accentColor),
            surface: Color(AppConstants.surfaceColor),
          ),
          fontFamily: 'Roboto',
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
