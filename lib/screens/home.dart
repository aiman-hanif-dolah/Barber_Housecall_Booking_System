// lib/screens/home.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../util/colors.dart';
import '../util/route_transitions.dart';
import 'barber.dart';
import 'customer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  String? _phoneNumber;
  bool _isBarber = false;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phoneNumber == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _signInWithPhone(context);
      });
    }
  }

  Future<void> _registerUser(String phone) async {
    try {
      // Here, we can register the user with basic information.
      // For example, you can set a default role as 'customer' or ask the user for more details.
      await FirebaseFirestore.instance.collection('users').add({
        'phoneNumber': phone,
        'role': 'customer',  // Default role can be 'customer', 'barber', etc.
        // Add other necessary fields like name, email, etc.
      });

      setState(() {
        _isBarber = false;  // Default to 'false' unless specified later.
        _phoneNumber = phone;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    setState(() {
      _phoneNumber = null;
      _isBarber = false;
    });
    _signInWithPhone(context);
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPhone(BuildContext context) async {
    final rootContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PhoneLoginDialog(
          onContinue: (phone) async {
            Navigator.of(dialogContext).pop();
            await _checkUserInFirestore(rootContext, phone);
          },
          onBack: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _checkUserInFirestore(BuildContext context, String phone) async {
    if (!mounted) return;
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phone)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        // If user exists, proceed to login
        final userDoc = userSnapshot.docs.first;
        setState(() {
          _isBarber = userDoc['role'] == 'barber';
          _phoneNumber = phone;
        });
      } else {
        // If user doesn't exist, proceed to register
        await _registerUser(phone);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _phoneNumber != null
          ? AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Barber Housecall',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      )
          : null,
      body: _phoneNumber == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Barber Housecall',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Experience premium barber services at your convenience.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _AnimatedLargeButton(
                        label: 'Reserve a Slot',
                        animationAsset:
                        'assets/animations/customer_home_animation.json',
                        onTap: () {
                          Navigator.push(
                            context,
                            createRoute(
                              const CustomerHomeScreen(),
                              type: TransitionType.fade,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_isBarber)
                        _AnimatedLargeButton(
                          label: 'Barber Dashboard',
                          animationAsset: 'assets/animations/barber.json',
                          onTap: () {
                            Navigator.push(
                              context,
                              createRoute(
                                const BarberHomeScreen(),
                                type: TransitionType.fade,
                              ),
                            );
                          },
                        ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PhoneLoginDialog extends StatefulWidget {
  final Function(String phone) onContinue;
  final VoidCallback onBack;

  const PhoneLoginDialog({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  _PhoneLoginDialogState createState() => _PhoneLoginDialogState();
}

class _PhoneLoginDialogState extends State<PhoneLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  String _phone = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter your phone number to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(color: AppColors.text),
                        filled: true,
                        fillColor: AppColors.secondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: AppColors.text),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _phone = value.trim();
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            widget.onContinue(_phone);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLargeButton extends StatefulWidget {
  final String label;
  final String animationAsset;
  final VoidCallback onTap;

  const _AnimatedLargeButton({
    super.key,
    required this.label,
    required this.animationAsset,
    required this.onTap,
  });

  @override
  _AnimatedLargeButtonState createState() => _AnimatedLargeButtonState();
}

class _AnimatedLargeButtonState extends State<_AnimatedLargeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.secondary : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: _isPressed ? 160 : 100,
              child: Lottie.asset(
                widget.animationAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: TextStyle(
                fontSize: _isPressed ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
