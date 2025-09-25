import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';

class DietProgramScreen extends StatelessWidget {
  const DietProgramScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kişisel Diyet Programı'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Color(0xFFE53E3E)),
            SizedBox(height: 20),
            Text(
              'Kişisel Diyet Programı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53E3E),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Hemogram sonuçlarınıza göre\nkişiselleştirilmiş diyet önerileri',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
