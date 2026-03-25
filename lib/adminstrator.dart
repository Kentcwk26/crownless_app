import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../notification.dart';
import '../../services/firebase_service.dart';
import 'screens/admin/manageusers.dart';

class AdminstratorScreen extends StatelessWidget {
  const AdminstratorScreen({super.key, this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Admin Dashboard'),
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
                      accountName: Text(user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Admin'),
                      accountEmail: const SizedBox.shrink(),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.admin_panel_settings, size: 40)
                            : null,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Manage Notifications'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.logout),
                  label: Text('logout'.tr()),
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
                          ElevatedButton(
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
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10.0,
            children: [
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
          title: const Text('Send Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 3,
              ),
              Row(
                children: [
                  Checkbox(
                    value: sendToAll,
                    onChanged: (value) => setState(() => sendToAll = value ?? true),
                  ),
                  const Text('Send to all users'),
                ],
              ),
              if (!sendToAll)
                ElevatedButton(
                  onPressed: () async => await _selectUsers(context, selectedUserIds, setState),
                  child: Text('Select Users (${selectedUserIds.length} selected)'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and body are required')),
                  );
                  return;
                }

                List<String>? userIds;
                if (!sendToAll) {
                  userIds = selectedUserIds.toList();
                  if (userIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one user')),
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
                    const SnackBar(content: Text('Notification sent successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send notification: $e')),
                  );
                }
              },
              child: const Text('Send'),
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
            title: const Text('Select Users'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userId = user['id'] as String;
                  final name = user['name'] as String? ?? 'Unknown';
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
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }
}