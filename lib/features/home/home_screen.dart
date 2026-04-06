import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/storage/token_storage.dart';
import 'home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeProvider>().loadProfile();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _logout() async {
    await TokenStorage.instance.clearAll();
    if (!mounted) return;
    context.go(Routes.login);
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        context.go(Routes.home);
      case 1:
        context.go(Routes.checkin);
      case 2:
        context.go(Routes.workout);
      case 3:
        context.go(Routes.messages);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B5CF6);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'SETLY',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: purple,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.go(Routes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, home, _) {
          if (home.loading) {
            return const _LoadingSkeleton();
          }

          if (home.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(home.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: home.loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Greeting ---
                Text(
                  '${_greeting()}, ${home.firstName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // --- Summary card ---
                _SummaryCard(
                  currentWeight: home.currentWeight,
                  targetWeight: home.targetWeight,
                  goal: home.goalFormatted,
                ),
                const SizedBox(height: 24),

                // --- Action cards ---
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _ActionCard(
                      icon: Icons.assignment_turned_in,
                      label: 'Submit Check-in',
                      onTap: () => context.go(Routes.checkinNew),
                    ),
                    _ActionCard(
                      icon: Icons.fitness_center,
                      label: 'My Workout',
                      onTap: () => context.go(Routes.workout),
                    ),
                    _ActionCard(
                      icon: Icons.chat_bubble_outline,
                      label: 'Messages',
                      onTap: () => context.go(Routes.messages),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Check-in history link ---
                Center(
                  child: TextButton(
                    onPressed: () => context.go(Routes.checkinHistory),
                    child: const Text(
                      'View check-in history',
                      style: TextStyle(
                        color: purple,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: purple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF171826),
        selectedItemColor: purple,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fact_check), label: 'Check-in'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.currentWeight,
    required this.targetWeight,
    required this.goal,
  });

  final double currentWeight;
  final double targetWeight;
  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Current',
            value: '${currentWeight.toStringAsFixed(1)} kg',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
          ),
          _SummaryItem(
            label: 'Target',
            value: '${targetWeight.toStringAsFixed(1)} kg',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
          ),
          _SummaryItem(label: 'Goal', value: goal),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action card
// ---------------------------------------------------------------------------

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B5CF6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: purple, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting placeholder
          _ShimmerBox(width: 220, height: 28),
          const SizedBox(height: 24),

          // Summary card placeholder
          _ShimmerBox(width: double.infinity, height: 90),
          const SizedBox(height: 24),

          // Action cards placeholder
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: List.generate(
              3,
              (_) => _ShimmerBox(width: double.infinity, height: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF1E1F2E),
            Color(0xFF2A2B3D),
            Color(0xFF1E1F2E),
          ],
          stops: [
            (_controller.value - 0.3).clamp(0.0, 1.0),
            _controller.value,
            (_controller.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}
