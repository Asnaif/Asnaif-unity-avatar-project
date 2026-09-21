// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get.dart';
// import 'package:interprep/common/constants/styles.dart';
// import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';
// import 'package:interprep/common/resources/widgets/textfields/app_text_field.dart';
// import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
// import 'package:interprep/models/app_user.dart';
// import 'package:interprep/services/activity_log_service.dart';
// import 'package:interprep/screens/signup/provider/confirm_password_text_controller_provider.dart';
// import 'package:interprep/screens/signup/provider/email_text_controller_provider.dart';
// import 'package:interprep/screens/signup/provider/name_text_controller_provider.dart';
// import 'package:interprep/screens/signup/provider/password_text_controller_provider.dart';

// class SignUpScreen extends ConsumerStatefulWidget {
//   const SignUpScreen({super.key});

//   @override
//   ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends ConsumerState<SignUpScreen> {
//   bool isRegisterLoading = false;
//   final formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     ref.read(emailTextControllerProvider).clear();
//     ref.read(passwordTextControllerProvider).clear();
//     ref.read(nameTextControllerProvider).clear();
//     ref.read(confirmPasswordTextControllerProvider).clear();
//     super.initState();
//   }

//   Future<User?> signUp(AppUser user) async {
//     try {
//       setState(() {
//         isRegisterLoading = true;
//       });

//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: user.email,
//         password: user.password,
//       );

//       User? createdUser = userCredential.user;
//       if (createdUser != null) {
//         // Try to create user document with 'user' role first
//         // If this is the first user, you can manually set them as admin later
//         // OR use a Cloud Function to handle first-user detection
//         try {
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(createdUser.uid)
//               .set({
//             'email': user.email,
//             'name': user.name,
//             'role': 'user', // Default to 'user', set first user as admin manually
//             'createdAt': DateTime.now().toIso8601String(),
//           });
//         } catch (e) {
//           // If document creation fails, throw error
//           throw Exception('Failed to create user profile: $e');
//         }
        
//         // Log signup activity (this should work now)
//         try {
//           final activityLogService = ActivityLogService();
//           await activityLogService.logSignup(createdUser.uid, email: user.email);
//         } catch (e) {
//           // Log error but don't fail signup if activity logging fails
//           debugPrint('Failed to log signup activity: $e');
//         }
//       }

//       Get.toNamed('/login');
//       return createdUser;
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'weak-password') {
//         CustomToast.showError('The password provided is too weak.');
//       } else if (e.code == 'email-already-in-use') {
//         CustomToast.showError('The account already exists for that email.');
//       }
//     } catch (e) {
//       CustomToast.showError(e.toString());
//     } finally {
//       setState(() {
//         isRegisterLoading = false;
//       });
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final nameController = ref.watch(nameTextControllerProvider);
//     final emailController = ref.watch(emailTextControllerProvider);
//     final passwordController = ref.watch(passwordTextControllerProvider);
//     final confirmPasswordController =
//         ref.watch(confirmPasswordTextControllerProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Center(child: Text("SignUp")),
//         backgroundColor: Styles.primaryColor,
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.only(left: 18, bottom: 8, right: 18),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "InterPrep",
//                   style: Styles.displayLargeBoldStyle.copyWith(
//                     color: Styles.primaryColor,
//                     fontSize: 32,
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 Form(
//                   key: formKey,
//                   child: Column(
//                     children: [
//                       AppTextField(
//                         key: const ValueKey('nameTextField'),
//                         label: "Name",
//                         keyboardType: TextInputType.name,
//                         controller: nameController,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Name is required';
//                           } else if (!RegExp(r'^[a-z A-Z]').hasMatch(
//                             value,
//                           )) {
//                             return "Enter Correct Name";
//                           }

//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                       AppTextField(
//                         key: const ValueKey('emailTextField'),
//                         label: "Email",
//                         keyboardType: TextInputType.name,
//                         controller: emailController,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Email is required';
//                           } else if (!RegExp(
//                                   r'^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})')
//                               .hasMatch(
//                             value,
//                           )) {
//                             return "Enter a valid email address";
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                       AppTextField(
//                         key: const ValueKey('passwordTextField'),
//                         label: "Password",
//                         keyboardType: TextInputType.name,
//                         controller: passwordController,
//                         obscureText: true,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Password is required';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                       AppTextField(
//                         key: const ValueKey('confirmPasswordTextField'),
//                         label: "Confirm Password",
//                         keyboardType: TextInputType.name,
//                         controller: confirmPasswordController,
//                         obscureText: true,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return "Confirm Password should have a value";
//                           } else if (passwordController.text !=
//                               confirmPasswordController.text) {
//                             return "Both Passwords should match";
//                           }
//                           return null;
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 isRegisterLoading
//                     ? const CircularProgressIndicator()
//                     : AppTextButton(
//                         text: "Sign Up",
//                         onTap: () {
//                           if (formKey.currentState!.validate()) {
//                             final email =
//                                 ref.read(emailTextControllerProvider).text;
//                             final password =
//                                 ref.read(passwordTextControllerProvider).text;
//                             final name =
//                                 ref.read(nameTextControllerProvider).text;

//                             final user = AppUser(
//                                 email: email, password: password, name: name);
//                             signUp(
//                               user,
//                             );
//                           }
//                         },
//                         color: Styles.primaryColor,
//                       ),
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Get.toNamed('/login');
//                   },
//                   child: RichText(
//                     text: TextSpan(
//                       text: 'Already have an account? ',
//                       style: const TextStyle(
//                         color: Colors.black,
//                         fontSize: 16,
//                       ),
//                       children: <TextSpan>[
//                         TextSpan(
//                           text: 'Log in',
//                           style: TextStyle(
//                             color: Styles.primaryColor,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';
import 'package:interprep/common/resources/widgets/textfields/app_text_field.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:interprep/models/app_user.dart';
import 'package:interprep/services/activity_log_service.dart';
import 'package:interprep/screens/signup/provider/confirm_password_text_controller_provider.dart';
import 'package:interprep/screens/signup/provider/email_text_controller_provider.dart';
import 'package:interprep/screens/signup/provider/name_text_controller_provider.dart';
import 'package:interprep/screens/signup/provider/password_text_controller_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> with SingleTickerProviderStateMixin {
  bool isRegisterLoading = false;
  final formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    ref.read(emailTextControllerProvider).clear();
    ref.read(passwordTextControllerProvider).clear();
    ref.read(nameTextControllerProvider).clear();
    ref.read(confirmPasswordTextControllerProvider).clear();
    
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

  Future<User?> signUp(AppUser user) async {
    try {
      setState(() {
        isRegisterLoading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      User? createdUser = userCredential.user;
      if (createdUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(createdUser.uid)
              .set({
            'email': user.email,
            'name': user.name,
            'role': 'user',
            'createdAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          throw Exception('Failed to create user profile: $e');
        }
        
        try {
          final activityLogService = ActivityLogService();
          await activityLogService.logSignup(createdUser.uid, email: user.email);
        } catch (e) {
          debugPrint('Failed to log signup activity: $e');
        }
      }

      Get.toNamed('/login');
      return createdUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        CustomToast.showError('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        CustomToast.showError('The account already exists for that email.');
      }
    } catch (e) {
      CustomToast.showError(e.toString());
    } finally {
      setState(() {
        isRegisterLoading = false;
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nameController = ref.watch(nameTextControllerProvider);
    final emailController = ref.watch(emailTextControllerProvider);
    final passwordController = ref.watch(passwordTextControllerProvider);
    final confirmPasswordController =
        ref.watch(confirmPasswordTextControllerProvider);

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
                          "Create Your Account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
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
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                // Name Field
                                AppTextField(
                                  key: const ValueKey('nameTextField'),
                                  label: "Full Name",
                                  keyboardType: TextInputType.name,
                                  controller: nameController,
                                  prefixIcon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Name is required';
                                    } else if (!RegExp(r'^[a-z A-Z]').hasMatch(value)) {
                                      return "Enter Correct Name";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
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
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Confirm Password Field
                                AppTextField(
                                  key: const ValueKey('confirmPasswordTextField'),
                                  label: "Confirm Password",
                                  keyboardType: TextInputType.text,
                                  controller: confirmPasswordController,
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Confirm Password should have a value";
                                    } else if (passwordController.text !=
                                        confirmPasswordController.text) {
                                      return "Both Passwords should match";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                
                                // Sign Up Button
                                isRegisterLoading
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
                                            onTap: () {
                                              if (formKey.currentState!.validate()) {
                                                final email =
                                                    ref.read(emailTextControllerProvider).text;
                                                final password =
                                                    ref.read(passwordTextControllerProvider).text;
                                                final name =
                                                    ref.read(nameTextControllerProvider).text;

                                                final user = AppUser(
                                                    email: email, password: password, name: name);
                                                signUp(user);
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              height: 56,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'Sign Up',
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
                        ),
                        const SizedBox(height: 24),
                        
                        // Login Link
                        GestureDetector(
                          onTap: () {
                            Get.toNamed('/login');
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Log in',
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
                          "Start your journey to better communication",
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
    );
  }
}