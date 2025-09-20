import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/state_management.dart';
import '../../utils/utils.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfilePage({super.key, this.userData});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SafeState<ProfilePage> {
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showSnackBar('Cannot open phone app', isError: true);
    }
  }

  Future<void> _signOut() async {
    await safeAsync(
      () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/auth');
      },
      successMessage: 'Signed out successfully',
      errorMessage: 'Failed to sign out',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Profile Page',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (widget.userData == null)
                    const Center(
                      child: Text(
                        'failed to load user data',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    )
                  else ...[
                     Card(
                      color: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildInfoRow(': Name ', widget.userData!['displayName'] ?? 'not set'),
                            const Divider(color: Colors.white24),
                            _buildInfoRow(': Email', widget.userData!['email'] ?? 'not set'),
                            const Divider(color: Colors.white24),
                            _buildInfoRow(': Role', widget.userData!['role'] ?? 'not set'),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Support Center Section
                    const Text(
                      'Support Center',
                       style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.phone, color: Colors.white),
                              title: const Text(
                                'Contact Us',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: const Text(
                                '+962 7 8817 1228',
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.phone_outlined, color: Colors.white),
                                onPressed: () => _launchPhone('+962788171228'),
                              ),
                              onTap: () => _launchPhone('+962788171228'),
                            ),
                            const Divider(color: Colors.white24),
                            const ListTile(
                              leading: Icon(Icons.access_time, color: Colors.white),
                              title: Text(
                                'Working Hours',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'الأحد - الخميس\n8:00 ص - 4:00 م',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Logout Button
                   ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70),
          ),
        ],
      ),
    );
  }
}