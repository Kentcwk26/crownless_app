import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../notification.dart';
import '../../services/firebase_service.dart';
import '../../utils/color_buttons.dart';
import 'manageusers.dart';

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
              ElevatedButton(
                onPressed: () => _showSendNotificationDialog(context),
                child: Text('send_notification'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUsersPage())),
                child: Text('manage_users'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool sendToAll = true;
    Set<String> selectedUserIds = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('send_notification'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'title'.tr()),
              ),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(labelText: 'body'.tr()),
                maxLines: 3,
              ),
              Row(
                children: [
                  Checkbox(
                    value: sendToAll,
                    onChanged: (value) => setState(() => sendToAll = value ?? true),
                  ),
                  const Text('send_to_all_users').tr(),
                ],
              ),
              if (!sendToAll)
                ElevatedButton(
                  onPressed: () async => await _selectUsers(context, selectedUserIds, setState),
                  child: Text('select_users_count').tr(args: [selectedUserIds.length.toString()]),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('cancel').tr(),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('title_and_body_required').tr()),
                  );
                  return;
                }

                List<String>? userIds;
                if (!sendToAll) {
                  userIds = selectedUserIds.toList();
                  if (userIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('select_users').tr()),
                    );
                    return;
                  }
                }

                try {
                  await FirebaseService().sendNotification(
                    title: title,
                    body: body,
                    userIds: userIds,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('notification_sent').tr()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('notification_failed'.tr(namedArgs: {'error': e.toString()}))),
                  );
                }
              },
              child: const Text('send').tr(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectUsers(BuildContext context, Set<String> selectedUserIds, StateSetter setState) async {
    try {
      final users = await FirebaseService().getAllUsers();
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, innerSetState) => AlertDialog(
            title: const Text('select_user').tr(),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userId = user['id'] as String;
                  final name = user['name'] as String? ?? 'unknown'.tr();
                  final email = user['email'] as String? ?? '';
                  return CheckboxListTile(
                    title: Text(name),
                    subtitle: Text(email),
                    value: selectedUserIds.contains(userId),
                    onChanged: (bool? value) {
                      innerSetState(() {
                        if (value == true) {
                          selectedUserIds.add(userId);
                        } else {
                          selectedUserIds.remove(userId);
                        }
                      });
                      setState(() {});
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('done').tr(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('load_users_failed'.tr(args: [e.toString()]))),
      );
    }
  }
}