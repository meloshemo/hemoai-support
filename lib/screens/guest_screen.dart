import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('continue_as_guest'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(loc.getString('guest_mode_description'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.person),
              label: Text(loc.getString('edit_profile')),
              onPressed: () {
                Navigator.pushNamed(context, '/personal_info');
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.bloodtype),
              label: Text(loc.getString('hemogram_entry')),
              onPressed: () {
                Navigator.pushNamed(context, '/hemogram_entry');
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.analytics),
              label: Text(loc.getString('analysis')),
              onPressed: () {
                Navigator.pushNamed(context, '/analysis');
              },
            ),
          ],
        ),
      ),
    );
  }
}
