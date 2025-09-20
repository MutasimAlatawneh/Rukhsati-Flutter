import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/utils.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  final TextEditingController _maxSeatsController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _centerId;
  final List<String> _testTypes = ['Theoretical', 'Practical'];
  String? _selectedTestType;

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }
 
 Future<void> _verifyAdminAccess() async {
  try {
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
      _centerId = doc.data()!['center'];
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying access: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/auth');  
    }
  }
}

  @override
  void dispose() {
    _maxSeatsController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _fetchTimeSlots() {
    if (_centerId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('centers')
        .doc(_centerId)
        .collection('time_slots')
        .orderBy('date')
        .orderBy('time')
        .snapshots();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addTimeSlot() async {
    if (_centerId == null || _selectedDate == null || _selectedTime == null || _maxSeatsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final maxSeats = int.tryParse(_maxSeatsController.text);
    if (maxSeats == null || maxSeats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of seats.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final timeStr = _selectedTime!.format(context);

    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc('Zarqa') // or _centerId if that's set to 'Zarqa'
          .collection('time_slots')
          .add({
        'date': dateStr,
        'time': timeStr,
        'max_seats': maxSeats,
        'booked_seats': 0,
        'isAvailable': true,
        'test_type': _selectedTestType, // <-- This is critical!
      });

      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _maxSeatsController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slot added.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding time slot: $e'),
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
          'Manage Availability',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Time Slot',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- Add this DropdownButtonFormField here ---
            DropdownButtonFormField<String>(
              value: _selectedTestType,
              items: _testTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTestType = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Test Type',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color.fromARGB(0, 158, 158, 158),
                border: OutlineInputBorder(),
              ),
              dropdownColor: Colors.grey,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // --- End dropdown ---

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text(_selectedDate == null
                        ? 'Select Date'
                        : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime(context),
                    child: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxSeatsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Seats',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color.fromARGB(0, 158, 158, 158),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTimeSlot,
              child: const Text('Add Time Slot'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Time Slots',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400, // or use MediaQuery for dynamic height if needed
              child: StreamBuilder<QuerySnapshot>(
                stream: _fetchTimeSlots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('AvailabilityPage Error: ${snapshot.error}'); 
                    return Center(
                      child: Text('Error loading time slots: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No time slots found.', style: TextStyle(color: Colors.white)),
                    );
                  }

                  final slots = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index].data() as Map<String, dynamic>;
                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          title: Text(
                            'Date: ${slot['date']} Time: ${slot['time']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Available Seats: ${slot['max_seats'] - slot['booked_seats']}/${slot['max_seats']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('centers')
                                    .doc(_centerId)
                                    .collection('time_slots')
                                    .doc(slots[index].id)
                                    .delete();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Time slot deleted.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting time slot: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}