import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    final pw = _password.text;
    if (email.isEmpty || pw.isEmpty) {
      setState(() => _localError = 'Enter an email and password');
      return;
    }
    setState(() => _localError = null);
    ref.read(authControllerProvider.notifier).signIn(email, pw);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final busy = state.isLoading;
    final errorText = _localError ??
        (state.hasError ? state.error.toString() : null);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Dublin PropTech',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: 4),
                  const Text('Floor Survey',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.muted)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    height: 3, width: 44,
                    decoration: BoxDecoration(color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  _label('Email'),
                  TextField(
                    controller: _email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        hintText: 'you@dublinproptech.com'),
                  ),
                  const SizedBox(height: 14),
                  _label('Password'),
                  TextField(
                    controller: _password,
                    enabled: !busy,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(hintText: '••••••••'),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 14),
                    Text(errorText,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w700,
            color: AppColors.label)),
  );
}