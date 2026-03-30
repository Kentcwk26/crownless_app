import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crownless_app/utils/information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'utils/date_formatter.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('notifications').tr(),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10.0,
                children: [
                  Text(
                    'not_logged_in'.tr(),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: Text('login'.tr()),
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('notifications').tr(),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: firebaseService.getUserNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: IconText(
                    leading: Icon(Icons.nearby_error_outlined, color: Colors.red),
                    text: 'error_loading'.tr(args: [snapshot.error.toString()]),
                    textColor: Colors.red,
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: IconText(
                    leading: Icon(Icons.notifications_off, color: Colors.grey),
                    text: 'no_notifications'.tr(),
                    textColor: Colors.grey,
                  ),
                );
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] as String? ?? 'notification'.tr();
                  final body = data['body'] as String? ?? '';
                  final isRead = data['read'] as bool? ?? false;

                  final createdAt = data['createdAt'] as Timestamp?;
                  final formattedTime = createdAt != null
                      ? DateFormatter.formatDateTime(context, createdAt)
                      : '';

                  return ListTile(
                    leading: Icon(
                      isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                      color: isRead ? Colors.grey : Colors.blue,
                    ),

                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: isRead ? Colors.grey : Colors.black,
                      ),
                    ),

                    subtitle: Text(
                      body,
                      style: TextStyle(
                        color: isRead ? Colors.grey : Colors.black87,
                      ),
                    ),

                    trailing: createdAt != null
                        ? Text(
                            DateFormatter.timeAgo(context, createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isRead ? Colors.grey : Colors.blue,
                            ),
                          )
                        : null,

                    tileColor: isRead ? null : Colors.blue.withOpacity(0.05),

                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(title),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(body),
                              if (formattedTime.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          actions: [
                            if (!isRead)
                              TextButton(
                                onPressed: () {
                                  firebaseService.markNotificationAsRead(
                                    docs[index].id,
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Mark as Read'),
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },

                    onLongPress: () => firebaseService.markNotificationAsRead(docs[index].id),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}