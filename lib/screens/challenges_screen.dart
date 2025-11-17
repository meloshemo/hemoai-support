import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/challenge_service.dart';
import '../services/social_challenge_service.dart';
import '../services/premium_service.dart';
import '../services/localization_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../services/group_challenge_service.dart';
import '../services/activity_service.dart';
import '../services/streak_service.dart';
import '../widgets/app_drawer.dart';
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

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late TabController _tabController;
  late GroupChallengeService _groupChallengeService;

  // Provide fast access to localization across helpers
  LocalizationService get loc => Provider.of<LocalizationService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _groupChallengeService = GroupChallengeService();
    _groupChallengeService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = Provider.of<ChallengeService>(context);
    final premium = Provider.of<PremiumService>(context);
    final socialService = Provider.of<SocialChallengeService>(context);
    final cs = Theme.of(context).colorScheme;
    final hemoaiPrimary = const Color(0xFFE53E3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      drawer: const AppDrawer(currentRoute: '/challenges'),
      appBar: AppBar(
        title: Text(loc.getString('motivation_challenges')),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: hemoaiPrimary,
          labelColor: hemoaiPrimary,
          unselectedLabelColor: isDark ? Colors.grey : Colors.black54,
          tabs: [
            Tab(icon: const Icon(Icons.local_fire_department), text: loc.getString('my_challenges')),
            Tab(icon: const Icon(Icons.groups), text: loc.getString('group_challenges')),
            Tab(icon: const Icon(Icons.emoji_events), text: loc.getString('leaderboard')),
            Tab(icon: const Icon(Icons.analytics), text: loc.getString('my_stats')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyChallengesTab(service, socialService, premium, isDark, loc, cs, hemoaiPrimary),
          _buildGroupChallengesTab(isDark, loc, cs, hemoaiPrimary),
          _buildLeaderboardTab(socialService, isDark, loc, cs, hemoaiPrimary),
          _buildMyStatsTab(service, socialService, isDark, loc, cs, hemoaiPrimary),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 1) {
            // Check premium for creating group challenges
            if (!premium.isPremium) {
              return FloatingActionButton.extended(
                onPressed: () {
                  _showPremiumUpgradeDialog(context, isDark, loc, cs, hemoaiPrimary);
                },
                icon: const Icon(Icons.lock),
                label: Text(loc.getString('create_group_challenge')),
                backgroundColor: hemoaiPrimary,
              );
            }
            return FloatingActionButton.extended(
              onPressed: () => _createGroupChallenge(context, isDark, loc, cs, hemoaiPrimary),
              icon: const Icon(Icons.add),
              label: Text(loc.getString('create_group_challenge')),
              backgroundColor: hemoaiPrimary,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }


  // Detailed weekly/monthly stats and friend comparison section
  Widget _buildDetailedStatsSection(ChallengeService service, SocialChallengeService socialService, bool isDark, LocalizationService loc) {
    return FutureBuilder<PreferencesService>(
      future: PreferencesService.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        final currentUserId = prefs?.getCurrentUserId();
        if (currentUserId == null) {
          return const SizedBox.shrink();
        }
        // Compute stats once for cards
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
                Expanded(child: _statCardInternal('[water] ${loc.getString('water_label')}', '${weeklyStats['water']} ${loc.getString('ml_unit')}', '${loc.getString('goal_label')}: ${weeklyStats['waterGoal']} ${loc.getString('ml_unit')}', (weeklyStats['water'] as int) / ((weeklyStats['waterGoal'] as int) > 0 ? (weeklyStats['waterGoal'] as int) : 1), isDark)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statCardInternal('[sleep] ${loc.getString('sleep_label')}', '${weeklyStats['sleep']}${loc.getString('sec_unit', defaultValue: 's')}', '${loc.getString('goal_label')}: ${weeklyStats['sleepGoal']}${loc.getString('sec_unit', defaultValue: 's')}', (weeklyStats['sleep'] as int) / ((weeklyStats['sleepGoal'] as int) > 0 ? (weeklyStats['sleepGoal'] as int) : 1), isDark)),
                const SizedBox(width: 12),
                Expanded(child: _statCardInternal('[win] ${loc.getString('points_label')}', '${weeklyStats['points']}', loc.getString('weekly_summary', defaultValue: 'This Week'), 1.0, isDark)),
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
                  _statRowInternal(loc.getString('total_water'), '${monthlyStats['totalWater']} ${loc.getString('ml_unit')}', '${monthlyStats['avgWater']} ${loc.getString('ml_unit')}${loc.getString('per_day')}', isDark),
                  const SizedBox(height: 12),
                  _statRowInternal(loc.getString('total_sleep'), '${monthlyStats['totalSleep']}${loc.getString('sec_unit', defaultValue: 's')}', '${monthlyStats['avgSleep']}${loc.getString('sec_unit', defaultValue: 's')}${loc.getString('per_day')}', isDark),
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
                Text(
                  friend.friendName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                  subtitle: Text('${loc.getString('age')}: ${member['age'] ?? loc.getString('not_available')}'),
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
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: Provider.of<LocalizationService>(context, listen: false).getString('enter_value')),
        ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (competition != null)
                      Text(
            competition.iAmWinning
              ? '[win] ${loc.getString('you_are_winning')}'
              : '[:] ${loc.getString('opponent_leading')}',
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
            _buildComparisonRow('[steps] ${loc.getString('steps_label')}', competition.mySteps, competition.friendSteps, isDark),
            const SizedBox(height: 8),
            _buildComparisonRow('[water] ${loc.getString('water_ml')}', competition.myWater, competition.friendWater, isDark),
            const SizedBox(height: 8),
            _buildComparisonRow('[sleep] ${loc.getString('sleep_minutes')}', competition.mySleep, competition.friendSleep, isDark),
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
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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

  // Tab builders and helpers (relocated from _FriendDetailsSheet)
  Widget _buildMyChallengesTab(ChallengeService service, SocialChallengeService socialService, PremiumService premium, bool isDark, LocalizationService loc, ColorScheme cs, Color hemoaiPrimary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModernScoreCard(service, isDark, cs, hemoaiPrimary),
        const SizedBox(height: 16),
        _buildStreakCard(service, isDark, cs, hemoaiPrimary),
        const SizedBox(height: 24),
        _buildDetailedStatsSection(service, socialService, isDark, loc),
        const SizedBox(height: 24),
        _goalToggles(service, isDark),
        const SizedBox(height: 24),
        _friendCompetitionSection(isDark, loc),
        const SizedBox(height: 24),
        _sharedDietSection(service, premium, isDark, loc),
      ],
    );
  }

  Widget _buildGroupChallengesTab(bool isDark, LocalizationService loc, ColorScheme cs, Color hemoaiPrimary) {
    final premium = Provider.of<PremiumService>(context, listen: false);
    return FutureBuilder<PreferencesService>(
      future: PreferencesService.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        final currentUserId = prefs?.getCurrentUserId();
        if (currentUserId == null) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(loc.getString('login_required'))));
        }
        final myChallenges = _groupChallengeService.getChallengesForUser(currentUserId);
        final activeChallenges = myChallenges.where((c) => c.isActive && DateTime.now().isBefore(c.endDate)).toList();
        final completedChallenges = myChallenges.where((c) => !c.isActive || DateTime.now().isAfter(c.endDate)).toList();
        
        // Check premium limit for free users
        final canCreateMore = premium.isPremium || activeChallenges.length < 1;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!premium.isPremium && activeChallenges.length >= 1)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [hemoaiPrimary.withValues(alpha: 0.15), hemoaiPrimary.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: hemoaiPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: hemoaiPrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.getString('premium_limit_reached', defaultValue: 'Free limit reached'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.getString('free_users_one_active_challenge', defaultValue: 'Free users can have 1 active group challenge. Upgrade to Premium for unlimited challenges!'),
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, '/premium'),
                      style: FilledButton.styleFrom(
                        backgroundColor: hemoaiPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(loc.getString('upgrade', defaultValue: 'Upgrade')),
                    ),
                  ],
                ),
              ),
            if (activeChallenges.isNotEmpty) ...activeChallenges.map((c) => _buildGroupChallengeCard(c, isDark, loc, cs, hemoaiPrimary, currentUserId)),
            if (completedChallenges.isNotEmpty) ...completedChallenges.map((c) => _buildGroupChallengeCard(c, isDark, loc, cs, hemoaiPrimary, currentUserId)),
            if (activeChallenges.isEmpty && completedChallenges.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(48), child: Text(loc.getString('no_group_challenges')))),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardTab(SocialChallengeService socialService, bool isDark, LocalizationService loc, ColorScheme cs, Color hemoaiPrimary) {
    return FutureBuilder<PreferencesService>(
      future: PreferencesService.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        final currentUserId = prefs?.getCurrentUserId();
        if (currentUserId == null) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(loc.getString('login_required'))));
        }
        final friends = socialService.activeFriends;
        final weeklyStats = _calculateWeeklyStatsInternal(socialService, currentUserId);
        final leaderboard = <Map<String, dynamic>>[
          {
            'userId': currentUserId,
            'name': (prefs?.getUserInfo()?['name'] as String?) ?? loc.getString('you'),
            'score': weeklyStats['points'] ?? 0,
            'isMe': true,
          },
          ...friends.map((f) {
            final friendStats = _getFriendWeeklyStatsInternal(socialService, f.friendUserId);
            return {
              'userId': f.friendUserId,
              'name': f.friendName,
              'score': friendStats['points'] ?? 0,
              'isMe': false,
            };
          }),
        ]..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...leaderboard.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return _buildLeaderboardItem(
                rank: index + 1,
                name: user['name'] as String,
                score: user['score'] as int,
                isMe: user['isMe'] as bool,
                isDark: isDark,
                loc: loc,
                cs: cs,
                hemoaiPrimary: hemoaiPrimary,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMyStatsTab(ChallengeService service, SocialChallengeService socialService, bool isDark, LocalizationService loc, ColorScheme cs, Color hemoaiPrimary) {
    return FutureBuilder<PreferencesService>(
      future: PreferencesService.getInstance(),
      builder: (context, snapshot) {
        // Stats can be calculated here if needed for future UI
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildModernScoreCard(service, isDark, cs, hemoaiPrimary),
            const SizedBox(height: 16),
            _buildStreakCard(service, isDark, cs, hemoaiPrimary),
            const SizedBox(height: 24),
            _buildDetailedStatsSection(service, socialService, isDark, loc),
          ],
        );
      },
    );
  }

  Widget _buildModernScoreCard(ChallengeService service, bool isDark, ColorScheme cs, Color hemoaiPrimary) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final activityService = Provider.of<ActivityService>(context, listen: true);
    return FutureBuilder<Map<String, dynamic>>(
      future: activityService.getWeeklyStats(),
      builder: (context, snapshot) {
        final weeklyPoints = snapshot.data?['points'] as int? ?? 0;
        final badges = (weeklyPoints / 100).floor();
        final progress = (weeklyPoints % 100) / 100.0;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [hemoaiPrimary.withValues(alpha: 0.15), hemoaiPrimary.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: hemoaiPrimary.withValues(alpha: 0.3), width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.getString('weekly_points'), style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(weeklyPoints.toString(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: cs.onSurface)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(hemoaiPrimary),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text('${weeklyPoints % 100}/100 ${loc.getString('to_next_badge')}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: hemoaiPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: hemoaiPrimary, size: 20),
                    const SizedBox(width: 6),
                    Text(badges.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: hemoaiPrimary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCard(ChallengeService service, bool isDark, ColorScheme cs, Color hemoaiPrimary) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final streakService = Provider.of<StreakService>(context, listen: true);
    final currentStreak = streakService.currentStreak;
    final reward = streakService.getStreakReward();
    final nextMilestone = streakService.getNextMilestone();
    final progress = streakService.getProgressToNextMilestone();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: hemoaiPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.whatshot, color: hemoaiPrimary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.getString('current_streak'), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('$currentStreak ${loc.getString('days')} $reward', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  ],
                ),
              ),
            ],
          ),
          if (nextMilestone != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(hemoaiPrimary),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text('${loc.getString('to_next_badge')}: ${nextMilestone.emoji} ${nextMilestone.title} (${nextMilestone.days} ${loc.getString('days')})', 
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupChallengeCard(GroupChallenge challenge, bool isDark, LocalizationService loc, ColorScheme cs, Color hemoaiPrimary, int currentUserId) {
    final leaderboard = challenge.getLeaderboard();
    final myScore = challenge.participantScores[currentUserId] ?? 0;
    final progress = (myScore / challenge.targetValue * 100).clamp(0.0, 100.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: hemoaiPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          challenge.name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress / 100, backgroundColor: cs.surfaceContainerHighest, valueColor: AlwaysStoppedAnimation<Color>(hemoaiPrimary)),
        const SizedBox(height: 4),
        Text('${progress.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        if (leaderboard.isNotEmpty) ...leaderboard.take(3).map((e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${e['name']}: ${e['score']}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            )),
      ]),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required int score,
    required bool isMe,
    required bool isDark,
    required LocalizationService loc,
    required ColorScheme cs,
    required Color hemoaiPrimary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? hemoaiPrimary.withValues(alpha: 0.1) : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? hemoaiPrimary.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: isMe ? 2 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: hemoaiPrimary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank, hemoaiPrimary).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank',
                style: TextStyle(
                  fontSize: rank <= 3 ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  color: _getRankColor(rank, hemoaiPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isMe)
                  Text(
                    loc.getString('you'),
                    style: TextStyle(
                      fontSize: 12,
                      color: hemoaiPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: hemoaiPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: hemoaiPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank, Color hemoaiPrimary) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return hemoaiPrimary;
    }
  }

  Future<void> _createGroupChallenge(BuildContext context, bool isDark, LocalizationService loc, ColorScheme cs, Color hemoaiPrimary) async {
    if (!mounted) return;

    // Capture dependencies before awaits to satisfy lint.
    final messenger = ScaffoldMessenger.of(context);
    final premium = Provider.of<PremiumService>(context, listen: false);
    final socialService = Provider.of<SocialChallengeService>(context, listen: false);
    final activeFriends = socialService.activeFriends;

    final prefs = await PreferencesService.getInstance();
    if (!mounted) return;
    final currentUserId = prefs.getCurrentUserId();
    if (currentUserId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.getString('login_required'))),
      );
      return;
    }

    // Check premium limit for free users
    if (!premium.isPremium) {
      final myChallenges = _groupChallengeService.getChallengesForUser(currentUserId);
      final activeChallenges = myChallenges.where((c) => c.isActive && DateTime.now().isBefore(c.endDate)).toList();
      if (activeChallenges.length >= 1) {
        _showPremiumUpgradeDialog(context, isDark, loc, cs, hemoaiPrimary);
        return;
      }
    }

    // Safe: context usage immediately after mounted check and before user interaction.
    // ignore: use_build_context_synchronously
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      // ignore: use_build_context_synchronously
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateGroupChallengeDialog(
        currentUserId: currentUserId,
        activeFriends: activeFriends,
        isDark: isDark,
        loc: loc,
        cs: cs,
        hemoaiPrimary: hemoaiPrimary,
      ),
    );
    if (!mounted) return;

    if (result != null) {
      try {
        final participants = result['participants'] as List<int>;
        final participantNames = <int, String>{
          currentUserId: (prefs.getUserInfo()?['name'] as String?) ?? loc.getString('you'),
        };

        for (final friend in activeFriends) {
          if (participants.contains(friend.friendUserId)) {
            participantNames[friend.friendUserId] = friend.friendName;
          }
        }

        await _groupChallengeService.createChallenge(
          name: result['name'] as String,
          description: result['description'] as String,
          type: result['type'] as ChallengeType,
          duration: result['duration'] as ChallengeDuration,
          targetValue: result['targetValue'] as int,
          participantIds: participants,
          participantNames: participantNames,
          createdBy: (prefs.getUserInfo()?['name'] as String?) ?? loc.getString('user'),
        );
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(loc.getString('group_challenge_created', defaultValue: 'Group challenge created!')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('${loc.getString('error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPremiumUpgradeDialog(BuildContext context, bool isDark, LocalizationService loc, ColorScheme cs, Color hemoaiPrimary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.getString('premium_feature', defaultValue: 'Premium Feature'),
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.getString('premium_required_group_challenges', defaultValue: 'Creating group challenges is a Premium feature. Upgrade to Premium to create unlimited group challenges and compete with your friends!'),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hemoaiPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hemoaiPrimary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: hemoaiPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.getString('premium_benefit_unlimited_challenges', defaultValue: 'Unlimited group challenges'),
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: hemoaiPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.getString('premium_benefit_advanced_types', defaultValue: 'Advanced challenge types'),
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: hemoaiPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.getString('premium_benefit_detailed_stats', defaultValue: 'Detailed leaderboards & stats'),
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('cancel', defaultValue: 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/premium');
            },
            style: FilledButton.styleFrom(backgroundColor: hemoaiPrimary),
            child: Text(loc.getString('upgrade_to_premium', defaultValue: 'Upgrade to Premium')),
          ),
        ],
      ),
    );
  }

}

class _CreateGroupChallengeDialog extends StatefulWidget {
  final int currentUserId;
  final List<FriendConnection> activeFriends;
  final bool isDark;
  final LocalizationService loc;
  final ColorScheme cs;
  final Color hemoaiPrimary;

  const _CreateGroupChallengeDialog({
    required this.currentUserId,
    required this.activeFriends,
    required this.isDark,
    required this.loc,
    required this.cs,
    required this.hemoaiPrimary,
  });

  @override
  State<_CreateGroupChallengeDialog> createState() => _CreateGroupChallengeDialogState();
}

class _CreateGroupChallengeDialogState extends State<_CreateGroupChallengeDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  
  ChallengeType _selectedType = ChallengeType.steps;
  ChallengeDuration _selectedDuration = ChallengeDuration.weekly;
  final Set<int> _selectedParticipants = {};

  @override
  void initState() {
    super.initState();
    _selectedParticipants.add(widget.currentUserId); // Include self by default
    _targetController.text = '10000'; // Default target
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  String _getTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.steps:
        return widget.loc.getString('steps_label', defaultValue: 'Steps');
      case ChallengeType.water:
        return widget.loc.getString('water_label', defaultValue: 'Water');
      case ChallengeType.sleep:
        return widget.loc.getString('sleep_label', defaultValue: 'Sleep');
      case ChallengeType.diet:
        return widget.loc.getString('diet_label', defaultValue: 'Diet');
      case ChallengeType.combined:
        return widget.loc.getString('combined', defaultValue: 'Combined');
      case ChallengeType.hemogram:
        return widget.loc.getString('hemogram', defaultValue: 'Hemogram');
    }
  }

  IconData _getTypeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.steps:
        return Icons.directions_walk;
      case ChallengeType.water:
        return Icons.water_drop;
      case ChallengeType.sleep:
        return Icons.bedtime;
      case ChallengeType.diet:
        return Icons.restaurant;
      case ChallengeType.combined:
        return Icons.all_inclusive;
      case ChallengeType.hemogram:
        return Icons.bloodtype;
    }
  }

  String _getDurationLabel(ChallengeDuration duration) {
    switch (duration) {
      case ChallengeDuration.daily:
        return widget.loc.getString('daily', defaultValue: 'Daily');
      case ChallengeDuration.weekly:
        return widget.loc.getString('weekly', defaultValue: 'Weekly');
      case ChallengeDuration.monthly:
        return widget.loc.getString('monthly', defaultValue: 'Monthly');
    }
  }

  String _getTargetHint() {
    switch (_selectedType) {
      case ChallengeType.steps:
        return widget.loc.getString('target_steps', defaultValue: 'Target steps (e.g., 10000)');
      case ChallengeType.water:
        return widget.loc.getString('target_water', defaultValue: 'Target glasses (e.g., 8)');
      case ChallengeType.sleep:
        return widget.loc.getString('target_sleep', defaultValue: 'Target minutes (e.g., 480)');
      case ChallengeType.diet:
        return widget.loc.getString('target_meals', defaultValue: 'Target meals completed');
      case ChallengeType.combined:
        return widget.loc.getString('target_points', defaultValue: 'Target points');
      case ChallengeType.hemogram:
        return widget.loc.getString('target_tests', defaultValue: 'Target tests');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: widget.hemoaiPrimary, size: 28),
                const SizedBox(width: 12),
                Text(
                  widget.loc.getString('create_group_challenge', defaultValue: 'Create Group Challenge'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: widget.cs.onSurface),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: widget.cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge Name
                  Text(
                    widget.loc.getString('challenge_name', defaultValue: 'Challenge Name'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: widget.loc.getString('enter_challenge_name', defaultValue: 'Enter challenge name'),
                      filled: true,
                      fillColor: widget.isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.hemoaiPrimary, width: 2),
                      ),
                    ),
                    style: TextStyle(color: widget.cs.onSurface),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    widget.loc.getString('description', defaultValue: 'Description'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: widget.loc.getString('enter_description', defaultValue: 'Enter description'),
                      filled: true,
                      fillColor: widget.isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.hemoaiPrimary, width: 2),
                      ),
                    ),
                    style: TextStyle(color: widget.cs.onSurface),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Challenge Type
                  Text(
                    widget.loc.getString('challenge_type', defaultValue: 'Challenge Type'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ChallengeType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            // Update default target based on type
                            switch (type) {
                              case ChallengeType.steps:
                                _targetController.text = '10000';
                                break;
                              case ChallengeType.water:
                                _targetController.text = '8';
                                break;
                              case ChallengeType.sleep:
                                _targetController.text = '480';
                                break;
                              case ChallengeType.diet:
                                _targetController.text = '3';
                                break;
                              case ChallengeType.combined:
                                _targetController.text = '100';
                                break;
                              case ChallengeType.hemogram:
                                _targetController.text = '1';
                                break;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.hemoaiPrimary.withValues(alpha: 0.15)
                                : widget.isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? widget.hemoaiPrimary : widget.cs.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTypeIcon(type),
                                color: isSelected ? widget.hemoaiPrimary : widget.cs.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getTypeLabel(type),
                                style: TextStyle(
                                  color: isSelected ? widget.hemoaiPrimary : widget.cs.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Duration
                  Text(
                    widget.loc.getString('duration', defaultValue: 'Duration'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ChallengeDuration.values.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDuration = duration),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.hemoaiPrimary.withValues(alpha: 0.15)
                                  : widget.isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? widget.hemoaiPrimary : widget.cs.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              _getDurationLabel(duration),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? widget.hemoaiPrimary : widget.cs.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Target Value
                  Text(
                    widget.loc.getString('target_value', defaultValue: 'Target Value'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _getTargetHint(),
                      filled: true,
                      fillColor: widget.isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.hemoaiPrimary, width: 2),
                      ),
                    ),
                    style: TextStyle(color: widget.cs.onSurface),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Participants
                  Text(
                    widget.loc.getString('participants', defaultValue: 'Participants'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  
                  // Self (always included)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.hemoaiPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.hemoaiPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: widget.hemoaiPrimary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.loc.getString('you', defaultValue: 'You'),
                            style: TextStyle(color: widget.cs.onSurface, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.check_circle, color: widget.hemoaiPrimary, size: 20),
                      ],
                    ),
                  ),
                  
                  if (widget.activeFriends.isEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: widget.cs.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.loc.getString('no_friends_add_friends', defaultValue: 'No friends added. Add friends to create group challenges!'),
                              style: TextStyle(color: widget.cs.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    ...widget.activeFriends.map((friend) {
                      final isSelected = _selectedParticipants.contains(friend.friendUserId);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedParticipants.remove(friend.friendUserId);
                            } else {
                              _selectedParticipants.add(friend.friendUserId);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.hemoaiPrimary.withValues(alpha: 0.1)
                                : widget.isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? widget.hemoaiPrimary : widget.cs.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              LabubuAvatar(
                                seed: friend.friendName,
                                size: 32,
                                variantIndex: friend.friendAvatar != null 
                                    ? int.tryParse(friend.friendAvatar!) 
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  friend.friendName,
                                  style: TextStyle(
                                    color: widget.cs.onSurface,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? widget.hemoaiPrimary : widget.cs.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Create Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
              border: Border(top: BorderSide(color: widget.cs.outlineVariant)),
            ),
            child: SafeArea(
              child: FilledButton(
                onPressed: _validateAndCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.hemoaiPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      widget.loc.getString('create_challenge', defaultValue: 'Create Challenge'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndCreate() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.loc.getString('enter_challenge_name', defaultValue: 'Please enter challenge name'))),
      );
      return;
    }

    final targetValue = int.tryParse(_targetController.text.trim());
    if (targetValue == null || targetValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.loc.getString('enter_valid_target', defaultValue: 'Please enter a valid target value'))),
      );
      return;
    }

    if (_selectedParticipants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.loc.getString('select_at_least_one_friend', defaultValue: 'Please select at least one friend'))),
      );
      return;
    }

    final now = DateTime.now();
    DateTime endDate;
    switch (_selectedDuration) {
      case ChallengeDuration.daily:
        endDate = now.add(const Duration(days: 1));
        break;
      case ChallengeDuration.weekly:
        endDate = now.add(const Duration(days: 7));
        break;
      case ChallengeDuration.monthly:
        endDate = now.add(const Duration(days: 30));
        break;
    }

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
      'duration': _selectedDuration,
      'targetValue': targetValue,
      'startDate': now,
      'endDate': endDate,
      'participants': _selectedParticipants.toList(),
    });
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
