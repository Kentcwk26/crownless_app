import 'package:crownless_app/utils/information.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '404.dart';
import 'about.dart';
import 'blog.dart';
import 'firebase_options.dart';
import 'inquiry.dart';
import 'faq.dart';
import 'login.dart';
import 'notification.dart';
import 'screens/admin/infomanagement.dart';
import 'settings.dart';
import 'utils/carousel_slides.dart';
import 'utils/color_buttons.dart';
import 'utils/image_responsive.dart';
import 'utils/responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
        Locale('zh'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crownless',
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      initialRoute: '/',
      routes: {
        '/login': (context) => LoginPage(toggleTheme: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
        '/about': (context) => AboutPage(),
        '/blog': (context) => BlogPage(),
        '/inquiries': (context) => InquiryPage(),
        '/faq': (context) => FAQPage(),
        '/privacy-policy': (context) => PrivacyPolicyPage(),
        '/terms-and-conditions': (context) => TACPage(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => ErrorScreen(routeName: settings.name),
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.black,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.black,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        cardTheme: const CardThemeData(
          color: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
      ),
      themeMode: _themeMode,
      home: AuthGate(
        toggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    this.user,
    this.role = 'member',
  });

  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final User? user;
  final String role;

  bool get isAdmin => role == 'admin';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'home'.tr(),
      user: widget.user,
      role: widget.role,
      toggleTheme: widget.toggleTheme,
      isDarkMode: widget.isDarkMode,
      actions: [
        if (widget.isAdmin)
          Row(
            children: [
              Icon(
                Icons.edit,
                size: 18,
                color: _isEditMode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              Switch(
                value: _isEditMode,
                onChanged: (val) => setState(() => _isEditMode = val),
              ),
            ],
          ),
      ],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CarouselSection(
                  imagePaths: [
                    'assets/images/logo.jpg',
                    'assets/images/photo1.jpg',
                    'assets/images/photo2.jpg',
                    'assets/images/photo3.jpg',
                    'assets/images/photo4.jpg',
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    spacing: 18.0,
                    children: [
                      Text("dc_slogan".tr(), textAlign: TextAlign.center),
                      Text(
                        "dc_description_short".tr(),
                        textAlign: MediaQuery.of(context).size.width >= 600
                            ? TextAlign.center
                            : TextAlign.justify,
                        overflow: TextOverflow.visible,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.pageview),
                            label: Text('aboutUs'.tr()),
                            onPressed: () => Navigator.pushNamed(context, '/about'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.newspaper),
                            label: Text('watchBlog'.tr()),
                            onPressed: () => Navigator.pushNamed(context, '/blog'),
                          ),
                        ],
                      ),
                      DividerText(
                        text: "comingSoon".tr(),
                        fontSize: 16,
                        lineColor: Colors.red,
                        textColor: Colors.red,
                      ),
                      Text("dc_inquiries".tr()),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.live_help),
                        label: Text('clickHere'.tr()),
                        onPressed: () => Navigator.pushNamed(context, '/inquiries'),
                      ),
                      const Footer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10.0,
        children: [
          FourImageRow(
            images: [
              'assets/images/whatsapp.png',
              'assets/images/instagram.png',
              'assets/images/tiktok.png',
              'assets/images/youtube.png',
            ],
            links: [
              "https://wa.me/60199830889",
              "https://www.instagram.com/crownlessd.c",
              null,
              null
            ]
          ),
          Text(
            'copyright'.tr(args: [year.toString()]),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const AuthGate({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return MyHomePage(
            toggleTheme: toggleTheme,
            isDarkMode: isDarkMode,
            user: null,
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = docSnapshot.data?.data() as Map<String, dynamic>?;
            final role = data?['role'] ?? 'member';

            // All roles go to MyHomePage, role controls what they see
            return MyHomePage(
              toggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
              user: user,
              role: role,
            );
          },
        );
      },
    );
  }
}