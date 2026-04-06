import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../home/home_provider.dart';
import '../profile/profile_provider.dart';

class SetupCompleteScreen extends StatefulWidget {
  const SetupCompleteScreen({super.key});

  @override
  State<SetupCompleteScreen> createState() => _SetupCompleteScreenState();
}

class _SetupCompleteScreenState extends State<SetupCompleteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProfileProvider>();
      if (provider.profile.isEmpty && !provider.loading) {
        provider.loadProfile();
      }
    });
  }

  Future<void> _finishSetup() async {
    final profileProvider = context.read<ProfileProvider>();
    final homeProvider = context.read<HomeProvider>();
    final saved = await profileProvider.completeOnboarding();

    if (!mounted) return;

    if (saved) {
      await homeProvider.loadProfile();
      if (!mounted) return;
      context.go(Routes.home);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          profileProvider.error ?? 'Could not mark onboarding as complete',
        ),
      ),
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Consumer<ProfileProvider>(
                  builder: (context, profile, _) {
                    final ptName = profile.ptName;
                    final title = ptName == null
                        ? 'You are all set'
                        : 'You are all set with $ptName';
                    final message = ptName == null
                        ? 'Your PTOS setup is complete. Your coach will review your details and start shaping your plan.'
                        : '$ptName now has your onboarding details and can start shaping your coaching plan.';

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: accent,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: field,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'While you wait',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check your messages, keep your phone nearby for plan updates, and connect any optional integrations later from the app.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.74),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (profile.error != null) ...[
                            const SizedBox(height: 18),
                            Text(
                              profile.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFF7A7A),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: profile.saving ? null : _finishSetup,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                disabledBackgroundColor:
                                    accent.withValues(alpha: 0.55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: profile.saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Go to home',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
