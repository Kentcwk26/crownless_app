import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/admin/adminstrator.dart';
import 'settings.dart';
import 'utils/color_buttons.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const LoginPage({super.key, this.toggleTheme, this.isDarkMode = false});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _ensureUserDocument(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'name': user.displayName ?? 'User',
        'email': user.email,
        'role': 'member',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> handleSignIn() async {
    setState(() => isLoading = true);

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: '15035334254-eoek90ejsd8nu5geal0qco032cggr56d.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await FirebaseAuth.instance.signInWithCredential(credential);

      final user = result.user;
      if (user == null) throw Exception('No user found after sign-in');

      await _ensureUserDocument(user);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = doc.data()?['role'] ?? 'member';

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminstratorScreen(user: user)));
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
      debugPrint('Error during Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('login'.tr()),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(
                  toggleTheme: widget.toggleTheme,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            ),
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.jpg', height: 140),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Text(
                          "welcome".tr(),
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("welcomeSubtitle".tr(), textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                        child: ElevatedButtonVariants.auto(
                          onPressed: handleSignIn,
                          icon: Image.asset('assets/images/google.png', height: 20),
                          child: Text('auth.signin_with_google'.tr()),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/about');
                            },
                            child: Text('aboutUs'.tr()),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/terms-and-conditions');
                            },
                            child: Text('termsConditions'.tr()),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/privacy-policy');
                            },
                            child: Text('privacyPolicy'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'copyright'.tr(args: ['${DateTime.now().year}']),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}