import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String? id;
  final String userId;
  final String destination;
  final int numberOfDays;
  final DateTime startDate;
  final double budget;
  final String? budgetCurrency;
  final String? travelStyle;
  final List<String>? interests;
  final String? specialRequirements;
  final String itinerary;
  final DateTime createdAt;

  TripModel({
    this.id,
    required this.userId,
    required this.destination,
    required this.numberOfDays,
    required this.startDate,
    required this.budget,
    this.budgetCurrency = 'INR',
    this.travelStyle,
    this.interests,
    this.specialRequirements,
    required this.itinerary,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'destination': destination,
      'numberOfDays': numberOfDays,
      'startDate': Timestamp.fromDate(startDate),
      'budget': budget,
      'budgetCurrency': budgetCurrency,
      'travelStyle': travelStyle,
      'interests': interests,
      'specialRequirements': specialRequirements,
      'itinerary': itinerary,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      userId: map['userId'] ?? '',
      destination: map['destination'] ?? '',
      numberOfDays: map['numberOfDays'] ?? 1,
      startDate: (map['startDate'] as Timestamp).toDate(),
      budget: (map['budget'] ?? 0).toDouble(),
      budgetCurrency: map['budgetCurrency'] ?? 'INR',
      travelStyle: map['travelStyle'],
      interests: map['interests'] != null 
          ? List<String>.from(map['interests']) 
          : null,
      specialRequirements: map['specialRequirements'],
      itinerary: map['itinerary'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  TripModel copyWith({
    String? id,
    String? userId,
    String? destination,
    int? numberOfDays,
    DateTime? startDate,
    double? budget,
    String? budgetCurrency,
    String? travelStyle,
    List<String>? interests,
    String? specialRequirements,
    String? itinerary,
    DateTime? createdAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      startDate: startDate ?? this.startDate,
      budget: budget ?? this.budget,
      budgetCurrency: budgetCurrency ?? this.budgetCurrency,
      travelStyle: travelStyle ?? this.travelStyle,
      interests: interests ?? this.interests,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      itinerary: itinerary ?? this.itinerary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TripRequest {
  final String destination;
  final int numberOfDays;
  final DateTime startDate;
  final double budget;
  final String budgetCurrency;
  final String? travelStyle;
  final List<String>? interests;
  final String? specialRequirements;

  TripRequest({
    required this.destination,
    required this.numberOfDays,
    required this.startDate,
    required this.budget,
    this.budgetCurrency = 'INR',
    this.travelStyle,
    this.interests,
    this.specialRequirements,
  });
}
