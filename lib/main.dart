import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:interprep/common/constants/routes.dart';
import 'package:interprep/services/theme_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Check if onboarding has been seen - skip on web
  bool hasSeenOnboarding = false;
  if (!kIsWeb) {
    // Only check SharedPreferences on mobile/desktop
    try {
      final prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    } catch (e) {
      debugPrint('Error getting SharedPreferences: $e');
      hasSeenOnboarding = false;
    }
  }
  // On web, always default to false (show onboarding on first visit)
  
  runApp(
    ProviderScope(
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    // Initialize theme service
    final themeService = Get.put(ThemeService());
    
    // Check if user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    
    // Determine initial route
    String initialRoute;
    if (!hasSeenOnboarding) {
      initialRoute = '/onboarding';
    } else if (user != null) {
      initialRoute = '/home';
    } else {
      initialRoute = '/signup';
    }
    
    return Obx(() => GetMaterialApp(
      title: 'InterPrep',
      theme: themeService.getLightTheme(),
      darkTheme: themeService.getDarkTheme(),
      themeMode: themeService.themeMode.value,
      initialRoute: initialRoute,
      getPages: appRoutes(),
      debugShowCheckedModeBanner: false,
    ));
  }
}