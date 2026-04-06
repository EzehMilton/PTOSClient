import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import '../../core/models/public_invite.dart';

enum _InviteLookupState {
  idle,
  loading,
  success,
  error,
}

class InviteLandingScreen extends StatefulWidget {
  const InviteLandingScreen({
    super.key,
    this.initialToken,
  });

  final String? initialToken;

  @override
  State<InviteLandingScreen> createState() => _InviteLandingScreenState();
}

class _InviteLandingScreenState extends State<InviteLandingScreen> {
  final _tokenController = TextEditingController();

  _InviteLookupState _state = _InviteLookupState.idle;
  String? _tokenError;
  String? _errorMessage;
  PublicInvite? _invite;

  @override
  void initState() {
    super.initState();
    final initialToken = widget.initialToken?.trim() ?? '';
    if (initialToken.isNotEmpty) {
      _tokenController.text = initialToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _lookupInvite();
        }
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _lookupInvite() async {
    final token = _tokenController.text.trim();
    FocusScope.of(context).unfocus();

    if (token.isEmpty) {
      setState(() {
        _tokenError = 'Enter your invitation token to continue';
        _state = _InviteLookupState.idle;
        _errorMessage = null;
        _invite = null;
      });
      return;
    }

    setState(() {
      _tokenError = null;
      _errorMessage = null;
      _invite = null;
      _state = _InviteLookupState.loading;
    });

    try {
      final invite = await ApiClient.instance.getPublicInvite(token);
      if (!mounted) return;

      setState(() {
        _invite = invite;
        _state = _InviteLookupState.success;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _InviteLookupState.error;
        _errorMessage = _extractMessage(e);
      });
    }
  }

  void _goToCreateAccount() {
    final token = _invite?.token ?? _tokenController.text.trim();
    context.go('${Routes.createAccount}?token=${Uri.encodeComponent(token)}');
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    if (e.response?.statusCode == 404) {
      return 'This invitation link is invalid or has expired.';
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return 'We could not reach the invite service. Try again shortly.';
    }

    return 'We could not verify that invitation. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7B5CF6);
    const panel = Color(0xFF171826);
    const card = Color(0xFF1E2031);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF10111A),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'SETLY',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 30,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Client invitation',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Your PT has invited you',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enter your invitation token to see who set up your coaching programme and continue onboarding.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _tokenController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _lookupInvite(),
                            decoration: InputDecoration(
                              labelText: 'Invitation token',
                              hintText: 'Paste or type your token',
                              errorText: _tokenError,
                              filled: true,
                              fillColor: card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: Colors.white12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: _state == _InviteLookupState.loading
                                  ? null
                                  : _lookupInvite,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                disabledBackgroundColor:
                                    accent.withValues(alpha: 0.55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _state == _InviteLookupState.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Check invite',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => context.go(Routes.login),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'I already have an account',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InviteStatePanel(
                      state: _state,
                      invite: _invite,
                      errorMessage: _errorMessage,
                      onGetStarted: _goToCreateAccount,
                      onLogin: () => context.go(Routes.login),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteStatePanel extends StatelessWidget {
  const _InviteStatePanel({
    required this.state,
    required this.invite,
    required this.errorMessage,
    required this.onGetStarted,
    required this.onLogin,
  });

  final _InviteLookupState state;
  final PublicInvite? invite;
  final String? errorMessage;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _InviteLookupState.idle:
        return _StateCard(
          icon: Icons.mail_outline,
          title: 'Ready when you are',
          message:
              'Use the invitation token from your PT to preview your onboarding details.',
          iconColor: const Color(0xFF7B5CF6),
        );
      case _InviteLookupState.loading:
        return const _LoadingCard();
      case _InviteLookupState.error:
        return _StateCard(
          icon: Icons.error_outline,
          title: 'Invite not found',
          message:
              errorMessage ??
              'We could not verify that invitation. Please try again.',
          iconColor: const Color(0xFFFF7A7A),
        );
      case _InviteLookupState.success:
        final resolvedInvite = invite!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF171826),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Invitation confirmed',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DetailRow(label: 'PT name', value: resolvedInvite.ptName),
              if (resolvedInvite.clientEmail != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Invited email',
                  value: resolvedInvite.clientEmail!,
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Your PT has set up a coaching programme for you.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onGetStarted,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get started',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'I already have an account',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF171826),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(height: 16),
          Text(
            'Checking your invitation...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF171826),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2031),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
