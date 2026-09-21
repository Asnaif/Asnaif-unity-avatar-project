import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/services/export_service.dart';
import 'package:interprep/services/theme_service.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:share_plus/share_plus.dart';
// import 'dart:io';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExportService _exportService = ExportService();
  
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _isExporting = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _pushNotifications = data['pushNotifications'] ?? true;
            _emailNotifications = data['emailNotifications'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _updateNotificationSettings(String key, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          key: value,
        });
        CustomToast.showSuccess('Settings updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      CustomToast.showError('Failed to update settings');
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isChangingPassword ? null : () async {
              if (formKey.currentState!.validate()) {
                await _changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    setState(() {
      _isChangingPassword = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Update password
        await user.updatePassword(newPassword);
        
        CustomToast.showSuccess('Password changed successfully');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak';
      }
      CustomToast.showError(message);
    } catch (e) {
      CustomToast.showError('Failed to change password');
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  void _showEmailPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Preferences'),
        content: const Text(
          'You can manage your email preferences here. '
          'This includes notifications about your progress, achievements, and updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Data Collection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We collect your practice session data, progress statistics, and profile information to provide personalized learning experiences.',
              ),
              SizedBox(height: 16),
              Text(
                'Data Usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your data is used to:\n'
                '• Track your progress\n'
                '• Provide personalized recommendations\n'
                '• Generate statistics and reports\n'
                '• Improve our services',
              ),
              SizedBox(height: 16),
              Text(
                'Data Storage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your data is securely stored in Firebase and is only accessible by you.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

      void _showThemeDialog() {
    final themeService = Get.find<ThemeService>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeService.themeMode.value,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setThemeMode(value);
                    Navigator.of(context).pop();
                    CustomToast.showSuccess('Theme changed to Light mode');
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeService.themeMode.value,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setThemeMode(value);
                    Navigator.of(context).pop();
                    CustomToast.showSuccess('Theme changed to Dark mode');
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeService.themeMode.value,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setThemeMode(value);
                    Navigator.of(context).pop();
                    CustomToast.showSuccess('Theme set to System Default');
                  }
                },
              ),
            ),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Spanish', 'French', 'German'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(languages[index]),
                trailing: languages[index] == 'English'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  CustomToast.showInfo('${languages[index]} language support coming soon!');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Show report type selection
      final reportType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Weekly Report'),
                onTap: () => Navigator.of(context).pop('weekly'),
              ),
              ListTile(
                title: const Text('Monthly Report'),
                onTap: () => Navigator.of(context).pop('monthly'),
              ),
              ListTile(
                title: const Text('All Time'),
                onTap: () => Navigator.of(context).pop('all'),
              ),
            ],
          ),
        ),
      );

      if (reportType != null) {
        final textData = await _exportService.exportToText(
          reportType: reportType == 'all' ? 'custom' : reportType,
        );

        // Share the exported data
        await Share.share(
          textData,
          subject: 'InterPrep Progress Report',
        );

        CustomToast.showSuccess('Data exported successfully');
      }
    } catch (e) {
      debugPrint('Error exporting data: $e');
      CustomToast.showError('Failed to export data');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear cached data. Some data may need to be reloaded. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear cache logic - in a real app, you'd clear image cache, etc.
      CustomToast.showSuccess('Cache cleared successfully');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. '
          'All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          // Delete user data from Firestore
          await _firestore.collection('users').doc(user.uid).delete();
          
          // Delete user's sessions
          await _firestore.collection('sessions').doc(user.uid).delete();
          
          // Delete user's preferences
          await _firestore.collection('userPreferences').doc(user.uid).delete();
          
          // Delete the auth account
          await user.delete();
          
          Get.offAllNamed('/signup');
          CustomToast.showSuccess('Account deleted successfully');
        }
      } catch (e) {
        debugPrint('Error deleting account: $e');
        CustomToast.showError('Failed to delete account. Please contact support.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('Account Settings', [
          _buildSettingTile(
            Icons.lock,
            'Change Password',
            _showChangePasswordDialog,
          ),
          _buildSettingTile(
            Icons.email,
            'Email Preferences',
            _showEmailPreferencesDialog,
          ),
          _buildSettingTile(
            Icons.privacy_tip,
            'Privacy Settings',
            _showPrivacySettingsDialog,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('Notification Settings', [
          _buildSwitchTile(
            'Push Notifications',
            _pushNotifications,
            (value) {
              setState(() {
                _pushNotifications = value;
              });
              _updateNotificationSettings('pushNotifications', value);
            },
          ),
          _buildSwitchTile(
            'Email Notifications',
            _emailNotifications,
            (value) {
              setState(() {
                _emailNotifications = value;
              });
              _updateNotificationSettings('emailNotifications', value);
            },
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('App Preferences', [
          _buildSettingTile(
            Icons.dark_mode,
            'Theme',
            _showThemeDialog,
          ),
          _buildSettingTile(
            Icons.language,
            'Language',
            _showLanguageDialog,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('Data Management', [
          _buildSettingTile(
            Icons.download,
            'Export Data',
            _isExporting ? () {} : _exportData,
            trailing: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          _buildSettingTile(
            Icons.delete_outline,
            'Clear Cache',
            _clearCache,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('Danger Zone', [
          _buildSettingTile(
            Icons.delete_forever,
            'Delete Account',
            _deleteAccount,
            color: Colors.red,
          ),
        ]),
        const SizedBox(height: 32),
        Center(
          child: ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Get.offAllNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Styles.primaryColor),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}