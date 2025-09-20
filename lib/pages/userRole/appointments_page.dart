import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/utils.dart';
import '../../utils/state_management.dart'; // Add this import

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> 
    with SafeState<AppointmentsPage> { // Add SafeState mixin
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _cancellingBookings = {}; // Track multiple cancellations

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.backgroundColor,
        title: Text(
          'Your Appointments',
          style: AppStyles.headingStyle,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .orderBy('date', descending: false) // Add sorting
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No appointments found', style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index];
              var data = booking.data() as Map<String, dynamic>;
              String bookingId = booking.id;
              String status = data['status'] ?? 'Pending';
              bool isCancelling = _cancellingBookings.contains(bookingId); // ACTUALLY USE THE STATE

              return Card(
                color: const Color.fromARGB(255, 93, 148, 143),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${data['exam_type']} Test',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Approved'
                                  ? Colors.green
                                  : status == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Center: ${data['test_center']}', style: const TextStyle(color: Colors.white)),
                      Text('Date: ${data['date']}', style: const TextStyle(color: Colors.white)),
                      // Add FutureBuilder for time slot
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore
                            .collection('centers')
                            .doc(data['test_center'])
                            .collection('time_slots')
                            .where('date', isEqualTo: data['date'])
                            .where('test_type', isEqualTo: data['exam_type'])
                            .limit(1)
                            .get(),
                        builder: (context, slotSnapshot) {
                          if (slotSnapshot.connectionState == ConnectionState.waiting) {
                            return const Text('Time: ...', style: TextStyle(color: Colors.white70));
                          }
                          if (slotSnapshot.hasError || slotSnapshot.data == null || slotSnapshot.data!.docs.isEmpty) {
                            return const Text('Time: Not found', style: TextStyle(color: Colors.red));
                          }
                          final slotData = slotSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                          final time = slotData['time'] ?? 'N/A';
                          return Text('Time: $time', style: const TextStyle(color: Colors.white));
                        },
                      ),
                      const SizedBox(height: 12),
                      if (status == 'Pending' && !isCancelling)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _cancelBooking(bookingId, data),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      if (isCancelling) // ACTUALLY USE THE STATE IN UI
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _cancelBooking(String bookingId, Map<String, dynamic> bookingData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 93, 148, 143),
        title: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to cancel this booking?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              safeSetState(() => _cancellingBookings.add(bookingId)); // ADD TO SET
              
              await safeAsync( // Use safeAsync for cancellation
                () async {
                  final slotSnapshot = await _firestore
                      .collection('slots')
                      .where('center', isEqualTo: bookingData['test_center'])
                      .where('date', isEqualTo: bookingData['date'])
                      .where('time', isEqualTo: bookingData['time'])
                      .get();

                  if (slotSnapshot.docs.isEmpty) {
                    throw Exception('Slot not found');
                  }

                  final slotDoc = slotSnapshot.docs.first;
                  final batch = _firestore.batch();
                  batch.delete(_firestore.collection('bookings').doc(bookingId));
                  batch.update(slotDoc.reference, {
                    'available_seats': FieldValue.increment(1),
                  });

                  await batch.commit();
                },
                successMessage: 'Booking cancelled successfully',
                errorMessage: 'Error cancelling booking',
              );
              
              safeSetState(() => _cancellingBookings.remove(bookingId)); // REMOVE FROM SET
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}