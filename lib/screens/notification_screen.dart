import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final int dailyGoal = 8;
  int waterCount = 0;

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('notifications'))),
      body: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.getString('daily_water_tracking'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text(loc.getStringWithParams('water_goal_progress', {'count': '$waterCount', 'goal': '$dailyGoal'}), style: const TextStyle(fontSize: 18)),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (waterCount < dailyGoal) {
                      setState(() {
                        waterCount++;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.getString('water_intake_logged'))),
                      );
                    }
                  },
                  icon: Icon(Icons.local_drink),
                  label: Text(loc.getString('log_one_glass')),
                ),
                SizedBox(height: 32),
                waterCount < dailyGoal
                    ? Column(
                        children: [
                          Text(
                            loc.getString('hydration_reminder_body'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(loc.getString('water_benefits_title')),
                          SizedBox(height: 8),
                          Text(loc.getString('keep_going')),
                        ],
                      )
                    : Column(
                        children: [
                          Text(loc.getString('water_goal_completed_title'), style: const TextStyle(color: Colors.green, fontSize: 16)),
                          SizedBox(height: 8),
                          Text(loc.getString('water_goal_completed_inline')),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
