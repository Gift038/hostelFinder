import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotification({
    required String managerId,
    required String type,
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'managerId': managerId,
      'type': type,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createPaymentNotification({
    required String managerId,
    required String tenantName,
    required double amount,
    required String hostelName,
  }) async {
    await createNotification(
      managerId: managerId,
      type: 'PAYMENT',
      message:
          'Payment of Ugx $amount received from $tenantName for $hostelName',
    );
  }

  Future<void> createMaintenanceNotification({
    required String managerId,
    required String tenantName,
    required String issue,
    required String roomNumber,
    required String hostelName,
  }) async {
    await createNotification(
      managerId: managerId,
      type: 'MAINTENANCE',
      message:
          'New maintenance request: $issue in Room $roomNumber at $hostelName by $tenantName',
    );
  }

  Future<void> createBookingNotification({
    required String managerId,
    required String tenantName,
    required String roomNumber,
    required String hostelName,
  }) async {
    await createNotification(
      managerId: managerId,
      type: 'BOOKING',
      message:
          'New booking request for Room $roomNumber at $hostelName from $tenantName',
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllAsRead(String managerId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('managerId', isEqualTo: managerId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  Stream<QuerySnapshot> getNotificationStream(String managerId) {
    return _firestore
        .collection('notifications')
        .where('managerId', isEqualTo: managerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<int> getUnreadCount(String managerId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('managerId', isEqualTo: managerId)
        .where('read', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
