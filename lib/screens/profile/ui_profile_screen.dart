import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/screens/profile/widgets/profile_header_tab.dart';
import 'package:interprep/screens/profile/widgets/statistics_tab.dart';
import 'package:interprep/screens/profile/widgets/achievements_tab.dart';
import 'package:interprep/screens/profile/widgets/session_history_tab.dart';
import 'package:interprep/screens/profile/widgets/goals_tab.dart';
import 'package:interprep/screens/profile/widgets/settings_tab.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _userEmail = '';
  String _userName = '';
  bool _isLoading = true;
  late TabController _tabController;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeListener() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
      });

      // Set up real-time listener
      _userSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final userData = snapshot.data()!;
          setState(() {
            _userEmail = user.email ?? '';
            _userName = userData['name'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _userEmail = user.email ?? '';
            _userName = '';
            _isLoading = false;
          });
        }
      }, onError: (error) {
        debugPrint('Error in real-time listener: $error');
        CustomToast.showError('Failed to load profile data');
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      Get.offNamed('/login');
    }
  }

  void _onNameUpdated(String newName) {
    setState(() {
      _userName = newName;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // Add modern app bar styling
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Styles.primaryColor,
                Styles.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person, color: Colors.white), text: 'Profile'),
            Tab(icon: Icon(Icons.analytics, color: Colors.white), text: 'Statistics'),
            Tab(icon: Icon(Icons.workspace_premium, color: Colors.white), text: 'Achievements'),
            Tab(icon: Icon(Icons.history, color: Colors.white), text: 'History'),
            Tab(icon: Icon(Icons.flag, color: Colors.white), text: 'Goals'),
            Tab(icon: Icon(Icons.settings, color: Colors.white), text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()  // Replace with shimmer
          : TabBarView(
              controller: _tabController,
              children: [
                // Wrap tabs with animated widgets
                _buildAnimatedTab(
                  ProfileHeaderTab(
                    userName: _userName,
                    userEmail: _userEmail,
                    onNameUpdated: _onNameUpdated,
                  ),
                ),
                _buildAnimatedTab(const StatisticsTab()),
                _buildAnimatedTab(const AchievementsTab()),
                _buildAnimatedTab(const SessionHistoryTab()),
                _buildAnimatedTab(const GoalsTab()),
                _buildAnimatedTab(const SettingsTab()),
              ],
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(5, (index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        )),
      ),
    );
  }

  Widget _buildAnimatedTab(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}