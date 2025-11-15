import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/challenge_service.dart';
import '../services/social_challenge_service.dart';
import '../services/premium_service.dart';
import '../services/localization_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_app_bar.dart';
import '../widgets/labubu_avatar.dart';
import '../services/ai_shared_diet_service.dart';
import 'dart:math';

// FORCE_REBUILD_MARKER: If you still see old errors, the build isn't using this source file.
// INVALID_SYNTAX; // Uncomment to verify build is reading this file

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Provide fast access to localization across helpers
  LocalizationService get loc => Provider.of<LocalizationService>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = Provider.of<ChallengeService>(context);
    final premium = Provider.of<PremiumService>(context);
    final socialService = Provider.of<SocialChallengeService>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
    drawer: const AppDrawer(currentRoute: '/challenges'),
  appBar: UnifiedAppBar(title: loc.getString('motivation_challenges'), currentRoute: '/challenges'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _scoreCard(service, isDark),
          const SizedBox(height: 16),
          _badgesRow(service, isDark),
          const SizedBox(height: 24),
          _buildDetailedStatsSection(service, socialService, isDark, loc),
          const SizedBox(height: 24),
          _goalToggles(service, isDark),
          const SizedBox(height: 24),
          _friendCompetitionSection(isDark, loc),
          const SizedBox(height: 24),
          _sharedDietSection(service, premium, isDark, loc),
        ],
      ),
    );
  }

  Widget _scoreCard(ChallengeService service, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Provider.of<LocalizationService>(context, listen: false).getString('weekly_points'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (service.weeklyPoints % 100) / 100.0,
            color: const Color(0xFFE53E3E),
            backgroundColor: Colors.grey.withValues(alpha:0.2),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final loc = Provider.of<LocalizationService>(context, listen: false);
              return Text('${service.weeklyPoints % 100}/100 | ${loc.getString('badges')}: ${service.weeklyBadges}');
            },
          )
        ],
      ),
    );
  }

  Widget _badgesRow(ChallengeService service, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(min(service.weeklyBadges, 8), (i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE53E3E).withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE53E3E).withValues(alpha:0.6)),
        ),
        child: Row(children: [
          const Icon(Icons.emoji_events, color: Color(0xFFE53E3E), size: 16),
          const SizedBox(width: 6),
          Text(Provider.of<LocalizationService>(context, listen: false).getString('badge'))
        ]),
      )),
    );
  }

  // Detailed weekly/monthly stats and friend comparison section
  Widget _buildDetailedStatsSection(ChallengeService service, SocialChallengeService socialService, bool isDark, LocalizationService loc) {
    return FutureBuilder<PreferencesService>(
      future: PreferencesService.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        final currentUserId = prefs?.getCurrentUserId();
        final weeklyStats = _calculateWeeklyStatsInternal(socialService, currentUserId);
        final monthlyStats = _calculateMonthlyStatsInternal(socialService, currentUserId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.getString('weekly_monthly_stats'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statCardInternal('[steps] ${loc.getString('steps_label')}', '${weeklyStats['steps']}', '${loc.getString('goal_label')}: ${weeklyStats['stepsGoal']}', (weeklyStats['steps'] as int) / ((weeklyStats['stepsGoal'] as int) > 0 ? (weeklyStats['stepsGoal'] as int) : 1), isDark)),
                const SizedBox(width: 12),
                Expanded(child: _statCardInternal('[water] ${loc.getString('water_label')}', '${weeklyStats['water']}ml', '${loc.getString('goal_label')}: ${weeklyStats['waterGoal']}ml', (weeklyStats['water'] as int) / ((weeklyStats['waterGoal'] as int) > 0 ? (weeklyStats['waterGoal'] as int) : 1), isDark)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statCardInternal('[sleep] ${loc.getString('sleep_label')}', '${weeklyStats['sleep']}s', '${loc.getString('goal_label')}: ${weeklyStats['sleepGoal']}s', (weeklyStats['sleep'] as int) / ((weeklyStats['sleepGoal'] as int) > 0 ? (weeklyStats['sleepGoal'] as int) : 1), isDark)),
                const SizedBox(width: 12),
                Expanded(child: _statCardInternal('[win] ${loc.getString('points_label')}', '${weeklyStats['points']}', '${loc.getString('weekly_summary', defaultValue: 'This Week')}', 1.0, isDark)),
              ],
            ),
            const SizedBox(height: 24),
            Text(loc.getString('monthly_summary'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _statRowInternal(loc.getString('total_steps'), '${monthlyStats['totalSteps']}', '${monthlyStats['avgSteps']}${loc.getString('per_day')}', isDark),
                  const SizedBox(height: 12),
                  _statRowInternal(loc.getString('total_water'), '${monthlyStats['totalWater']}ml', '${monthlyStats['avgWater']}ml${loc.getString('per_day')}', isDark),
                  const SizedBox(height: 12),
                  _statRowInternal(loc.getString('total_sleep'), '${monthlyStats['totalSleep']}s', '${monthlyStats['avgSleep']}s${loc.getString('per_day')}', isDark),
                  const SizedBox(height: 12),
                  _statRowInternal(loc.getString('total_points'), '${monthlyStats['totalPoints']}', '${monthlyStats['badges']} ${loc.getString('badges')}', isDark),
                ],
              ),
            ),
            if (socialService.activeFriends.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(loc.getString('friends_comparison'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...socialService.activeFriends.map((friend) {
                final friendStats = _getFriendWeeklyStatsInternal(socialService, friend.friendUserId);
                return _friendComparisonMiniCardInternal(friend, weeklyStats, friendStats, socialService, isDark);
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _statCardInternal(String label, String value, String subtitle, double progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.black54)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey : Colors.black54)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.grey.withValues(alpha:0.2), color: const Color(0xFFE53E3E)),
        ],
      ),
    );
  }

  Widget _statRowInternal(String label, String value, String subtitle, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE53E3E))),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _friendComparisonMiniCardInternal(FriendConnection friend, Map<String, dynamic> myStats, Map<String, dynamic> friendStats, SocialChallengeService service, bool isDark) {
    final avatarIndex = service.generateAvatarVariantIndex(seed: friend.friendName);
    final stepsDiff = (myStats['steps'] as int) - (friendStats['steps'] as int);
    final waterDiff = (myStats['water'] as int) - (friendStats['water'] as int);
    final sleepDiff = (myStats['sleep'] as int) - (friendStats['sleep'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          LabubuAvatar(seed: friend.friendName, size: 36, variantIndex: avatarIndex),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.friendName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  _miniComparisonInternal('[steps]', stepsDiff),
                  const SizedBox(width: 8),
                  _miniComparisonInternal('[water]', waterDiff),
                  const SizedBox(width: 8),
                  _miniComparisonInternal('[sleep]', sleepDiff),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniComparisonInternal(String emoji, int diff) {
    final isPositive = diff > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.withValues(alpha:0.1) : Colors.orange.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text('${diff > 0 ? '+' : ''}$diff', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateWeeklyStatsInternal(SocialChallengeService service, int? userId) {
    if (userId == null) return {'steps': 0, 'water': 0, 'sleep': 0, 'points': 0, 'stepsGoal': 70000, 'waterGoal': 14000, 'sleepGoal': 49000};
    final now = DateTime.now();
    int totalSteps = 0, totalWater = 0, totalSleep = 0, totalPoints = 0;
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final activity = service.activityData['${userId}_${date.year}_${date.month}_${date.day}'];
      if (activity != null) {
        totalSteps += activity.steps;
        totalWater += activity.water;
        totalSleep += activity.sleep;
        totalPoints += activity.points;
      }
    }
    return {'steps': totalSteps, 'water': totalWater, 'sleep': totalSleep, 'points': totalPoints, 'stepsGoal': 70000, 'waterGoal': 14000, 'sleepGoal': 49000};
  }

  Map<String, dynamic> _calculateMonthlyStatsInternal(SocialChallengeService service, int? userId) {
    if (userId == null) return {'totalSteps': 0, 'totalWater': 0, 'totalSleep': 0, 'totalPoints': 0, 'avgSteps': 0, 'avgWater': 0, 'avgSleep': 0, 'badges': 0};
    final now = DateTime.now();
    int totalSteps = 0, totalWater = 0, totalSleep = 0, totalPoints = 0, days = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final activity = service.activityData['${userId}_${date.year}_${date.month}_${date.day}'];
      if (activity != null) {
        totalSteps += activity.steps;
        totalWater += activity.water;
        totalSleep += activity.sleep;
        totalPoints += activity.points;
        days++;
      }
    }
    return {
      'totalSteps': totalSteps,
      'totalWater': totalWater,
      'totalSleep': totalSleep,
      'totalPoints': totalPoints,
      'avgSteps': days > 0 ? (totalSteps / days).round() : 0,
      'avgWater': days > 0 ? (totalWater / days).round() : 0,
      'avgSleep': days > 0 ? (totalSleep / days).round() : 0,
      'badges': (totalPoints / 100).floor(),
    };
  }

  Map<String, dynamic> _getFriendWeeklyStatsInternal(SocialChallengeService service, int friendUserId) {
    final now = DateTime.now();
    int totalSteps = 0, totalWater = 0, totalSleep = 0;
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final activity = service.activityData['${friendUserId}_${date.year}_${date.month}_${date.day}'];
      if (activity != null) {
        totalSteps += activity.steps;
        totalWater += activity.water;
        totalSleep += activity.sleep;
      }
    }
    return {'steps': totalSteps, 'water': totalWater, 'sleep': totalSleep};
  }

  Widget _goalToggles(ChallengeService service, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
  Text(Provider.of<LocalizationService>(context, listen: false).getString('weekly_goals'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
  _toggle(Provider.of<LocalizationService>(context, listen: false).getString('steps_label'), service.weeklySteps, (v) => service.toggleWeeklyStep(v), isDark),
  _toggle(Provider.of<LocalizationService>(context, listen: false).getString('water_label'), service.weeklyWater, (v) => service.toggleWeeklyWater(v), isDark),
  _toggle(Provider.of<LocalizationService>(context, listen: false).getString('sleep_label'), service.weeklySleep, (v) => service.toggleWeeklySleep(v), isDark),
      ],
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _sharedDietSection(ChallengeService service, PremiumService premium, bool isDark, LocalizationService loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
  Text(loc.getString('ai_shared_diet_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (!premium.isPremium)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.getString('ai_shared_diet_premium_title')),
                      const SizedBox(height: 4),
                      Text(
                        loc.getString('ai_shared_diet_premium_subtitle'),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/premium'),
                  child: Text(loc.getString('upgrade')),
                ),
              ],
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE53E3E).withValues(alpha:0.1), const Color(0xFFE53E3E).withValues(alpha:0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE53E3E).withValues(alpha:0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53E3E).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology, color: Color(0xFFE53E3E), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.getString('ai_shared_diet_title'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            loc.getString('two_week_personalized_plan'),
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _createSharedDietFlow(service, loc),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(loc.getString('create_new_plan_with_ai')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...service.sharedDiets.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${d.name} | ${d.month} | ${loc.getString('points_label')}: ${d.points}')),
                    IconButton(
                      icon: const Icon(Icons.add_task),
                      onPressed: () => service.addDietPoints(d.id, 5),
                      tooltip: loc.getString('today_plan_applied_plus_5'),
                    )
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Future<void> _createSharedDietFlow(ChallengeService service, LocalizationService loc) async {
    try {
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      if (userId == null) {
        if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.getString('login_required'))));
        return;
      }

  // Get family members
      final family = await _db.getFamilyMembers(userId);
      if (!mounted) return;
      if (family.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.getString('no_family_members'))));
        return;
      }

  // Select partner
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.getString('select_partner'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: family.length,
              itemBuilder: (context, index) {
                final member = family[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(member['name'] ?? loc.getStringWithParams('member_label', {'id': member['id'] ?? ''})),
                  subtitle: Text('${loc.getString('age')}: ${member['age'] ?? 'N/A'}'),
                  onTap: () => Navigator.pop(ctx, member),
                );
              },
            ),
          ),
        ),
      );
      if (selected == null) return;

  // Get plan name
  final name = await _promptText(loc.getString('plan_name'));
      if (name == null || name.trim().isEmpty) return;

  // Create a 2-week diet with AI
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final aiService = AISharedDietService();
        final partnerId = selected['connected_user_id'] as int? ?? selected['id'] as int;
        
  // Create AI diet plan
        final dietWeeks = await aiService.generateSharedDietPlan(
          userId1: userId,
          userId2: partnerId,
          planName: name.trim(),
        );

        if (!mounted) return;
  Navigator.pop(context); // Close loading dialog

  // Save the plan
        final now = DateTime.now();
        final month = now.year * 100 + now.month;
        final id = '${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  // Save plan details as meta
        final meta = <String, dynamic>{
          'weeks': dietWeeks.map((week) => <String, dynamic>{
            'weekNumber': week.weekNumber,
            'dailyPlans': week.dailyPlans.entries.map((entry) => <String, dynamic>{
              'day': entry.key,
              'breakfast': entry.value.breakfast,
              'lunch': entry.value.lunch,
              'dinner': entry.value.dinner,
              'snack': entry.value.snack,
              'nutrition': entry.value.nutrition,
              'focusAreas': entry.value.focusAreas,
            }).toList(),
          }).toList(),
          'createdAt': now.toIso8601String(),
          'partnerId': partnerId,
          'partnerName': selected['name'],
        };

        await service.createSharedDiet(
          id: id,
          name: name.trim(),
          month: month,
          userIds: [userId, partnerId],
          meta: meta,
        );

        if (!mounted) return;
        
  // Show success message and plan details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('shared_diet_created')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

  // Show plan details
        if (!mounted) return;
  _showDietPlanDetails(dietWeeks, name.trim(), selected['name'] ?? loc.getString('partner_default'));
      } catch (e) {
        if (!mounted) return;
  Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getStringWithParams('ai_diet_error', {'error': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.getStringWithParams('error_with_details', {'error': '$e'}))));
    }
  }

  void _showDietPlanDetails(List<SharedDietWeek> weeks, String planName, String partnerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$planName - ${Provider.of<LocalizationService>(context, listen: false).getString('two_week_plan')}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${Provider.of<LocalizationService>(context, listen: false).getString('partner_label')}: $partnerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...weeks.map((week) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Provider.of<LocalizationService>(context, listen: false).getString('week_label')} ${week.weekNumber}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...week.dailyPlans.entries.map((entry) {
                      final loc = Provider.of<LocalizationService>(context, listen: false);
                      final dayNames = [
                        loc.getString('monday'),
                        loc.getString('tuesday'),
                        loc.getString('wednesday'),
                        loc.getString('thursday'),
                        loc.getString('friday'),
                        loc.getString('saturday'),
                        loc.getString('sunday'),
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayNames[entry.key],
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text('${loc.getString('meal_breakfast')}: ${entry.value.breakfast}'),
                            Text('${loc.getString('meal_lunch')}: ${entry.value.lunch}'),
                            Text('${loc.getString('meal_dinner')}: ${entry.value.dinner}'),
                            Text('${loc.getString('meal_snack')}: ${entry.value.snack}')
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Provider.of<LocalizationService>(context, listen: false).getString('close')),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptText(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Provider.of<LocalizationService>(context, listen: false).getString('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(Provider.of<LocalizationService>(context, listen: false).getString('save'))),
        ],
      ),
    );
  }

  Widget _friendCompetitionSection(bool isDark, LocalizationService loc) {
    final socialService = Provider.of<SocialChallengeService>(context);
    
    return FutureBuilder<PreferencesService>(
      future: PreferencesService.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        final currentUserId = prefs?.getCurrentUserId();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  loc.getString('friend_competition_title'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addFriendFlow(socialService, currentUserId),
                  tooltip: loc.getString('add_friend'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (socialService.activeFriends.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      loc.getString('no_friends_yet'),
                      style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _addFriendFlow(socialService, currentUserId),
                      icon: const Icon(Icons.person_add),
                      label: Text(loc.getString('add_friend')),
                    ),
                  ],
                ),
              )
            else
              ...socialService.activeFriends.map((friend) => _buildFriendCompetitionCard(
                    friend,
                    socialService,
                    currentUserId,
                    isDark,
                    loc,
                  )),
            if (socialService.pendingFriends.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                loc.getString('pending_requests'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...socialService.pendingFriends.map((friend) => _buildPendingFriendCard(friend, socialService, isDark)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFriendCompetitionCard(
    FriendConnection friend,
    SocialChallengeService service,
    int? currentUserId,
    bool isDark,
    LocalizationService loc,
  ) {
    if (currentUserId == null) return const SizedBox.shrink();

    FriendCompetition? competition;
    try {
      competition = service.getTodayCompetition(currentUserId, friend.friendUserId);
    } catch (_) {
      // No competition yet
    }

    final avatarIndex = friend.friendAvatar != null 
        ? int.tryParse(friend.friendAvatar!) ?? service.generateAvatarVariantIndex(seed: friend.friendName)
        : service.generateAvatarVariantIndex(seed: friend.friendName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: competition != null && competition.iAmWinning
              ? Colors.green
              : (isDark ? const Color(0xFF30363D) : Colors.grey.shade200),
          width: competition != null && competition.iAmWinning ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LabubuAvatar(
                seed: friend.friendName,
                size: 48,
                variantIndex: avatarIndex,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.friendName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (competition != null)
                      Text(
            competition.iAmWinning
              ? '[win] ' + loc.getString('you_are_winning')
              : '[:] ' + loc.getString('opponent_leading'),
                        style: TextStyle(
                          fontSize: 12,
                          color: competition.iAmWinning ? Colors.green : Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
              if (competition != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
          color: competition.iAmWinning
            ? Colors.green.withValues(alpha:0.1)
            : Colors.orange.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${competition.pointsDifference > 0 ? '+' : ''}${competition.pointsDifference}',
                    style: TextStyle(
                      color: competition.iAmWinning ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (competition != null) ...[
            const SizedBox(height: 16),
            _buildComparisonRow('[steps] ' + loc.getString('steps_label'), competition.mySteps, competition.friendSteps, isDark),
            const SizedBox(height: 8),
            _buildComparisonRow('[water] ' + loc.getString('water_label') + ' (ml)', competition.myWater, competition.friendWater, isDark),
            const SizedBox(height: 8),
            _buildComparisonRow('[sleep] ' + loc.getString('sleep_label') + ' (min)', competition.mySleep, competition.friendSleep, isDark),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                loc.getString('no_data_shared_today'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _viewFriendDetails(friend, service, currentUserId),
                icon: const Icon(Icons.visibility, size: 16),
                label: Text(loc.getString('details')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, int myValue, int friendValue, bool isDark) {
    final iAmWinning = myValue > friendValue;
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 14))),
        Expanded(
          child: Text(
            myValue.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: iAmWinning ? Colors.green : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        Expanded(
          child: Text(
            friendValue.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: !iAmWinning ? Colors.orange : (isDark ? Colors.grey : Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingFriendCard(FriendConnection friend, SocialChallengeService service, bool isDark) {
    final avatarIndex = friend.friendAvatar != null 
        ? int.tryParse(friend.friendAvatar!) ?? service.generateAvatarVariantIndex(seed: friend.friendName)
        : service.generateAvatarVariantIndex(seed: friend.friendName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha:0.5)),
      ),
      child: Row(
        children: [
          LabubuAvatar(
            seed: friend.friendName,
            size: 40,
            variantIndex: avatarIndex,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.friendName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  friend.isApprovedByMe
                      ? Provider.of<LocalizationService>(context, listen: false).getString('waiting_for_approval')
                      : Provider.of<LocalizationService>(context, listen: false).getString('request_approved'),
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.black54),
                ),
              ],
            ),
          ),
          if (!friend.isApprovedByMe)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => service.approveFriendRequest(friend.id),
              tooltip: Provider.of<LocalizationService>(context, listen: false).getString('confirm'),
            ),
        ],
      ),
    );
  }

  Future<void> _addFriendFlow(SocialChallengeService service, int? currentUserId) async {
    if (currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getString('login_required'))),
      );
      return;
    }

    try {
      final db = DatabaseHelper.instance;
      final family = await db.getFamilyMembers(currentUserId);

      if (!mounted) return;
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(Provider.of<LocalizationService>(context, listen: false).getString('select_friend')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: family.length,
              itemBuilder: (ctx, i) {
                final member = family[i];
                return ListTile(
                  leading: LabubuAvatar(
                    seed: member['name']?.toString() ?? '',
                    size: 40,
                  ),
                  title: Text(member['name']?.toString() ?? Provider.of<LocalizationService>(context, listen: false).getStringWithParams('member_label', {'id': member['id'].toString()})),
                  onTap: () => Navigator.pop(ctx, member),
                );
              },
            ),
          ),
        ),
      );

      if (selected == null) return;

      if (!mounted) return;
      final friendId = selected['id'] as int?;
      final friendName = selected['name']?.toString() ?? Provider.of<LocalizationService>(context, listen: false).getString('friend_default');
      
      if (friendId == null) return;

      final avatarIndex = service.generateAvatarVariantIndex(seed: friendName);
      await service.sendFriendRequest(
        friendUserId: friendId,
        friendName: friendName,
        friendAvatar: avatarIndex.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getStringWithParams('request_sent_to', {'name': friendName}))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getStringWithParams('error_with_details', {'error': '$e'}))),
      );
    }
  }

  void _viewFriendDetails(FriendConnection friend, SocialChallengeService service, int? currentUserId) {
    if (currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => _FriendDetailsSheet(
        friend: friend,
        service: service,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _FriendDetailsSheet extends StatelessWidget {
  final FriendConnection friend;
  final SocialChallengeService service;
  final int currentUserId;

  const _FriendDetailsSheet({
    required this.friend,
    required this.service,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final activities = service.getFriendActivity(friend.friendUserId, days: 7);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LabubuAvatar(
                seed: friend.friendName,
                size: 60,
                variantIndex: friend.friendAvatar != null 
                    ? int.tryParse(friend.friendAvatar!) 
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.friendName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(Provider.of<LocalizationService>(context, listen: false).getString('seven_day_activity'), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(Provider.of<LocalizationService>(context, listen: false).getString('no_activity_data_yet')),
            )
          else
            ...activities.map((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(activity.date.day.toString())),
                      Expanded(child: Text('[steps] ${activity.steps}')),
                      Expanded(child: Text('[water] ${activity.water}ml')),
                      Expanded(child: Text('[sleep] ${activity.sleep}m')),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

}


