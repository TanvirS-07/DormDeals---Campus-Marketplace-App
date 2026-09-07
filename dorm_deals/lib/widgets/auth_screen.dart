import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  void _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    if (!_isLogin && password != repeatPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Authentication error')),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Login' : 'Sign Up';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/dorm_deals_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/dorm_deals_logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      key: const ValueKey('email-field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        label: Text('Email ID'),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('password-field'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        label: Text('Password'),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    if (!_isLogin) const SizedBox(height: 12),
                    if (!_isLogin)
                      TextField(
                        key: const ValueKey('repeat-password-field'),
                        controller: _repeatPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          label: Text('Repeat Password'),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitAuthForm,
                          child: Text(title),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _toggleAuthMode,
                      child: Text(
                        _isLogin
                            ? 'Create new account'
                            : 'I already have an account',
                      ),
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
