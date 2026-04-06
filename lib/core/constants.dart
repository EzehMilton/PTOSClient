import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

String get kBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:8082';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8082';
  }

  return 'http://localhost:8082';
}

class Routes {
  Routes._();

  static const String inviteLanding = '/invite';
  static const String createAccount = '/create-account';
  static const String basicInfo = '/onboarding/basic-info';
  static const String goals = '/onboarding/goals';
  static const String experienceAndHealth =
      '/onboarding/experience-and-health';
  static const String progressPhotos = '/onboarding/progress-photos';
  static const String connectHealthData = '/onboarding/connect-health-data';
  static const String setupComplete = '/onboarding/setup-complete';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String checkin = '/checkin';
  static const String checkinNew = '/checkin/new';
  static const String checkinHistory = '/checkin/history';
  static const String checkinConfirmation = '/checkin/confirmation';
  static const String checkinDetailPath = '/checkin/:id';
  static String checkinDetail(String id) => '/checkin/$id';
  static const String workout = '/workout';
  static const String mealPlan = '/meal-plan';
  static const String messages = '/messages';
}
