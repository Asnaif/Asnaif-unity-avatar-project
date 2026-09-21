// import 'package:flutter/material.dart';
// import 'package:interprep/common/constants/styles.dart';

// class Themes {
//   static ThemeData lightThemeData() {
//     final baseTheme = ThemeData(
//       brightness: Brightness.light,
//       primaryColor: Styles.primaryColor,
//       scaffoldBackgroundColor: Styles.backgroundColor,
//       bottomSheetTheme:
//           BottomSheetThemeData(backgroundColor: Styles.primaryColor),
//       useMaterial3: true,
//     );
    
//     // Apply Outfit font to text but NOT to icons
//     return baseTheme.copyWith(
//       textTheme: baseTheme.textTheme.apply(
//         fontFamily: "Outfit",
//       ),
//       // Icons should use default Material Icons font, not Outfit
//       iconTheme: baseTheme.iconTheme,
//     );
//   }

// // dark Theme
//   static ThemeData darkThemeData() {
//     final baseTheme = ThemeData(
//       brightness: Brightness.dark,
//       primaryColor: Styles.primaryColor,
//       scaffoldBackgroundColor: Styles.backgroundColor,
//       bottomSheetTheme:
//           BottomSheetThemeData(backgroundColor: Styles.backgroundColor),
//       useMaterial3: true,
//     );
    
//     // Apply Outfit font to text but NOT to icons
//     return baseTheme.copyWith(
//       textTheme: baseTheme.textTheme.apply(
//         fontFamily: "Outfit",
//       ),
//       // Icons should use default Material Icons font, not Outfit
//       iconTheme: baseTheme.iconTheme,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';

class Themes {
  static ThemeData lightThemeData() {
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: Styles.primaryColor,
      scaffoldBackgroundColor: Styles.backgroundColor,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Styles.primaryColor,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(  // Changed from CardTheme
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Styles.primaryColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
    
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamily: "Outfit",
      ),
    );
  }

  static ThemeData darkThemeData() {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Styles.primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Styles.primaryColor,
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(  // Changed from CardTheme
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:  Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
      ),
    );
    
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamily: "Outfit",
      ),
    );
  }
}