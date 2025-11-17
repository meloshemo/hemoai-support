
/// Calculates points based on daily activities (steps, water, sleep)
class PointsCalculator {
  /// Calculate points for steps
  /// - 10,000+ steps: 10 points
  /// - 7,500-9,999: 7 points
  /// - 5,000-7,499: 5 points
  /// - 2,500-4,999: 2 points
  /// - <2,500: 0 points
  static int calculateStepsPoints(int steps, int goal) {
    if (steps >= goal) return 10; // 100%+ of goal
    if (steps >= (goal * 0.75).round()) return 7; // 75-99%
    if (steps >= (goal * 0.50).round()) return 5; // 50-74%
    if (steps >= (goal * 0.25).round()) return 2; // 25-49%
    return 0; // <25%
  }

  /// Calculate points for water intake
  /// - 8+ glasses: 10 points
  /// - 6-7 glasses: 7 points
  /// - 4-5 glasses: 5 points
  /// - 2-3 glasses: 2 points
  /// - <2 glasses: 0 points
  static int calculateWaterPoints(int glasses, int goal) {
    if (glasses >= goal) return 10; // 100%+ of goal
    if (glasses >= (goal * 0.75).round()) return 7; // 75-99%
    if (glasses >= (goal * 0.50).round()) return 5; // 50-74%
    if (glasses >= (goal * 0.25).round()) return 2; // 25-49%
    return 0; // <25%
  }

  /// Calculate points for sleep
  /// - 7-9 hours (420-540 min): 10 points
  /// - 6-7 hours (360-419 min): 7 points
  /// - 5-6 hours (300-359 min): 5 points
  /// - 4-5 hours (240-299 min): 2 points
  /// - <4 hours: 0 points
  static int calculateSleepPoints(int sleepMinutes, int goal) {
    // Goal is typically 480 minutes (8 hours)
    if (sleepMinutes >= 420 && sleepMinutes <= 540) return 10; // 7-9 hours (optimal)
    if (sleepMinutes >= 360 && sleepMinutes < 420) return 7; // 6-7 hours
    if (sleepMinutes >= 300 && sleepMinutes < 360) return 5; // 5-6 hours
    if (sleepMinutes >= 240 && sleepMinutes < 300) return 2; // 4-5 hours
    return 0; // <4 hours
  }

  /// Calculate total daily points
  /// Returns: {points, goalsAchieved (0-3), breakdown}
  static Map<String, dynamic> calculateDailyPoints({
    required int steps,
    required int waterGlasses,
    required int sleepMinutes,
    required int stepsGoal,
    required int waterGoal,
    required int sleepGoal,
  }) {
    final stepsPoints = calculateStepsPoints(steps, stepsGoal);
    final waterPoints = calculateWaterPoints(waterGlasses, waterGoal);
    final sleepPoints = calculateSleepPoints(sleepMinutes, sleepGoal);

    int goalsAchieved = 0;
    if (stepsPoints >= 10) goalsAchieved++;
    if (waterPoints >= 10) goalsAchieved++;
    if (sleepPoints >= 10) goalsAchieved++;

    // Bonus: +5 points if all goals achieved
    final bonus = goalsAchieved == 3 ? 5 : 0;

    final totalPoints = stepsPoints + waterPoints + sleepPoints + bonus;

    return {
      'total_points': totalPoints,
      'steps_points': stepsPoints,
      'water_points': waterPoints,
      'sleep_points': sleepPoints,
      'bonus_points': bonus,
      'goals_achieved': goalsAchieved,
      'breakdown': {
        'steps': {'value': steps, 'goal': stepsGoal, 'points': stepsPoints},
        'water': {'value': waterGlasses, 'goal': waterGoal, 'points': waterPoints},
        'sleep': {'value': sleepMinutes, 'goal': sleepGoal, 'points': sleepPoints},
      },
    };
  }

  /// Calculate weekly streak bonus
  /// - 7 consecutive days with all goals: +20 bonus
  static int calculateWeeklyStreakBonus(int consecutiveDays) {
    if (consecutiveDays >= 7) return 20;
    return 0;
  }

  /// Calculate monthly streak bonus
  /// - 30 consecutive days with all goals: +50 bonus
  static int calculateMonthlyStreakBonus(int consecutiveDays) {
    if (consecutiveDays >= 30) return 50;
    return 0;
  }
}

