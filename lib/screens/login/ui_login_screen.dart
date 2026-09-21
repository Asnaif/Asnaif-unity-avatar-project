// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:interprep/common/constants/styles.dart';
// import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';
// import 'package:interprep/common/resources/widgets/textfields/app_text_field.dart';
// import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
// import 'package:interprep/screens/login/provider/email_text_controller_provider.dart';
// import 'package:interprep/screens/login/provider/password_text_controller_provider.dart';
// import 'package:interprep/services/activity_log_service.dart';
// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   bool isLoading = false;
//   final _formKey = GlobalKey<FormState>();
//   Future<void> signIn(String email, String password) async {
//     try {
//       setState(() {
//         isLoading = true;
//       });
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
      
//       // Get user role and redirect accordingly
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         // Log login activity
//         final activityLogService = ActivityLogService();
//         await activityLogService.logLogin(user.uid);
        
//         final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
//         final role = userDoc.data()?['role'] ?? 'user';
        
//         if (role == 'admin') {
//           Get.offNamed('/admin_dashboard');
//         } else {
//           Get.offNamed('/user_dashboard');
//         }
//       } else {
//         Get.offNamed('/user_dashboard');
//       }
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'user-not-found') {
//         CustomToast.showError('No user found for that email.');
//       } else if (e.code == 'wrong-password') {
//         CustomToast.showError('Wrong password provided for that user.');
//       }
//     } catch (e) {
//       CustomToast.showError(e.toString());
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   void initState() {
//     ref.read(emailTextControllerProvider).clear();
//     ref.read(passwordTextControllerProvider).clear();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final emailController = ref.watch(emailTextControllerProvider);
//     final passwordController = ref.watch(passwordTextControllerProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Center(child: Text("Login")),
//         backgroundColor: Styles.primaryColor,
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//       ),
//       body: Form(
//         key: _formKey,
//         child: Padding(
//           padding: const EdgeInsets.only(left: 18, bottom: 8, right: 18),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "InterPrep Login",
//                 style: Styles.displayLargeBoldStyle.copyWith(
//                   color: Styles.primaryColor,
//                   fontSize: 32,
//                 ),
//               ),
//               const SizedBox(
//                 height: 20,
//               ),
//               AppTextField(
//                 key: const ValueKey('emailTextField'),
//                 label: "Email",
//                 keyboardType: TextInputType.name,
//                 controller: emailController,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Email is required';
//                   } else if (!RegExp(
//                           r'^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})')
//                       .hasMatch(
//                     value,
//                   )) {
//                     return "Enter a valid email address";
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(
//                 height: 10,
//               ),
//               AppTextField(
//                 key: const ValueKey('passwordTextField'),
//                 label: "Password",
//                 keyboardType: TextInputType.name,
//                 controller: passwordController,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Password is required';
//                   }
//                   return null;
//                 },
//                 obscureText: true,
//               ),
//               const SizedBox(
//                 height: 20,
//               ),
//               isLoading
//                   ? const Center(
//                       child: CircularProgressIndicator(),
//                     )
//                   : AppTextButton(
//                       text: "Login",
//                       onTap: () async {
//                         if (_formKey.currentState!.validate()) {
//                           final email =
//                               ref.read(emailTextControllerProvider).text;
//                           final password =
//                               ref.read(passwordTextControllerProvider).text;
//                           await signIn(email, password);
//                         }
//                       },
//                       color: Styles.primaryColor,
//                     ),
//               const SizedBox(
//                 height: 20,
//               ),
//               GestureDetector(
//                 onTap: () {
//                   Get.toNamed('/signup');
//                 },
//                 child: RichText(
//                   text: TextSpan(
//                     text: "Don't have an account? ",
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                     ),
//                     children: <TextSpan>[
//                       TextSpan(
//                         text: 'Sign Up',
//                         style: TextStyle(
//                           color: Styles.primaryColor,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:interprep/common/constants/styles.dart';
// import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';
import 'package:interprep/common/resources/widgets/textfields/app_text_field.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:interprep/screens/login/provider/email_text_controller_provider.dart';
import 'package:interprep/screens/login/provider/password_text_controller_provider.dart';
import 'package:interprep/services/activity_log_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> signIn(String email, String password) async {
    try {
      setState(() {
        isLoading = true;
      });
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get user role and redirect accordingly
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Log login activity
        final activityLogService = ActivityLogService();
        await activityLogService.logLogin(user.uid);
        
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'] ?? 'user';
        
        if (role == 'admin') {
          Get.offNamed('/admin_dashboard');
        } else {
          Get.offNamed('/user_dashboard');
        }
      } else {
        Get.offNamed('/user_dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        CustomToast.showError('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        CustomToast.showError('Wrong password provided for that user.');
      }
    } catch (e) {
      CustomToast.showError(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ref.read(emailTextControllerProvider).clear();
    ref.read(passwordTextControllerProvider).clear();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailController = ref.watch(emailTextControllerProvider);
    final passwordController = ref.watch(passwordTextControllerProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Styles.primaryColor.withOpacity(0.1),
              Colors.purple.withOpacity(0.05),
              Colors.pink.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with gradient background
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Styles.primaryColor,
                                  Colors.purple.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Styles.primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.message_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Title with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Styles.primaryColor,
                                Colors.purple.shade600,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              "InterPrep",
                              style: Styles.displayLargeBoldStyle.copyWith(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Subtitle
                          Text(
                            "Master Your Communication Skills",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Card container for form
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Email Field
                                AppTextField(
                                  key: const ValueKey('emailTextField'),
                                  label: "Email Address",
                                  keyboardType: TextInputType.emailAddress,
                                  controller: emailController,
                                  prefixIcon: Icons.email_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    } else if (!RegExp(
                                            r'^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})')
                                        .hasMatch(value)) {
                                      return "Enter a valid email address";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Password Field
                                AppTextField(
                                  key: const ValueKey('passwordTextField'),
                                  label: "Password",
                                  keyboardType: TextInputType.text,
                                  controller: passwordController,
                                  prefixIcon: Icons.lock_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                ),
                                const SizedBox(height: 12),
                                
                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // Add forgot password functionality
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Styles.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Login Button
                                isLoading
                                    ? Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Styles.primaryColor,
                                              Colors.purple.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Styles.primaryColor,
                                              Colors.purple.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Styles.primaryColor.withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              if (_formKey.currentState!.validate()) {
                                                final email = ref.read(emailTextControllerProvider).text;
                                                final password = ref.read(passwordTextControllerProvider).text;
                                                await signIn(email, password);
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              height: 56,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'Login',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Sign Up Link
                          GestureDetector(
                            onTap: () {
                              Get.toNamed('/signup');
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 15,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: Styles.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Bottom tagline
                          Text(
                            "Join thousands improving their skills",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}