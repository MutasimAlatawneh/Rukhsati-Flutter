import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/utils.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminders',
            style: AppStyles.headingStyle,
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 20),
          
          // Demo Reminder Card
          _buildDemoReminderCard(),
          const SizedBox(height: 16),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bookings')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .where('status', isEqualTo: 'Approved')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return const Center(
                      child: Text(' ',
                          style: TextStyle(color: Colors.white)));
                }

                final upcomingExams = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateStr = data['date'] as String? ?? '';
                  final timeStr = data['time'] as String? ?? '';
                  if (dateStr.isEmpty || timeStr.isEmpty) return false;
                  try {
                    final examDateTime = DateTime.parse('$dateStr $timeStr');
                    return examDateTime.isAfter(DateTime.now());
                  } catch (e) {
                    return false;
                  }
                }).toList();

                if (upcomingExams.isEmpty) {
                  return const Center(
                      child: Text('No upcoming exams found',
                          style: TextStyle(color: Colors.white)));
                }

                return ListView.builder(
                  itemCount: upcomingExams.length,
                  itemBuilder: (context, index) {
                    final booking = upcomingExams[index];
                    final data = booking.data() as Map<String, dynamic>;
                    final dateStr = data['date'] as String;
                    final examType = data['exam_type'] as String;
                    final testCenter = data['test_center'] as String;

                    return FutureBuilder<QuerySnapshot>(
                      future: _firestore
                          .collection('centers')
                          .doc(testCenter)
                          .collection('time_slots')
                          .where('date', isEqualTo: dateStr)
                          .where('test_type', isEqualTo: examType)
                          .limit(1)
                          .get(),
                      builder: (context, slotSnapshot) {
                        if (slotSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading...', style: TextStyle(color: Colors.white)),
                          );
                        }
                        if (slotSnapshot.hasError || slotSnapshot.data == null || slotSnapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final slotData = slotSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                        final timeStr = slotData['time'] as String? ?? '';

                        if (timeStr.isEmpty) return const SizedBox.shrink();

                        try {
                          final examDateTime = DateTime.parse('$dateStr $timeStr');
                          final now = DateTime.now();
                          final difference = examDateTime.difference(now);

                          // You may want to move the SnackBar logic elsewhere to avoid showing multiple SnackBars
                          // in a list context.

                          return Card(
                            color: Colors.grey[900],
                            child: ListTile(
                              title: Text(
                                '$examType Exam',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Date: $dateStr\nTime: $timeStr\nCenter: $testCenter',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoReminderCard() {
    final now = DateTime.now();
    final demoExamDate = now.add(const Duration(days: 3));
    final formatter = DateFormat('yyyy-MM-dd');
    
    return Card(
      color: Colors.orange[900]?.withOpacity(0.8),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange[300],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theoretical Driving Test',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, 
                           size: 16, 
                           color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        'Date: ${formatter.format(demoExamDate)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, 
                           size: 16, 
                           color: Colors.white70),
                      const SizedBox(width: 6),
                      const Text(
                        'Time: 10:30 AM',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, 
                           size: 16, 
                           color: Colors.white70),
                      const SizedBox(width: 6),
                      const Text(
                        'Center: Zarqa Driving Center',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, 
                      vertical: 6
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '3 days remaining',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Check and send notifications
    _checkAndSendNotifications();
  }

  Future<void> _checkAndSendNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: 'Approved')
          .get();

      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String;
        final examType = data['exam_type'] as String;
        final testCenter = data['test_center'] as String;

        // Fetch the slot to get the time
        final slotSnapshot = await _firestore
            .collection('centers')
            .doc(testCenter)
            .collection('time_slots')
            .where('date', isEqualTo: dateStr)
            .where('test_type', isEqualTo: examType)
            .limit(1)
            .get();

        if (slotSnapshot.docs.isEmpty) {
          continue; // Skip if no slot found
        }

        final slotData = slotSnapshot.docs.first.data() as Map<String, dynamic>;
        final timeStr = slotData['time'] as String? ?? '';

        if (timeStr.isEmpty) continue;

        try {
          final examDateTime = DateTime.parse('$dateStr $timeStr');
          final difference = examDateTime.difference(now);

          if (difference.inDays == 7 &&
              difference.inHours >= 168 &&
              difference.inHours <= 170) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('7-day reminder for $examType exam')),
            );
          } else if (difference.inHours == 24 &&
              difference.inMinutes >= 1440 &&
              difference.inMinutes <= 1460) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('24-hour reminder for $examType exam')),
            );
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking notifications: $e')),
        );
      }
    }
  }
}