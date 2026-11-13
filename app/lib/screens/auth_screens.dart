import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/server_config_sheet.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Solis.ink,
        body: Center(child: Text('SOLIS', style: Solis.serif(34, color: Solis.paper).copyWith(letterSpacing: 10))),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Solis.ink,
      body: Stack(fit: StackFit.expand, children: [
        // Decorative palette shapes (arch + sun) from the brand boards
        Positioned(
          right: -60,
          top: 80,
          child: Container(
            width: 260,
            height: 420,
            decoration: const BoxDecoration(color: Solis.teal, borderRadius: BorderRadius.vertical(top: Radius.circular(140))),
          ),
        ),
        Positioned(left: -70, top: 260, child: Container(width: 220, height: 220, decoration: const BoxDecoration(color: Solis.sun, shape: BoxShape.circle))),
        Positioned(left: 120, top: 150, child: Container(width: 90, height: 90, decoration: const BoxDecoration(color: Solis.rust, shape: BoxShape.circle))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SOLIS', style: Solis.serif(22, color: Solis.paper).copyWith(letterSpacing: 8)),
                  GestureDetector(
                    onTap: () => showServerConfigSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Solis.paper.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Solis.paper.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dns_rounded, size: 13, color: Solis.sun),
                          const SizedBox(width: 5),
                          Text('Server', style: Solis.sans(12, color: Solis.paper, weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text('Art, told by hand.', style: Solis.serif(44, color: Solis.paper, height: 1.05)),
              const SizedBox(height: 14),
              Text('Explore the collection, bid on live lots and book events at the museum.',
                  style: Solis.sans(15, color: Solis.paper.withValues(alpha: 0.7))),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Create account',
                color: Solis.sun,
                textColor: Solis.ink,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(register: true))),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: Solis.paper.withValues(alpha: 0.4)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(register: false))),
                  child: Text('I already have an account', style: Solis.sans(15, color: Solis.paper, weight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.register});
  final bool register;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  late bool _register = widget.register;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    try {
      if (_register) {
        await auth.register(_name.text, _email.text, _pass.text);
      } else {
        await auth.login(_email.text, _pass.text);
      }
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Solis.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_outlined, color: Solis.inkSoft),
            tooltip: 'Server Connection',
            onPressed: () => showServerConfigSheet(context, onSaved: () => setState(() {})),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(_register ? 'Join Solis' : 'Welcome back', style: Solis.serif(38)),
              const SizedBox(height: 8),
              Text(_register ? 'Create an account to bid, save works and book events.' : 'Sign in to continue to your collection.',
                  style: Solis.sans(15, color: Solis.muted)),
              const SizedBox(height: 32),
              if (_register) ...[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: _register ? 'At least 8 characters, with a letter and a number' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Solis.muted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Password is required';
                  if (_register) {
                    if (s.length < 8) return 'Use at least 8 characters';
                    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) return 'Include a letter and a number';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Solis.rust.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.error_outline, color: Solis.rust, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: Solis.sans(13.5, color: Solis.rust))),
                      ]),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => showServerConfigSheet(context, onSaved: () => setState(() => _error = null)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.settings_ethernet, size: 15, color: Solis.teal),
                            const SizedBox(width: 6),
                            Text('Change Server Address / Test Ping',
                                style: Solis.sans(13, color: Solis.teal, weight: FontWeight.w600).copyWith(decoration: TextDecoration.underline)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(label: _register ? 'Create account' : 'Sign in', loading: _loading, onPressed: _submit),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _register = !_register;
                            _error = null;
                          }),
                  child: Text(
                    _register ? 'Already have an account? Sign in' : 'New to Solis? Create an account',
                    style: Solis.sans(14, weight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
