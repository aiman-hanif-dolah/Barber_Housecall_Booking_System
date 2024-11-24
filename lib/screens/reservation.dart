import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart'; // For widget animations
import 'package:table_calendar/table_calendar.dart'; // Import the calendar package

import '../models/reservation_model.dart';
import '../util/colors.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with TickerProviderStateMixin {
  // User Input Variables
  String? customerName;
  String? phoneNumber;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _lottieController;

  // Available Time Slots
  List<TimeOfDay> availableTimes = [];

  // Calendar-related Variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1));
  DateTime? _selectedDay;

  // List of Fully Booked Days
  List<DateTime> fullyBookedDays = [];

  // Form Key for Validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize Fade Animation Controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500), // Fast fade-up
      vsync: this,
    );

    // Define Fade Animation
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start the fade animation
    _fadeController.forward();

    // Initialize Lottie Animation Controller
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // Loop the animation smoothly

    // Initialize available times
    generateAvailableTimes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  /// Generates available time slots from 9 AM to 12 AM in 30-minute increments
  void generateAvailableTimes() {
    availableTimes.clear();
    for (int hour = 9; hour < 24; hour++) { // 9 AM to 11:30 PM
      availableTimes.add(TimeOfDay(hour: hour, minute: 0));
      availableTimes.add(TimeOfDay(hour: hour, minute: 30));
    }
    // Note: TimeOfDay does not support 24:00, so the last slot is 11:30 PM
  }

  /// Handles date selection from the calendar
  Future<void> onDateSelected(DateTime selected, DateTime focused) async {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
      selectedDate = selected;
      selectedTime = null; // Reset time when date changes
    });
    await fetchBookedTimes();
  }

  /// Opens a modal bottom sheet for time selection with a grid layout
  Future<void> selectTime() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }

    if (availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available times on the selected date')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: availableTimes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2, // Responsive columns
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3, // Adjust as needed
            ),
            itemBuilder: (context, index) {
              TimeOfDay time = availableTimes[index];
              bool isSelected = selectedTime == time;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primary : Colors.white,
                  side: BorderSide(
                    color: AppColors.primary,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    selectedTime = time;
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  time.format(context),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Fetches booked times from Firestore for the selected date
  Future<void> fetchBookedTimes() async {
    if (selectedDate == null) return;

    DateTime startOfDay =
    DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 0, 0, 0);
    DateTime endOfDay =
    DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      List<DateTime> bookedTimes = snapshot.docs.map((doc) {
        return (doc['dateTime'] as Timestamp).toDate();
      }).toList();

      setState(() {
        generateAvailableTimes();
        availableTimes.removeWhere((time) {
          DateTime dateTime = DateTime(
              selectedDate!.year, selectedDate!.month, selectedDate!.day, time.hour, time.minute);
          return bookedTimes.any((bookedTime) =>
          bookedTime.year == dateTime.year &&
              bookedTime.month == dateTime.month &&
              bookedTime.day == dateTime.day &&
              bookedTime.hour == dateTime.hour &&
              bookedTime.minute == dateTime.minute);
        });

        // Check if all time slots are booked
        if (availableTimes.isEmpty) {
          fullyBookedDays.add(selectedDate!);
        } else {
          fullyBookedDays.removeWhere((day) => isSameDay(day, selectedDate!));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching booked times: $e')),
      );
    }
  }

  /// Reserves the selected time slot by adding it to Firestore
  Future<void> reserveSlot() async {
    if (!_formKey.currentState!.validate()) {
      // If the form is invalid, do not proceed.
      return;
    }

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    DateTime dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('dateTime', isEqualTo: Timestamp.fromDate(dateTime))
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot already booked')),
        );
        // Refresh the booked times to reflect the current state
        await fetchBookedTimes();
        return;
      }

      ReservationModel reservation = ReservationModel(
        customerName: customerName!,
        phoneNumber: phoneNumber!,
        dateTime: dateTime,
        status: 'pending',
      );

      await FirebaseFirestore.instance
          .collection('reservations')
          .add(reservation.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation made successfully')),
      );

      // Refresh the available times to remove the newly booked slot
      await fetchBookedTimes();

      // Reset the form fields
      setState(() {
        customerName = null;
        phoneNumber = null;
        selectedDate = null;
        selectedTime = null;
      });
      // Optionally, reset the calendar selection
      // _selectedDay = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reserving slot: $e')),
      );
    }
  }

  /// Builds the Lottie animation widget
  Widget _buildAnimation(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.25;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        height: height,
        child: Lottie.asset(
          'assets/animations/animation1.json',
          controller: _lottieController,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Builds the TableCalendar widget
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime(2024, 12, 31), // Extended to December 31, 2024
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: onDateSelected,
      calendarFormat: _calendarFormat,
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        disabledDecoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      ),
      enabledDayPredicate: (day) {
        // Disable past days and fully booked days
        return day.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
            !fullyBookedDays.any((d) => isSameDay(d, day));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: Colors.white, // Default back button color
        ),
        title: const Text(
          'Barber Housecall',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(children: [
          _buildAnimation(context),
          Expanded(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Form(
                key: _formKey, // Assign the form key
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: const Text(
                        'Book Your Appointment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Your Name Input Field
                    SlideInLeft(
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Your Name',
                            labelStyle: TextStyle(
                              color: Colors.black87, // Updated label color for better contrast
                              fontSize: 16, // Adjust label size if necessary
                            ),
                            filled: true,
                            fillColor: Colors.white, // Set a white background for better visibility
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          onChanged: (value) {
                            customerName = value;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number Input Field
                    SlideInRight(
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Your Phone Number',
                            labelStyle:
                            const TextStyle(color: AppColors.primary),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            phoneNumber = value;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            final phoneExp = RegExp(r'^\+?1?\d{9,15}$');
                            if (!phoneExp.hasMatch(value)) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Calendar for Date Selection
                    SlideInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: selectedDate == null
                                ? AppColors.primary
                                : AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildCalendar(),
                            if (selectedDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Selected: ${DateFormat('EEEE, MMM d, yyyy').format(selectedDate!)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Time Selection ListTile
                    SlideInUp(
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedContainer(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: selectedTime == null
                                ? AppColors.primary
                                : AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: ListTile(
                          title: Text(
                            selectedTime == null
                                ? 'Select Time'
                                : selectedTime!.format(context),
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing:
                          const Icon(Icons.access_time, color: AppColors.primary),
                          onTap: selectTime,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Confirm Reservation Button
                    BounceInUp(
                      duration: const Duration(milliseconds: 700),
                      child: ElevatedButton(
                        onPressed: reserveSlot,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize:
                          Size(double.infinity, isSmallScreen ? 50 : 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor:
                          AppColors.primary.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Confirm Reservation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Cancel Button
                    FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side:
                          BorderSide(color: AppColors.primary, width: 2),
                          minimumSize:
                          Size(double.infinity, isSmallScreen ? 50 : 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
