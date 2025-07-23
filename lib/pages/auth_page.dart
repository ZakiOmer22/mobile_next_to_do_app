import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  final void Function() onSignedIn;
  const AuthPage({required this.onSignedIn, super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    setState(() {
      _loading = false;
      _error = response.error?.message;
    });
    if (response.error == null) {
      widget.onSignedIn();
    }
  }

  Future<void> signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await Supabase.instance.client.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    setState(() {
      _loading = false;
      _error = response.error?.message;
    });
    if (response.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please verify your email before signing in.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In / Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_loading,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : signIn,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : signUp,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign Up'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
