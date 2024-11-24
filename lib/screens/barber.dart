// lib/screens/barber_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart'; // Ensure this package is added in pubspec.yaml

import '../util/colors.dart';

class BarberHomeScreen extends StatefulWidget {
  const BarberHomeScreen({super.key});

  @override
  State<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends State<BarberHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<DocumentSnapshot> pendingReservations = [];
  List<DocumentSnapshot> approvedReservations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this);

    // Start fetching reservations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchReservations();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Fetches all reservations from Firestore
  Future<void> fetchReservations() async {
    try {
      // Fetch pending reservations
      QuerySnapshot pendingSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: 'pending')
          .get();

      // Fetch approved reservations
      QuerySnapshot approvedSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: 'approved')
          .get();

      setState(() {
        pendingReservations = pendingSnapshot.docs;
        approvedReservations = approvedSnapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      _showError('🚨 Error retrieving reservations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Approves a reservation by updating its status in Firestore
  Future<void> approveReservation(String reservationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({'status': 'approved'});

      await fetchReservations();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Reservation approved.')),
      );
    } catch (e) {
      _showError('🚨 Error approving reservation: $e');
    }
  }

  /// Deletes a reservation from Firestore
  Future<void> deleteReservation(String reservationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .delete();

      await fetchReservations();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Reservation deleted.')),
      );
    } catch (e) {
      _showError('🚨 Error deleting reservation: $e');
    }
  }

  /// Displays error messages using SnackBar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Builds the Lottie animation widget
  Widget _buildAnimation(BuildContext context) {
    double animationHeight = MediaQuery.of(context).size.height * 0.2;

    return FadeInDown(
      child: SizedBox(
        height: animationHeight,
        child: Lottie.asset(
          'assets/animations/barber.json',
          controller: _animationController,
          onLoaded: (composition) {
            // Set the duration and start the animation
            _animationController.duration = composition.duration;
            _animationController.forward();
          },
          repeat: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Formats DateTime objects into readable strings
  String formatDate(DateTime dateTime) {
    return DateFormat('EEEE, yyyy-MM-dd | hh:mm a').format(dateTime);
  }

  /// Builds a list of reservations (pending or approved)
  Widget _buildReservationList(
      List<DocumentSnapshot> reservations, bool isPending) {
    return reservations.isEmpty
        ? Center(
      child: Text(
        isPending
            ? 'No pending reservations.'
            : 'No approved reservations.',
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.textSecondary,
        ),
      ),
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        var reservation =
        reservations[index].data() as Map<String, dynamic>;
        DateTime reservationTime =
        (reservation['dateTime'] as Timestamp).toDate();
        String customerName = reservation['customerName'];
        String phoneNumber = reservation['phoneNumber'];

        return SlideInUp(
          duration: const Duration(milliseconds: 500),
          child: Card(
            color: Colors.white,
            elevation: 4,
            margin:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👤 Client: $customerName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '📞 Phone: $phoneNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '🕒 Time: ${formatDate(reservationTime)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPending)
                        BounceInRight(
                          duration: const Duration(milliseconds: 500),
                          child: TextButton.icon(
                            onPressed: () {
                              approveReservation(reservations[index].id);
                            },
                            icon: const Icon(Icons.check_circle,
                                color: AppColors.primary),
                            label: const Text(
                              'Approve',
                              style:
                              TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      BounceInLeft(
                        duration: const Duration(milliseconds: 500),
                        child: TextButton.icon(
                          onPressed: () {
                            deleteReservation(reservations[index].id);
                          },
                          icon: const Icon(Icons.delete,
                              color: AppColors.secondary),
                          label: const Text(
                            'Delete',
                            style:
                            TextStyle(color: AppColors.secondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner if isLoading is true, else show the reservations
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: Colors.white, // Default back button color
        ),
        title: const Text(
          'Dashboard✂️',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back to HomeScreen
          },
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildAnimation(context),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.07,
                      child: const TabBar(
                        labelColor: AppColors.text,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.text,
                        tabs: [
                          Tab(text: '🟡 Pending'),
                          Tab(text: '🟢 Approved'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildReservationList(pendingReservations, true),
                          _buildReservationList(approvedReservations, false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
