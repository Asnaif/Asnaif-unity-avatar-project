import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:introduction_screen/introduction_screen.dart';
import 'package:get/get.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to InterPrep",
          body: "Practice your communication skills with AI-powered feedback",
          image: _buildImage(),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Practice Presentations",
          body: "Upload your slides and practice presentations with real-time feedback",
          image: _buildImage(),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Ace Interviews",
          body: "Upload your resume and practice interview questions tailored to your profile",
          image: _buildImage(),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Get AI Feedback",
          body: "Receive detailed feedback on pitch, sentiment, vocabulary, and more",
          image: _buildImage(),
          decoration: _getPageDecoration(),
        ),
      ],
      onDone: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_onboarding', true);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Get.offNamed('/home');
        } else {
          Get.offNamed('/signup');
        }
      },
      onSkip: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_onboarding', true);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Get.offNamed('/home');
        } else {
          Get.offNamed('/signup');
        }
      },
      showSkipButton: true,
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size(10, 10),
        color: Colors.grey,
        activeColor: Styles.primaryColor,
        activeSize: const Size(22, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // For web, use a fallback icon directly to avoid asset loading issues
    if (kIsWeb) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Styles.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.school,
          size: 100,
          color: Styles.primaryColor,
        ),
      );
    }

    // For mobile platforms, try to load the asset
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to an icon if the image fails to load
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Styles.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              size: 100,
              color: Styles.primaryColor,
            ),
          );
        },
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      bodyTextStyle: TextStyle(fontSize: 16),
      bodyPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      imagePadding: EdgeInsets.all(20),
    );
  }
}