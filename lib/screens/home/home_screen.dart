import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:interprep/common/constants/styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _checkUserRoleAndRedirect() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'] ?? 'user';
        
        if (role == 'admin') {
          Get.offNamed('/admin_dashboard');
        } else {
          Get.offNamed('/user_dashboard');
        }
      } else {
        Get.offNamed('/login');
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
      Get.offNamed('/user_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Redirect based on user role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRoleAndRedirect();
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('InterPrep Dashboard'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Get.offAllNamed('/login');
              } else if (value == 'mode_type') {
                Get.toNamed('/mode_type');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'mode_type',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Select Mode'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeaturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      color: Styles.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to InterPrep!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Practice your communication skills with AI-powered feedback',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.toNamed('/mode_type'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Styles.primaryColor,
              ),
              child: const Text('Start Practice Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildActionCard(
          'Practice',
          Icons.mic,
          Colors.blue,
          () => Get.toNamed('/mode_type'),
        ),
        _buildActionCard(
          'Progress',
          Icons.trending_up,
          Colors.green,
          () => Get.toNamed('/gamification'),
        ),
        _buildActionCard(
          'Analytics',
          Icons.analytics,
          Colors.orange,
          () => Get.toNamed('/analytics'),
        ),
        _buildActionCard(
          'Learning Path',
          Icons.school,
          Colors.purple,
          () => Get.toNamed('/learning_path'),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeatureTile(
          'Community',
          'Connect with others and see leaderboards',
          Icons.groups,
          Colors.blue,
          () => Get.toNamed('/community'),
        ),
        const SizedBox(height: 8),
        _buildFeatureTile(
          'Templates',
          'Practice with industry-specific templates',
          Icons.description,
          Colors.green,
          () => Get.toNamed('/templates'),
        ),
        const SizedBox(height: 8),
        _buildFeatureTile(
          'Benchmarks',
          'Compare your performance with industry standards',
          Icons.compare_arrows,
          Colors.orange,
          () => Get.toNamed('/benchmarks'),
        ),
        const SizedBox(height: 8),
        _buildFeatureTile(
          'Integrations',
          'Connect LinkedIn, Calendar, and more',
          Icons.link,
          Colors.purple,
          () => Get.toNamed('/integrations'),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

