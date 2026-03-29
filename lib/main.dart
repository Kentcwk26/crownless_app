import 'package:crownless_app/utils/information.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '404.dart';
import 'about.dart';
import 'blog.dart';
import 'inquiry.dart';
import 'faq.dart';
import 'screens/admin/adminstrator.dart';
import 'login.dart';
import 'notification.dart';
import 'screens/admin/infomanagement.dart';
import 'settings.dart';
import 'utils/carousel_slides.dart';
import 'utils/color_buttons.dart';
import 'utils/image_responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
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
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('confirm_logout'.tr()),
          content: Text('logout_confirmation'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('logged_out_success'.tr())),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('logout_failed'.tr(args: [e.toString()]))),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text('logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)).tr(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.user != null;

    return Scaffold(
      appBar: AppBar(
        title: Text("home".tr()),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage())),
            icon: const Icon(Icons.notifications),
          )
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      accountName: Text(
                        widget.user?.displayName ?? 'guest'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      accountEmail: const SizedBox.shrink(),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: widget.user != null
                            ? NetworkImage(widget.user!.photoURL ?? '')
                            : null,
                        child: widget.user == null
                            ? Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: Text('home'.tr()),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.new_label_sharp),
                      title: const Text('information').tr(),
                      childrenPadding: EdgeInsets.all(8),
                      children: [ 
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('aboutUs').tr(),
                          onTap: () => Navigator.pushNamed(context, '/about')
                        ),
                        ListTile(
                          leading: const Icon(Icons.quiz),
                          title: const Text('faq').tr(),
                          onTap: () => Navigator.pushNamed(context, '/faq')
                        ),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('privacyPolicy').tr(),
                          onTap: () => Navigator.pushNamed(context, '/privacy-policy')
                        ),
                        ListTile(
                          leading: const Icon(Icons.document_scanner),
                          title: const Text('termsConditions').tr(),
                          onTap: () => Navigator.pushNamed(context, '/terms-and-conditions')
                        ),
                      ]
                    ),
                    if (widget.isAdmin)
                      ExpansionTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: const Text('managePage').tr(),
                        childrenPadding: EdgeInsets.all(8),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.notifications),
                            title: Text('manage_notifications'.tr()),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.supervised_user_circle),
                            title: Text('manageUsers'.tr()),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUsersPage())),
                          ),
                          ListTile(
                            leading: Image.asset('assets/images/policy_alert.png'),
                            title: Text('managePolicy'.tr()),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyAdminPage())),
                          ),
                          ListTile(
                            leading: const Icon(Icons.edit_document),
                            title: Text('manageTAC'.tr()),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TACAdminPage())),
                          ),
                        ],
                      ),
                    ListTile(
                      leading: const Icon(Icons.live_help),
                      title: const Text('inquiries').tr(),
                      onTap: () => Navigator.pushNamed(context, '/inquiries')
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: Text('settings'.tr()),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(
                              toggleTheme: widget.toggleTheme,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: isLoggedIn
                      ? ElevatedButtonVariants.danger(
                          icon: Icon(Icons.logout),
                          child: Text('logout'.tr()),
                          onPressed: () {
                            Navigator.pop(context);
                            _handleLogout();
                          },
                        )
                      : ElevatedButtonVariants.success(
                          icon: Icon(Icons.login),
                          child: Text('login'.tr()),
                          onPressed: () async {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/login');
                          }
                        ),
                ),
              )
            ],
          ),
        )
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10.0,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.isAdmin ? "Admin View" : "Member View",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: widget.isAdmin,
                        onChanged: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Admin toggle is for demo only. Actual role is determined by authentication.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                CarouselSection(
                  imagePaths: [
                    'assets/images/logo.jpg', 'assets/images/photo1.jpg', 'assets/images/photo2.jpg', 'assets/images/photo3.jpg', 'assets/images/photo4.jpg', 
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    spacing: 10.0,
                    children: [
                      Text("dc_slogan".tr(), textAlign: TextAlign.center),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          widget.user != null
                              ? 'welcome_back'.tr(args: [widget.user!.displayName ?? 'User'])
                              : 'welcome_to_crownless'.tr(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text("dc_description".tr(), textAlign: TextAlign.justify, overflow: TextOverflow.visible),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        spacing: 10.0,
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
                        ]
                      ),
                      DividerText(text: "Coming Soon", fontSize: 16, lineColor: Colors.red, textColor: Colors.red),
                      Text("dc_inquiries".tr()),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.live_help),
                        label: Text('clickHere'.tr()),
                        onPressed: () => Navigator.pushNamed(context, '/inquiries'),
                      ),
                      Footer()
                    ],
                  )
                )
              ],
            ),
          ),
        ),
      )
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