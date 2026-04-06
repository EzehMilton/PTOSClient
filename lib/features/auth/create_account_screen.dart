import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import '../../core/models/public_invite.dart';
import 'auth_provider.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    this.inviteToken,
  });

  final String? inviteToken;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loadingInvite = false;
  String? _inviteError;
  PublicInvite? _invite;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadInvite() async {
    final inviteToken = widget.inviteToken?.trim() ?? '';
    if (inviteToken.isEmpty) {
      setState(() {
        _inviteError = 'Missing invitation token. Start again from your invite.';
      });
      return;
    }

    setState(() {
      _loadingInvite = true;
      _inviteError = null;
    });

    try {
      final invite = await ApiClient.instance.getPublicInvite(inviteToken);
      if (!mounted) return;

      setState(() {
        _invite = invite;
        _loadingInvite = false;
      });

      if (_fullNameController.text.trim().isEmpty &&
          invite.clientFullName != null) {
        _fullNameController.text = invite.clientFullName!;
      }
      if (_emailController.text.trim().isEmpty && invite.clientEmail != null) {
        _emailController.text = invite.clientEmail!;
      }
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingInvite = false;
        _inviteError = _extractInviteError(e);
      });
    }
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final inviteToken = widget.inviteToken?.trim() ?? '';

    if (inviteToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing invitation token')),
      );
      return;
    }

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      inviteToken: inviteToken,
      fullName: fullName,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      context.go(Routes.basicInfo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not create account')),
      );
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  String _extractInviteError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.response?.statusCode == 404) {
      return 'This invitation link is invalid or has expired.';
    }
    return 'We could not load your invitation details.';
  }

  void _showSocialMock(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-up is not available yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4DD97A);
    const panel = Color(0xFF171816);
    const field = Color(0xFF2C2D29);
    const border = Color(0xFF4A4B47);

    return Scaffold(
      body: Container(
        color: const Color(0xFF121311),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          '2. CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_loadingInvite)
                        Text(
                          'Loading your invite details...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        )
                      else
                        Text(
                          _invite == null
                              ? 'Set your details to continue.'
                              : "You'll be connected to ${_invite!.ptName} automatically.",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      if (_inviteError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _inviteError!,
                          style: const TextStyle(
                            color: Color(0xFFFF7A7A),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.go(Routes.inviteLanding),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          child: const Text('Back to invite'),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _AccountField(
                        controller: _fullNameController,
                        hintText: 'Full name',
                        fillColor: field,
                        borderColor: border,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),
                      _AccountField(
                        controller: _emailController,
                        hintText: 'Email',
                        fillColor: field,
                        borderColor: border,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _AccountField(
                        controller: _passwordController,
                        hintText: 'Password',
                        fillColor: field,
                        borderColor: border,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: auth.loading || _inviteError != null
                                  ? null
                                  : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                disabledBackgroundColor:
                                    accent.withValues(alpha: 0.45),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: auth.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Create account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.42),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SocialMockButton(
                        label: 'Continue with Apple',
                        onPressed: () => _showSocialMock('Apple'),
                      ),
                      const SizedBox(height: 12),
                      _SocialMockButton(
                        label: 'Continue with Google',
                        onPressed: () => _showSocialMock('Google'),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(Routes.login),
                          child: const Text('I already have an account'),
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

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.controller,
    required this.hintText,
    required this.fillColor,
    required this.borderColor,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final Color fillColor;
  final Color borderColor;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: fillColor,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}

class _SocialMockButton extends StatelessWidget {
  const _SocialMockButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.78),
          side: const BorderSide(color: Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
