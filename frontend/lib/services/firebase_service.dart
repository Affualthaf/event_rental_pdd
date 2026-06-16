import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Orders ────────────────────────────────────────────────────────────────
  
  Future<String> placeOrder(OrderModel order) async {
    final docRef = _db.collection('orders').doc();
    final orderWithId = order.toMap();
    orderWithId['id'] = docRef.id;
    // Stamp the current user's UID so customers can later query their own orders.
    orderWithId['customerId'] = _auth.currentUser?.uid ?? '';
    await docRef.set(orderWithId);
    return docRef.id;
  }

  Stream<List<OrderModel>> getOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<OrderModel?> getOrderByIdStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromMap(doc.data()!, doc.id) : null);
  }

  /// Orders that belong to this vendor — filtered and sorted client-side to avoid
  /// needing a Firestore composite index on (vendorId + createdAt), and to allow
  /// testing with mock or unassigned vendor IDs.

  /// Orders that belong to the logged-in customer.
  /// Matches on the `customerId` field (UID stored at order-placement time).
  /// Orders without a `customerId` field are excluded.
  Stream<List<OrderModel>> getCustomerOrders(String uid) {
    return _db.collection('orders').snapshots().map((s) {
      final filtered = s.docs.where((d) {
        final cid = d.data()['customerId'] as String? ?? '';
        return cid == uid;
      }).map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  Stream<List<OrderModel>> getOrdersForVendor(String vendorId) {
    return _db.collection('orders').snapshots().map((s) {
      final list = s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      final filtered = list.where((o) {
        return o.vendorId == vendorId || 
               o.vendorId.isEmpty || 
               o.vendorId.startsWith('mock_');
      }).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
      return filtered;
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> acceptOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'Confirmed',
      'trackingStep': 1,
    });
  }

  Future<void> rejectOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'Rejected',
    });
  }

  Future<void> updateTracking(String orderId, int step, String note) async {
    final statuses = [
      'Processing',
      'Confirmed',
      'Prepared',
      'Out for Delivery',
      'Delivered',
    ];
    await _db.collection('orders').doc(orderId).update({
      'trackingStep': step,
      'trackingNote': note,
      'status': statuses[step.clamp(0, 4)],
    });
  }

  // ─── Equipment (Example) ───────────────────────────────────────────────────
  
  Stream<List<Map<String, dynamic>>> getEquipment() {
    return _db.collection('equipment').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getEquipmentByVendor(String vendorId) {
    return _db.collection('equipment').where('vendorId', isEqualTo: vendorId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<UserModel>> getVendorsByCity(String city) {
    return _db.collection('users').where('role', isEqualTo: 'Vendor').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList();
      if (city.isEmpty) return list;
      final q = city.toLowerCase();
      return list.where((u) => u.location.toLowerCase().contains(q)).toList();
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  // ─── User Profile ──────────────────────────────────────────────────────────

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // Create a default profile if it doesn't exist
      final newUser = UserModel(
        id: user.uid,
        name: user.displayName ?? 'New User',
        email: user.email ?? '',
        phone: '',
        location: 'Not set',
        createdAt: DateTime.now(),
      );
      await updateUserProfile(newUser);
      return newUser;
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<UserModel?> userProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> addEquipment(Map<String, dynamic> item) async {
    await _db.collection('equipment').add(item);
  }

  Future<Map<String, dynamic>?> getEquipmentById(String id) async {
    try {
      final doc = await _db.collection('equipment').doc(id).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      return null;
    }
  }

  // ─── Chat System ─────────────────────────────────────────────────────────────
  
  String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  Stream<List<Map<String, dynamic>>> getUserChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          list.sort((a, b) {
            final timeA = a['lastMessageTime'] as String? ?? '';
            final timeB = b['lastMessageTime'] as String? ?? '';
            return timeB.compareTo(timeA);
          });
          return list;
        });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> sendMessage({
    required String uid1,
    required String uid2,
    required String text,
    required String senderName,
    required String receiverName,
  }) async {
    final chatId = getChatId(uid1, uid2);
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final now = DateTime.now().toIso8601String();

    await _db.runTransaction((tx) async {
      final chatDoc = await tx.get(chatRef);
      if (!chatDoc.exists) {
        tx.set(chatRef, {
          'participants': [uid1, uid2],
          'participantNames': {uid1: senderName, uid2: receiverName},
          'lastMessage': text,
          'lastMessageTime': now,
        });
      } else {
        tx.update(chatRef, {
          'lastMessage': text,
          'lastMessageTime': now,
          // ensure names are updated in case they change
          'participantNames.$uid1': senderName,
          'participantNames.$uid2': receiverName,
        });
      }

      tx.set(msgRef, {
        'senderId': uid1,
        'text': text,
        'timestamp': now,
      });
    });
  }
}
