import 'dart:convert';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/splash/screens/splash_screen.dart';

class RouteHelper {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String home = '/home';

  static String getSplashRoute({Map<String, dynamic>? notificationData}) {
    notificationData?.remove('body');
    String userName =
        (notificationData?['user_name'] ?? '').replaceAll('&', 'a');
    notificationData?.remove('user_name');

    return '$splash?notification=${jsonEncode(notificationData)}&userName=$userName';
  }

  static List<GetPage> routes = [
    GetPage(
      name: initial,
      page: () {
        final auth = Get.find<AuthController>();
        final hasSession = auth.isLoggedIn() || auth.getUserToken().isNotEmpty;
        return hasSession ? const DashboardScreen() : const SignInScreen();
      },
    ),
    GetPage(
        name: splash,
        page: () => SplashScreen(
            notificationData: Get.parameters['notification'] == null
                ? null
                : jsonDecode(Get.parameters['notification']!),
            userName: Get.parameters['userName']?.replaceAll('a', '&'))),
    GetPage(name: home, page: () => const DashboardScreen()),
  ];
}
