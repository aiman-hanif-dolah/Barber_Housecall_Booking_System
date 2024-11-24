// models/reservation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String customerName;
  final String phoneNumber; // Added phoneNumber field
  final DateTime dateTime;
  final String status;

  ReservationModel({
    required this.customerName,
    required this.phoneNumber, // Include phoneNumber in constructor
    required this.dateTime,
    required this.status,
  });

  factory ReservationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '', // Retrieve phoneNumber from data
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      status: data['status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'phoneNumber': phoneNumber, // Include phoneNumber in map
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
