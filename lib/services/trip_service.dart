import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'trips';

  // Save a new trip
  Future<String> saveTrip(TripModel trip) async {
    try {
      final docRef = await _firestore.collection(_collection).add(trip.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save trip: $e');
    }
  }

  // Get all trips for a user
  Stream<List<TripModel>> getUserTrips(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final trips = snapshot.docs
              .map((doc) => TripModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort in memory instead of using orderBy to avoid composite index
          trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return trips;
        });
  }

  // Get a single trip by ID
  Future<TripModel?> getTrip(String tripId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(tripId).get();
      if (doc.exists) {
        return TripModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }

  // Update a trip
  Future<void> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(tripId).update(updates);
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  // Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection(_collection).doc(tripId).delete();
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  // Get upcoming trips
  Stream<List<TripModel>> getUpcomingTrips(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          // Filter and sort in memory to avoid composite index requirement
          final trips = snapshot.docs
              .map((doc) => TripModel.fromMap(doc.data(), doc.id))
              .where((trip) => trip.startDate.isAfter(now) || 
                              trip.startDate.isAtSameMomentAs(now))
              .toList();
          trips.sort((a, b) => a.startDate.compareTo(b.startDate));
          return trips;
        });
  }

  // Get past trips
  Stream<List<TripModel>> getPastTrips(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          // Filter and sort in memory to avoid composite index requirement
          final trips = snapshot.docs
              .map((doc) => TripModel.fromMap(doc.data(), doc.id))
              .where((trip) => trip.startDate.isBefore(now))
              .toList();
          trips.sort((a, b) => b.startDate.compareTo(a.startDate));
          return trips;
        });
  }
}
