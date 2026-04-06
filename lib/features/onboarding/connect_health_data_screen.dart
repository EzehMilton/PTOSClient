import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';

class ConnectHealthDataScreen extends StatelessWidget {
  const ConnectHealthDataScreen({super.key});

  static const _providers = <_HealthProvider>[
    _HealthProvider(
      name: 'Apple Health',
      description: 'Share activity, steps, workouts, and body metrics.',
      icon: Icons.favorite_outline,
    ),
    _HealthProvider(
      name: 'Garmin',
      description: 'Bring in training load, runs, rides, and recovery data.',
      icon: Icons.watch_outlined,
    ),
    _HealthProvider(
      name: 'Whoop',
      description: 'Surface recovery, sleep, and strain trends for your PT.',
      icon: Icons.bolt_outlined,
    ),
    _HealthProvider(
      name: 'Fitbit',
      description: 'Sync movement, heart rate, sleep, and wellness signals.',
      icon: Icons.multiline_chart,
    ),
  ];

  void _showMockedMessage(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider connection is mocked for now'),
      ),
    );
  }

  void _finish(BuildContext context) {
    context.go(Routes.setupComplete);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7B5CF6);
    const panel = Color(0xFF171826);
    const field = Color(0xFF1E2031);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF11131C),
              Color(0xFF0C0D14),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2A000000),
                        blurRadius: 32,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go(Routes.progressPhotos),
                            style: IconButton.styleFrom(
                              backgroundColor: field,
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                          const Spacer(),
                          const _ProgressStepIndicator(
                            currentStep: 7,
                            totalSteps: 7,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Connect health data',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This step is currently mocked. It is structured so real provider integrations can replace the placeholder actions later.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ..._providers.map(
                        (provider) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _HealthProviderCard(
                            provider: provider,
                            onConnect: () =>
                                _showMockedMessage(context, provider.name),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: field,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'You can finish setup now and connect providers later without blocking access to the app.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () => _finish(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Finish setup',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => _finish(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Skip — I'll do this later",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthProvider {
  const _HealthProvider({
    required this.name,
    required this.description,
    required this.icon,
  });

  final String name;
  final String description;
  final IconData icon;
}

class _HealthProviderCard extends StatelessWidget {
  const _HealthProviderCard({
    required this.provider,
    required this.onConnect,
  });

  final _HealthProvider provider;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2031),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7B5CF6).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(provider.icon, color: const Color(0xFF7B5CF6)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  provider.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: onConnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Connect'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStepIndicator extends StatelessWidget {
  const _ProgressStepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Step $currentStep',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.64),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isComplete = stepNumber < currentStep;
            final isCurrent = stepNumber == currentStep;
            final color = isCurrent
                ? const Color(0xFF7B5CF6)
                : isComplete
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.16);

            return Container(
              width: isCurrent ? 30 : 18,
              height: 6,
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}
