bool isValidSnoozeMinutes(int minutes) {
  // Accept between 1 minute and 24 hours inclusive
  return minutes >= 1 && minutes <= 1440;
}
