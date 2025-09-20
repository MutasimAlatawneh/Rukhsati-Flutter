import 'package:flutter/material.dart';

class PromoRemindersPage extends StatelessWidget {
  const PromoRemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for promotional purposes
    final List<Map<String, String>> dummyReminders = [
      {
        'examType': 'Driving Theory',
        'date': '2024-04-15',
        'time': '10:00 AM',
        'center': 'City Driving Center',
        'daysLeft': '7 days left',
      },
      {
        'examType': 'Practical Driving',
        'date': '2024-04-10',
        'time': '2:30 PM',
        'center': 'Downtown Test Center',
        'daysLeft': '24 hours left',
      },
      {
        'examType': 'Highway Driving',
        'date': '2024-04-20',
        'time': '11:15 AM',
        'center': 'Highway Training Complex',
        'daysLeft': '12 days left',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Test Reminders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: dummyReminders.length,
              itemBuilder: (context, index) {
                final reminder = dummyReminders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  color: Colors.grey[900],
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reminder['examType']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            reminder['daysLeft']!,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${reminder['date']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'Time: ${reminder['time']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'Center: ${reminder['center']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 