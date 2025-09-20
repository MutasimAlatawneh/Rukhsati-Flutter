import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _theoreticalCooldownController = TextEditingController();
  final TextEditingController _practicalCooldownController = TextEditingController();
  final TextEditingController _maxSeatsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
    _loadSettings();
  }

  Future<void> _verifyAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data()?['role'] != 'center_admin') {
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('global').get();
    if (doc.exists && mounted) { // <-- check mounted before setState
      setState(() {
        _theoreticalCooldownController.text = doc.data()?['theoretical_cooldown']?.toString() ?? '14';
        _practicalCooldownController.text = doc.data()?['practical_cooldown']?.toString() ?? '21';
        _maxSeatsController.text = doc.data()?['max_seats']?.toString() ?? '10';
      });
    }
  }

  Future<void> _saveSettings() async {
    final theoretical = int.tryParse(_theoreticalCooldownController.text) ?? 14;
    final practical = int.tryParse(_practicalCooldownController.text) ?? 21;
    final maxSeats = int.tryParse(_maxSeatsController.text) ?? 10;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('global').set({
        'theoretical_cooldown': theoretical,
        'practical_cooldown': practical,
        'max_seats': maxSeats,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _theoreticalCooldownController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Theoretical Cooldown (days)',
                labelStyle: TextStyle(color: Color.fromARGB(179, 245, 242, 242)),
                filled: true,
                fillColor: Color.fromARGB(0, 255, 255, 255),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _practicalCooldownController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Practical Cooldown (days)',
                labelStyle: TextStyle(color: Color.fromARGB(179, 245, 242, 242)),
                filled: true,
                fillColor: Color.fromARGB(0, 255, 255, 255),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
             
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}