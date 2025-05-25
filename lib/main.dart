import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/supabase_service.dart';
import 'app/data/repositories/user_repository.dart';
import 'app/data/repositories/book_comment_repository.dart';
import 'app/data/repositories/readlist_repository.dart';
import 'app/data/repositories/book_repository.dart';
import 'app/modules/book/controllers/inbox_controller.dart';
import 'app/modules/book/controllers/readlist_controller.dart';
import 'app/init_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase
    print('Initializing Supabase...');
    final service = await SupabaseService.initialize();
    print('Supabase initialized successfully: ${service.hashCode}');
    
    // Register repositories globally
    print('Registering repositories globally...');
    Get.put(UserRepository(), permanent: true);
    Get.put(BookRepository(), permanent: true);
    Get.put(BookCommentRepository(), permanent: true);
    Get.put(ReadlistRepository(), permanent: true);
    
    // Initialize controllers
    print('Initializing global controllers...');
    Get.put(InboxController(), permanent: true, tag: 'global_inbox');
    Get.put(ReadlistController(), permanent: true, tag: 'global_readlist');
    
    // Initialize database
    print('Initializing database...');
    await DatabaseInitializer.initializeDatabase();
  } catch (e) {
    print('Error during initialization: $e');
    // Continue with app launch as authentication might be handled in splash screen
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SAGE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4355B9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        brightness: Brightness.light,
        cardTheme: CardTheme(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B8FFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        cardTheme: CardTheme(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('id', 'ID'),
      ],
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
