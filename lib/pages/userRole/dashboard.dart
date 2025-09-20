import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/state_management.dart';
import '../../utils/utils.dart';
import 'booking_page.dart';
import 'appointments_page.dart';
import 'reminders_page.dart';
import 'guideliness_page.dart';
import 'profile_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SafeState<Dashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    await safeAsync(
      () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not signed in');
        }

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          throw Exception('User data not found in Firestore');
        }

        _userData = {
          'email': userDoc.data()?['email'] ?? user.email,
          'role': userDoc.data()?['role'] ?? 'user',
          'center': userDoc.data()?['center'],
          'test_history': userDoc.data()?['test_history'] ?? [],
        };
      },
      successMessage: 'User data loaded successfully',
      errorMessage: 'Failed to load user data',
      onSuccess: () {
        safeSetState(() {
          _isLoadingUserData = false;
        });
      },
      showLoadingIndicator: false,
    );
  }

  void _onItemTapped(int index) {
    safeSetState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await safeAsync(
      () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      },
      successMessage: 'Signed out successfully',
      errorMessage: 'Failed to sign out',
      showLoadingIndicator: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Image.asset(
          'assets/logoo.png',
          height: 40,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _userData == null
              ? const Center(
                  child: Text(
                    'Failed to load user data',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : _buildPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Book Exam',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Guidelines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF5F7FA),
        unselectedItemColor: Colors.grey,
        backgroundColor: AppStyles.backgroundColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildPage() {
    final List<Widget> pages = [
      const BookingPage(),
      const AppointmentsPage(),
      const RemindersPage(),
      const GuidelinesPage(),
      ProfilePage(userData: _userData!), // Pass user data to ProfilePage
    ];
    return pages[_selectedIndex];
  }
}