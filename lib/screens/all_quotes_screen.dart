import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/daily_advice_service.dart';

class AllQuotesScreen extends StatelessWidget {
  const AllQuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final quotes = DailyAdviceService().getAllQuotes(loc);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('all_quotes_title')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: quotes.isEmpty
          ? Center(
              child: Text(loc.getString('no_quotes_available')),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final q = quotes[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('â€œ', style: TextStyle(fontSize: 24, color: Color(0xFFE53E3E))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

