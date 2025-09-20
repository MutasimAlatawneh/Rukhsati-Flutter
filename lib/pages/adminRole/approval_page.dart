import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/utils.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final List<String> _rejectionReasons = [
    'Cooldown active',
    'No theoretical pass',
    'Other',
  ];
  String? _centerId; 

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  Future<void> _verifyAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists || doc.data()?['role'] != 'center_admin' || doc.data()?['center'] == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }
    setState(() {
      _centerId = doc.data()?['center'];
    });
  }

  Stream<QuerySnapshot> _fetchPendingBookings() {
    if (_centerId == null) {
      return Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('test_center', isEqualTo: _centerId)
        .where('status', isEqualTo: 'Pending')
        .snapshots();
  }

  Future<bool> _canApproveBooking(Map<String, dynamic> booking) async {
    try {
      final userId = booking['userId'];
      final testType = booking['test_type'];

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;
      final now = DateTime.now();
      final testHistory = userData['test_history'] as List<dynamic>? ?? [];

      if (testType == 'practical') {
        if (userData['theoretical_pass_date'] == null) {
          return false;
        }
      }

      final cooldownDays = testType == 'theoretical' ? 14 : 21;
      for (var history in testHistory) {
        if (history['test_type'] == testType && history['result'] == 'fail') {
          final testDate = (history['date'] as Timestamp).toDate();
          final daysSinceFail = now.difference(testDate).inDays;
          if (daysSinceFail < cooldownDays) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('Error in _canApproveBooking: $e');
      return false;
    }
  }

  void _approveBooking(String bookingId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final booking = doc.data()!;

      final canApprove = await _canApproveBooking(booking);

      if (!canApprove) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot approve: Check theoretical pass or cooldown.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'Approved'}); // or 'Rejected'

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking approved.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error in _approveBooking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectBooking(String bookingId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'rejected'
        ,
        'rejection_reason': reason,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking rejected: $reason'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error in _rejectBooking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Approvals',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _fetchPendingBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('ApprovalPage Error: ${snapshot.error}');
              return const Center(
                child: Text(
                  'Error loading bookings.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No pending bookings.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            final bookings = snapshot.data!.docs;

            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                 
                final booking = bookings[index].data() as Map<String, dynamic>;
                final bookingId = bookings[index].id;

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking ID: $bookingId',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User ID: ${booking['userId']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Test Type: ${booking['exam_type']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Date: ${booking['date']} ',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => _approveBooking(bookingId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Approve'),
                            ),
                            DropdownButton<String>(
                              hint: const Text(
                                'Reject with Reason',
                                style: TextStyle(color: Colors.white70),
                              ),
                              items: _rejectionReasons.map((reason) {
                                return DropdownMenuItem(
                                  value: reason,
                                  child: Text(
                                    reason,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                              onChanged: (reason) {
                                if (reason != null) {
                                  _rejectBooking(bookingId, reason);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}