import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_form_widgets.dart';
import '../../utils/state_management.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with SafeState<BookingPage> {
  String? _selectedExamType;
  String? _selectedTestCenter;
  String? _selectedTime;
  DateTime? _selectedDate;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isDataLoading = true;

  // Lists to store data from Firestore
  List<Map<String, dynamic>> _examTypes = [];
  List<Map<String, dynamic>> _testCenters = [];
  List<Map<String, dynamic>> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await safeAsync(
      () async {
        await Future.wait([
          _fetchExamTypes(),
          _fetchTestCenters(),
        ]);
      },
      errorMessage: 'Failed to load initial data',
      onSuccess: () {
        safeSetState(() {
          _isDataLoading = false;
        });
      },
      showLoadingIndicator: false,
    );
  }

  Future<void> _fetchExamTypes() async {
    final snapshot = await _firestore.collection('exam_types').get();
    safeSetState(() {
      _examTypes = snapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['name'],
          }).toList();
    });
  }

  Future<void> _fetchTestCenters() async {
    final snapshot = await _firestore.collection('test_centers').get();
    safeSetState(() {
      _testCenters = snapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['name'],
            'location': doc['location'],
          }).toList();
    });
  }

  Future<void> _fetchAvailableSlots() async {
    if (_selectedTestCenter == null || _selectedDate == null || _selectedExamType == null) {
      safeSetState(() {
        _availableSlots = [];
        _selectedTime = null;
      });
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final snapshot = await _firestore
        .collection('centers')
        .doc('Zarqa')
        .collection('time_slots')
        .where('isAvailable', isEqualTo: true)
        .where('test_type', isEqualTo: _selectedExamType)
        .get();

    safeSetState(() {
      _availableSlots = snapshot.docs
          .where((doc) {
            final ts = doc['date'];
            String dateStr;
            if (ts is Timestamp) {
              dateStr = DateFormat('yyyy-MM-dd').format(ts.toDate());
            } else if (ts is String) {
              dateStr = ts;
            } else {
              return false;
            }
            return dateStr == formattedDate &&
                (doc['max_seats'] ?? 0) - (doc['booked_seats'] ?? 0) > 0;
          })
          .map((doc) => {
                'id': doc.id,
                'time': doc['time'],
                'available_seats': (doc['max_seats'] ?? 0) - (doc['booked_seats'] ?? 0),
              })
          .toList();
      
    });
  }

  Future<bool> _canBookExam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final testHistory = userDoc.data()?['test_history'] as List<dynamic>? ?? [];

    if (_selectedExamType == 'Practical') {
      final hasPassedTheoretical = testHistory.any((test) =>
          test['exam_type'] == 'Theoretical' && test['result'] == 'pass');
      if (!hasPassedTheoretical) {
        showSnackBar('You must pass the theoretical test first', isError: true);
        return false;
      }
    }

    final settings = await _firestore.collection('settings').doc('global').get();
    final theoreticalCooldown = settings.data()?['theoretical_cooldown'] ?? 14;
    final practicalCooldown = settings.data()?['practical_cooldown'] ?? 21;

    final now = DateTime.now();
    for (var test in testHistory) {
      final testDate = DateTime.parse(test['date']);
      final daysSinceTest = now.difference(testDate).inDays;

      if (test['exam_type'] == _selectedExamType && test['result'] == 'fail') {
        final cooldown = _selectedExamType == 'Theoretical'
            ? theoreticalCooldown
            : practicalCooldown;
        if (daysSinceTest < cooldown) {
          showSnackBar(
              'You must wait $cooldown days before retaking this exam',
              isError: true);
          return false;
        }
      }
    }

    return true;
  }

  Set<String> _availableDates = {};

  Future<void> _fetchAvailableDates() async {
    if (_selectedTestCenter == null || _selectedExamType == null) {
      safeSetState(() => _availableDates = {});
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('centers')
        .doc(_selectedTestCenter) 
        .collection('time_slots')
        .where('isAvailable', isEqualTo: true)
        .where('test_type', isEqualTo: _selectedExamType)
        .get();

    final availableDates = snapshot.docs
        .where((doc) => (doc['max_seats'] ?? 0) - (doc['booked_seats'] ?? 0) > 0)
        .map((doc) {
          final ts = doc['date'];
          if (ts is Timestamp) {
            return DateFormat('yyyy-MM-dd').format(ts.toDate());
          } else if (ts is String) {
            return ts;
          }
          return null;
        })
        .whereType<String>()
        .toSet();

    safeSetState(() {
      _availableDates = availableDates;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_selectedTestCenter == null) return;
    await _fetchAvailableDates();

    // Convert available dates to DateTime and sort
    final availableDateTimes = _availableDates
        .map((d) => DateFormat('yyyy-MM-dd').parse(d))
        .where((d) => !d.isBefore(DateTime.now()))
        .toList()
      ..sort();

    if (availableDateTimes.isEmpty) {
      showSnackBar('No available dates for this center', isError: true);
      return;
    }

    // Set initialDate to the first available date if today is not available
    DateTime initialDate = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(initialDate);
    if (!_availableDates.contains(todayStr)) {
      initialDate = availableDateTimes.first;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        return _availableDates.contains(formattedDate);
      },
    );

    if (picked != null && picked != _selectedDate) {
      safeSetState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
      await _fetchAvailableSlots();
    }
  }

  Future<void> _bookExam() async {
    if (_selectedExamType == null ||
        _selectedTestCenter == null ||
        _selectedDate == null) {
      showSnackBar('Please fill all fields', isError: true);
      return;
    }

    if (!(await _canBookExam())) {
      return;
    }

    await safeAsync(
      () async {
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        final bookingData = {
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'exam_type': _selectedExamType,
          'test_center': _selectedTestCenter,
          'date': formattedDate,
          'status': 'Pending',
        };

        // Update available seats in the slot
        final slotSnapshot = await _firestore
            .collection('centers')
            .doc(_selectedTestCenter)
            .collection('time_slots')
            .where('date', isEqualTo: formattedDate)
            .where('isAvailable', isEqualTo: true)
            .where('test_type', isEqualTo: _selectedExamType)
            .get();

        if (slotSnapshot.docs.isEmpty) {
          showSnackBar('Selected slot is no longer available', isError: true);
          return;
        }

        final slotDoc = slotSnapshot.docs.first;
        final availableSeats = (slotDoc['max_seats'] ?? 0) - (slotDoc['booked_seats'] ?? 0);
        if (availableSeats <= 0) {
          showSnackBar('No available seats for this slot', isError: true);
          return;
        }

        final batch = _firestore.batch();
        batch.set(_firestore.collection('bookings').doc(), bookingData);
        batch.update(slotDoc.reference, {
          'booked_seats': FieldValue.increment(1),
        });

        await batch.commit();
      },
      successMessage: 'Booking successful!',
      errorMessage: 'Failed to book exam',
      showLoadingIndicator: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Your Exam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (_isDataLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else ...[
              CustomDropdownField<String>(
                label: 'Exam Type',
                value: _selectedExamType,
                items: _examTypes
                    .map((examType) => DropdownMenuItem<String>(
                          value: examType['id'] as String,
                          child: Text(
                            examType['name'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) => safeSetState(() {
                  _selectedExamType = value;
                  _selectedDate = null;
                  _availableSlots = [];
                }),
              ),
              const SizedBox(height: 20),
              CustomDropdownField<String>(
                label: 'Test Center',
                value: _selectedTestCenter,
                items: _testCenters
                    .map((center) => DropdownMenuItem<String>(
                          value: center['id'] as String,
                          child: Text(
                            center['name'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) => safeSetState(() {
                  _selectedTestCenter = value;
                  _selectedDate = null;
                  _selectedTime = null;
                  _availableSlots = [];
                }),
              ),
              const SizedBox(height: 20),
              CustomTextFormField(
                label: 'Select Date',
                readOnly: true,
                onTap: _selectedTestCenter != null ? () => _selectDate(context) : null,
                hint: _selectedDate == null
                    ? 'Select a test center first'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Book Now',
                onPressed: _bookExam,
                isLoading: _isLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }
}