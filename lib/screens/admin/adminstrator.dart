import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../notification.dart';
import '../../services/firebase_service.dart';
import '../../utils/color_buttons.dart';
import 'infomanagement.dart';

class AdminstratorScreen extends StatelessWidget {
  const AdminstratorScreen({super.key, this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('admin_dashboard'.tr()),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage())),
              icon: const Icon(Icons.notifications),
            )
          ],
        ),
        drawer: Drawer(
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
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : 'role_admin'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      accountEmail: const SizedBox.shrink(),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Icon(
                                Icons.admin_panel_settings,
                                size: 40,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text('manage_notifications'.tr()),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.supervised_user_circle),
                      title: Text('manage_users'.tr()),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUsersPage())),
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_document),
                      title: Text('manage_info'.tr()),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyAdminPage())),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButtonVariants.danger(
                    icon: Icon(Icons.logout),
                    child: Text('logout'.tr()),
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('confirm_logout'.tr()),
                          content: Text('logout_confirmation'.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('cancel'.tr()),
                            ),
                            ElevatedButtonVariants.danger(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('logout'.tr()),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('logged_out_success'.tr())),
                        );
                      }
                    },
                  ),
                )
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10.0,
            children: [
              Image.asset('assets/images/logo.jpg', height: 200),
              Text('welcome_back'.tr(args: [user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Admin'])),
            ],
          ),
        ),
      ),
    );
  }
}