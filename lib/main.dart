import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/constants.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/checkin/checkin_confirmation_screen.dart';
import 'features/checkin/checkin_detail_screen.dart';
import 'features/checkin/checkin_form_screen.dart';
import 'features/checkin/checkin_history_screen.dart';
import 'features/checkin/checkin_provider.dart';
import 'features/home/home_provider.dart';
import 'features/home/home_screen.dart';
import 'features/meal_plan/meal_plan_provider.dart';
import 'features/meal_plan/meal_plan_screen.dart';
import 'features/messages/messages_provider.dart';
import 'features/messages/messages_screen.dart';
import 'features/profile/profile_provider.dart';
import 'features/profile/profile_screen.dart';
import 'features/workout/workout_provider.dart';
import 'features/workout/workout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await TokenStorage.instance.readToken();
  final isLoggedIn = token != null;

  runApp(SetlyApp(isLoggedIn: isLoggedIn));
}

class SetlyApp extends StatefulWidget {
  const SetlyApp({super.key, required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  State<SetlyApp> createState() => _SetlyAppState();
}

class _SetlyAppState extends State<SetlyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: widget.isLoggedIn ? Routes.home : Routes.login,
      routes: [
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: Routes.checkin,
          builder: (context, state) => const _Placeholder(label: 'Check-in'),
        ),
        GoRoute(
          path: Routes.checkinNew,
          builder: (context, state) => const CheckInFormScreen(),
        ),
        GoRoute(
          path: Routes.checkinConfirmation,
          builder: (context, state) =>
              const CheckInConfirmationScreen(),
        ),
        GoRoute(
          path: Routes.checkinHistory,
          builder: (context, state) => const CheckInHistoryScreen(),
        ),
        GoRoute(
          path: Routes.checkinDetailPath,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CheckInDetailScreen(id: id);
          },
        ),
        GoRoute(
          path: Routes.workout,
          builder: (context, state) => const WorkoutScreen(),
        ),
        GoRoute(
          path: Routes.mealPlan,
          builder: (context, state) => const MealPlanScreen(),
        ),
        GoRoute(
          path: Routes.messages,
          builder: (context, state) => const MessagesScreen(),
        ),
      ],
    );

    ApiClient.instance.setNavigatorKey(_router.routerDelegate.navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: ApiClient.instance),
        Provider.value(value: TokenStorage.instance),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp.router(
        title: 'Setly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF171826),
            primary: Color(0xFF7B5CF6),
            onPrimary: Color(0xFFFFFFFF),
            secondary: Color(0xFF34D399),
          ),
          scaffoldBackgroundColor: const Color(0xFF0C0D14),
        ),
        routerConfig: _router,
      ),
    );
  }
}

/// Temporary placeholder screen used until real feature screens are built.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
