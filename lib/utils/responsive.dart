import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/admin/infomanagement.dart';
import '../notification.dart';
import '../settings.dart';
import '../utils/color_buttons.dart';

class Responsive {
  static const double desktopBreakpoint = 600;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < desktopBreakpoint;
}

class AppShell extends StatefulWidget {
  final Widget body;
  final String title;
  final User? user;
  final String role;
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.body,
    required this.title,
    required this.toggleTheme,
    required this.isDarkMode,
    this.user,
    this.role = 'member',
    this.actions,
  });

  bool get isAdmin => role == 'admin';

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get isAdmin => widget.isAdmin;
  bool get isLoggedIn => widget.user != null;

  Future<void> _handleLogout() async {
    _scaffoldKey.currentState?.closeDrawer();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_logout'.tr()),
        content: Text('logout_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('logged_out_success'.tr())),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('logout_failed'.tr(args: [e.toString()])),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              'logout',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ).tr(),
          ),
        ],
      ),
    );
  }

  void _navigate(String route) {
    _scaffoldKey.currentState?.closeDrawer();
    Navigator.pushNamed(context, route);
  }

  Widget _buildAuthButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: isLoggedIn
            ? ElevatedButtonVariants.danger(
                icon: const Icon(Icons.logout),
                child: Text('logout'.tr()),
                onPressed: _handleLogout,
              )
            : ElevatedButtonVariants.success(
                icon: const Icon(Icons.login),
                child: Text('login'.tr()),
                onPressed: () => _navigate('/login'),
              ),
      ),
    );
  }

  Widget _buildNavItems(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          accountName: Text(
            widget.user?.displayName ?? 'guest'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          accountEmail: const SizedBox.shrink(),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child:
                widget.user?.photoURL != null &&
                    widget.user!.photoURL!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.user!.photoURL!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      headers: kIsWeb
                          ? const {'Access-Control-Allow-Origin': '*'}
                          : null,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Icon(
                          Icons.person,
                          size: 40,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.home),
          title: Text('home'.tr()),
          onTap: () {},
        ),

        ExpansionTile(
          leading: const Icon(Icons.new_label_sharp),
          title: Text('information'.tr()),
          childrenPadding: const EdgeInsets.all(8),
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: Text('aboutUs'.tr()),
              onTap: () => _navigate('/about'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: Text('faq'.tr()),
              onTap: () => _navigate('/faq'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text('privacyPolicy'.tr()),
              onTap: () => _navigate('/privacy-policy'),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: Text('termsConditions'.tr()),
              onTap: () => _navigate('/terms-and-conditions'),
            ),
          ],
        ),

        if (isAdmin)
          ExpansionTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: Text('managePage'.tr()),
            childrenPadding: const EdgeInsets.all(8),
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text('manage_notifications'.tr()),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageNotificationsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.supervised_user_circle),
                title: Text('manageUsers'.tr()),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageUsersPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.diversity_1),
                title: Text('manageDancers'.tr()),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageDancersPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: Text('managePolicy'.tr()),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrivacyPolicyAdminPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_document),
                title: Text('manageTAC'.tr()),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TACAdminPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.contact_support),
                title: Text('manageFAQ'.tr()),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageFAQPage()),
                  );
                },
              ),
            ],
          ),

        ListTile(
          leading: const Icon(Icons.live_help),
          title: Text('inquiries'.tr()),
          onTap: () => _navigate('/inquiries'),
        ),

        ListTile(
          leading: const Icon(Icons.settings),
          title: Text('settings'.tr()),
          onTap: () {
            _scaffoldKey.currentState?.closeDrawer();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  toggleTheme: widget.toggleTheme,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationsPage()),
            ),
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [_buildNavItems(context)],
                ),
              ),

              _buildAuthButton(),
            ],
          ),
        ),
      ),
      body: widget.body,
    );
  }
}
