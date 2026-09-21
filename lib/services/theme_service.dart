import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interprep/common/constants/theme.dart';

class ThemeService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final themeString = userDoc.data()?['themeMode'] as String?;
          if (themeString != null) {
            switch (themeString) {
              case 'dark':
                themeMode.value = ThemeMode.dark;
                break;
              case 'light':
                themeMode.value = ThemeMode.light;
                break;
              case 'system':
                themeMode.value = ThemeMode.system;
                break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      themeMode.value = mode;
      
      final user = _auth.currentUser;
      if (user != null) {
        String themeString;
        switch (mode) {
          case ThemeMode.dark:
            themeString = 'dark';
            break;
          case ThemeMode.light:
            themeString = 'light';
            break;
          case ThemeMode.system:
            themeString = 'system';
            break;
        }
        
        await _firestore.collection('users').doc(user.uid).update({
          'themeMode': themeString,
        });
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
  
  ThemeData getLightTheme() => Themes.lightThemeData();
  ThemeData getDarkTheme() => Themes.darkThemeData();
}