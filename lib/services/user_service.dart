import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'users';

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? location,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        updates['displayName'] = displayName;
        // Also update Firebase Auth profile
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;
      
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(userId).set(
        updates,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Create or initialize user profile
  Future<void> initializeUserProfile(User user) async {
    try {
      final doc = await _firestore.collection(_collection).doc(user.uid).get();
      
      if (!doc.exists) {
        await _firestore.collection(_collection).doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'bio': '',
          'location': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to initialize user profile: $e');
    }
  }

  // Stream user profile
  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}
