import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<QuerySnapshot> getUserNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    List<String>? userIds,
  }) async {
    final notificationData = {
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    };

    if (userIds == null || userIds.isEmpty) {
      final usersSnapshot = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = userDoc.reference.collection('notifications').doc();
        batch.set(notificationRef, notificationData);
      }
      await batch.commit();
    } else {
      final batch = _firestore.batch();
      for (final userId in userIds) {
        final notificationRef = _firestore.collection('users').doc(userId).collection('notifications').doc();
        batch.set(notificationRef, notificationData);
      }
      await batch.commit();
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role,
    });
  }
}