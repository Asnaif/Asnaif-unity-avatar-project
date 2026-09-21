import 'package:get/get.dart';
import 'package:interprep/screens/audio_upload/ui_audio_upload_screen.dart';
// import 'package:interprep/screens/feedback/ui_feedback_screen.dart' as old_feedback;
import 'package:interprep/screens/feedback/ui_new_feedback_screen.dart';
import 'package:interprep/screens/start_session/ui_start_session.dart';
import 'package:interprep/screens/start_session/widgets/industry_selection/ui_industry_selection.dart';
import 'package:interprep/screens/login/ui_login_screen.dart';
import 'package:interprep/screens/start_session/widgets/mode_type/ui_mode_type_screen.dart';
import 'package:interprep/screens/signup/ui_signup_screen.dart';
import 'package:interprep/screens/fetched_questions/ui_fetch_questions_screen.dart';
import 'package:interprep/screens/start_session/widgets/mode_type/widgets/interview_questions.dart';
import 'package:interprep/screens/practice_session/practice_session_screen.dart';
import 'package:interprep/screens/gamification/gamification_screen.dart';
import 'package:interprep/screens/analytics/analytics_screen.dart';
import 'package:interprep/screens/learning_path/learning_path_screen.dart';
import 'package:interprep/screens/community/community_screen.dart';
import 'package:interprep/screens/templates/templates_screen.dart';
import 'package:interprep/screens/benchmarks/benchmarks_screen.dart';
import 'package:interprep/screens/integrations/integrations_screen.dart';
import 'package:interprep/screens/home/home_screen.dart';
import 'package:interprep/screens/user_dashboard/user_dashboard_screen.dart';
import 'package:interprep/screens/admin_dashboard/admin_dashboard_screen.dart';
import 'package:interprep/screens/profile/ui_profile_screen.dart';
import 'package:interprep/screens/onboarding/onboarding_screen.dart';
// VAPI Real-Time Interview
import 'package:interprep/screens/vapi_interview/vapi_interview_screen.dart';
import 'package:interprep/screens/vapi_interview/vapi_feedback_screen.dart';
// import 'package:get/get.dart';
import 'package:flutter/material.dart';

appRoutes() => [
  GetPage(
    name: '/onboarding',
    page: () => const OnboardingScreen(),
    transition: Transition.rightToLeftWithFade,
    transitionDuration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  ),
      GetPage(
        name: '/home',
        page: () => const HomeScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/user_dashboard',
        page: () => const UserDashboardScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/profile',
        page: () => const ProfileScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/admin_dashboard',
        page: () => const AdminDashboardScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/signup',
        page: () => const SignUpScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/login',
        page: () => const LoginScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/industry_selection',
        page: () => const IndustrySelectionScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/mode_type',
        page: () => const ModeTypeScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/audio_upload',
        page: () => const AudioUploadScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/generated_questions',
        page: () => const GeneratedQuestionsScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      // GetPage(
      //   name: '/feedback',
      //   page: () => const old_feedback.NewFeedBackScreen(),
      //   transition: Transition.fadeIn,
      //   transitionDuration: const Duration(milliseconds: 300),
      // ),
      GetPage(
        name: '/new_feedback',
        page: () => const NewFeedBackScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/practice_session',
        page: () => const PracticeSessionScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      // GetPage(
      //   name: '/migrate_to_vr',
      //   page: () => PracticeSessionScreen(),
      //   transition: Transition.fadeIn,
      //   transitionDuration: const Duration(milliseconds: 300),
      // ),
      GetPage(
        name: '/start_session',
        page: () => const StartSessionScreen(
          isPresentation: true,
        ),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/interview_questions',
        page: () => const InterviewQuestions(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/gamification',
        page: () => const GamificationScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/analytics',
        page: () => const AnalyticsScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/learning_path',
        page: () => const LearningPathScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/community',
        page: () => const CommunityScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/templates',
        page: () => const TemplatesScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/benchmarks',
        page: () => const BenchmarksScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/integrations',
        page: () => const IntegrationsScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      // VAPI Real-Time Interview Routes
      GetPage(
        name: '/vapi_interview',
        page: () => const VapiInterviewScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      GetPage(
        name: '/vapi_feedback',
        page: () => const VapiFeedbackScreen(),
        transition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
    ];
